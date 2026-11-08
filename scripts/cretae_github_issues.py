#!/usr/bin/env python3
"""Create GitHub issues (features and their tasks as sub-issues) from the plan YAML.

The issue templates are NOT hardcoded: they are read from the repository's
issue-form files (default: .github/ISSUE_TEMPLATE/*.yml) and rendered the same way
GitHub renders a submitted form (title, labels, "### Label" sections, checkboxes).
`gh issue create` cannot fill YAML issue forms, so the script builds the body itself
and creates the issue through `gh api`.

Template detection:
  * The feature template is the form whose `labels` contain "feature".
  * The task template is the form whose `labels` contain "task".
  * Override with --feature-template / --task-template.

Plan -> form field mapping:
  The only coupling with the templates is the field `id` values listed in
  FEATURE_FIELDS / TASK_FIELDS below. Everything else (title prefix, labels,
  section labels, checkbox texts, dropdown options, extra keys such as `assignees`
  or `type`) comes from the template files. Fields without a provider are rendered
  as "_No response_", like GitHub does for empty fields.

Idempotency:
  Issues are matched by their title (`<template title prefix><ID>:`), so re-running
  the script skips issues that already exist and only creates/links what is missing.

Usage:
    python3 create_github_issues.py --dry-run -v            # preview, no gh calls
    python3 create_github_issues.py                         # create everything
    python3 create_github_issues.py --only FEAT-001 FEAT-002
    python3 create_github_issues.py --repo OWNER/REPO

Requires: gh (authenticated, with sub-issues support) and PyYAML.
"""

import argparse
import glob
import itertools
import json
import os
import re
import shutil
import subprocess
import sys
import time

import yaml

PLACEHOLDER = re.compile(r"<[^>]*>")
NO_RESPONSE = "_No response_"


# --------------------------------------------------------------------------- #
# Plan -> template field providers (keyed by the form field `id`)
# --------------------------------------------------------------------------- #
def render_elements(elements):
    return ", ".join("`%s`" % e if str(e).endswith(".mmd") else str(e) for e in elements)


def bullets(items):
    return "\n".join("- %s: %s" % (i["id"], i["description"]) for i in items)


def ref(ctx, ident):
    number = ctx["refs"].get(ident)
    return "%s (#%d)" % (ident, number) if number else ident


def feature_description(ctx):
    f = ctx["feature"]
    parts = [f["detailed_description"], "**Summary:** %s" % f["short_description"],
             "**Related elements:** %s" % render_elements(f["related_elements"])]
    deps = f.get("depends_on") or []
    if deps:
        line = "**Depends on:** %s" % ", ".join(ref(ctx, d) for d in deps)
        if f.get("dependency_rationale"):
            line += " (%s)" % f["dependency_rationale"]
        parts.append(line)
    return "\n\n".join(parts)


def task_description(ctx):
    t = ctx["task"]
    return "\n\n".join([
        t["description"],
        "**TDD step:** %s" % t["tdd_step"],
        "**Related elements:** %s" % render_elements(t["related_elements"]),
        "**Parent feature:** %s" % ref(ctx, ctx["feature"]["id"]),
    ])


def task_acceptance_criteria(ctx):
    """Tasks carry no ACs in the plan (they hang from the feature).

    Use the task's own `acceptance_criteria` if the YAML ever provides them;
    otherwise the completion criterion is the TDD step definition from the plan.
    """
    t = ctx["task"]
    if t.get("acceptance_criteria"):
        return bullets(t["acceptance_criteria"])
    step = t["tdd_step"]
    lines = ["- %s: %s" % (step, ctx["tdd"].get(step, ""))]
    lines.append("- Feature-level acceptance criteria are tracked in %s." % ref(ctx, ctx["feature"]["id"]))
    return "\n".join(lines)


FEATURE_FIELDS = {
    "feat-id": lambda c: c["feature"]["id"],
    "description": feature_description,
    "acceptance-criteria": lambda c: bullets(c["feature"].get("acceptance_criteria") or []),
    "tasks": lambda c: bullets(c["feature"].get("tasks") or []),
}

TASK_FIELDS = {
    "task-id": lambda c: c["task"]["id"],
    "parent-feature": lambda c: c["feature"]["id"],
    "description": task_description,
    "acceptance-criteria": task_acceptance_criteria,
}


# --------------------------------------------------------------------------- #
# Issue-form handling
# --------------------------------------------------------------------------- #
def load_form(path):
    with open(path, encoding="utf-8") as fh:
        form = yaml.safe_load(fh)
    if not isinstance(form, dict) or "body" not in form:
        raise ValueError("%s is not an issue form (no `body`)" % path)
    return form


def discover_templates(directory):
    found = {}
    for path in sorted(glob.glob(os.path.join(directory, "*.y*ml"))):
        try:
            form = load_form(path)
        except (ValueError, yaml.YAMLError):
            continue  # config.yml or invalid form
        labels = {str(l).lower() for l in (form.get("labels") or [])}
        for kind in ("feature", "task"):
            if kind in labels and kind not in found:
                found[kind] = (path, form)
    return found


def check_form(kind, path, form, providers):
    """Warn about mismatches between template fields and available providers."""
    ids = set()
    for field in form.get("body", []):
        if field.get("type") == "markdown":
            continue
        fid = field.get("id")
        ids.add(fid)
        required = bool((field.get("validations") or {}).get("required"))
        if field.get("type") != "checkboxes" and fid not in providers and required:
            sys.stderr.write("warning: %s template (%s): required field '%s' has no value source; "
                             "it will be '%s'\n" % (kind, path, fid, NO_RESPONSE))
    for fid in providers:
        if fid not in ids:
            sys.stderr.write("warning: %s template (%s) has no field '%s'; its value is ignored\n"
                             % (kind, path, fid))


def render_title(form, ident, text):
    template = form.get("title") or ""
    title_text = "%s: %s" % (ident, text)
    if PLACEHOLDER.search(template):
        return PLACEHOLDER.sub(lambda _m: title_text, template, count=1)
    return (template + " " + title_text).strip()


def title_pattern(form):
    head = (form.get("title") or "").split("<", 1)[0]
    return re.compile("^" + re.escape(head) + r"([A-Za-z]+-\d+):")


def render_body(form, values, check_boxes=True):
    """Render a form the way GitHub does when it is submitted."""
    sections = []
    for field in form.get("body", []):
        ftype = field.get("type")
        if ftype == "markdown":
            continue
        attrs = field.get("attributes") or {}
        label = attrs.get("label") or field.get("id") or ""
        if ftype == "checkboxes":
            content = "\n".join("- [%s] %s" % ("x" if check_boxes else " ", o.get("label", ""))
                                for o in attrs.get("options") or [])
        else:
            value = values.get(field.get("id"))
            if value in (None, ""):
                content = NO_RESPONSE
            elif ftype == "dropdown":
                options = [str(o) for o in attrs.get("options") or []]
                if options and str(value) not in options:
                    sys.stderr.write("warning: value %r is not an option of dropdown '%s'\n"
                                     % (value, field.get("id")))
                content = str(value)
            elif ftype == "textarea" and attrs.get("render"):
                content = "```%s\n%s\n```" % (attrs["render"], value)
            else:
                content = str(value)
        sections.append("### %s\n\n%s" % (label, content))
    return "\n\n".join(sections)


def build_values(providers, ctx):
    return {fid: fn(ctx) for fid, fn in providers.items()}


# --------------------------------------------------------------------------- #
# gh wrapper
# --------------------------------------------------------------------------- #
class GhError(RuntimeError):
    pass


def gh(*args, input_data=None, retries=3):
    for attempt in range(retries):
        proc = subprocess.run(["gh"] + list(args), input=input_data,
                              capture_output=True, text=True)
        if proc.returncode == 0:
            return proc.stdout
        err = (proc.stderr or "") + (proc.stdout or "")
        if "rate limit" in err.lower() and attempt < retries - 1:
            wait = 60 * (attempt + 1)
            sys.stderr.write("rate limited; sleeping %ds\n" % wait)
            time.sleep(wait)
            continue
        raise GhError("gh %s failed: %s" % (" ".join(args[:3]), err.strip()))
    raise GhError("unreachable")


def resolve_repo(explicit):
    if explicit:
        return explicit
    return gh("repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner").strip()


def fetch_existing_issues(repo):
    jq = ".[] | select(.pull_request | not) | {id, number, title, html_url}"
    out = gh("api", "--paginate", "repos/%s/issues?state=all&per_page=100" % repo, "--jq", jq)
    return [json.loads(line) for line in out.splitlines() if line.strip()]


def ensure_labels(repo, labels):
    out = gh("api", "--paginate", "repos/%s/labels?per_page=100" % repo, "--jq", ".[].name")
    existing = {l.strip().lower() for l in out.splitlines()}
    for label in sorted(set(labels)):
        if label.lower() not in existing:
            gh("api", "-X", "POST", "repos/%s/labels" % repo, "-f", "name=%s" % label)
            print("created label '%s'" % label)


def create_issue(repo, form, title, body):
    payload = {"title": title, "body": body}
    for key in ("labels", "assignees", "type"):
        if form.get(key):
            payload[key] = form[key]
    out = gh("api", "-X", "POST", "repos/%s/issues" % repo, "--input", "-",
             input_data=json.dumps(payload))
    return json.loads(out)


def list_sub_issue_ids(repo, number):
    out = gh("api", "--paginate", "repos/%s/issues/%d/sub_issues?per_page=100" % (repo, number),
             "--jq", ".[].id")
    return {int(x) for x in out.split()}


def link_sub_issue(repo, parent_number, child_db_id):
    gh("api", "-X", "POST", "repos/%s/issues/%d/sub_issues" % (repo, parent_number),
       "--input", "-", input_data=json.dumps({"sub_issue_id": child_db_id}))


# --------------------------------------------------------------------------- #
# Main flow
# --------------------------------------------------------------------------- #
def main():
    ap = argparse.ArgumentParser(description="Create GitHub issues from the plan YAML.")
    ap.add_argument("-i", "--input", default="implementation_plan.yml")
    ap.add_argument("--templates-dir", default=".github/ISSUE_TEMPLATE")
    ap.add_argument("--feature-template", help="path to the feature issue form")
    ap.add_argument("--task-template", help="path to the task issue form")
    ap.add_argument("--repo", help="OWNER/REPO (default: current repository)")
    ap.add_argument("--only", nargs="+", metavar="FEAT-ID", help="only process these features")
    ap.add_argument("--delay", type=float, default=1.0, help="seconds between creations")
    ap.add_argument("--dry-run", action="store_true", help="do not call gh; print what would be done")
    ap.add_argument("-v", "--verbose", action="store_true", help="print rendered bodies in dry-run")
    args = ap.parse_args()

    with open(args.input, encoding="utf-8") as fh:
        plan = yaml.safe_load(fh)

    # Templates -----------------------------------------------------------------
    found = discover_templates(args.templates_dir)
    templates = {}
    for kind, explicit in (("feature", args.feature_template), ("task", args.task_template)):
        if explicit:
            templates[kind] = (explicit, load_form(explicit))
        elif kind in found:
            templates[kind] = found[kind]
        else:
            sys.stderr.write("error: no %s template found in %s (use --%s-template)\n"
                             % (kind, args.templates_dir, kind))
            return 1
    f_path, f_form = templates["feature"]
    t_path, t_form = templates["task"]
    check_form("feature", f_path, f_form, FEATURE_FIELDS)
    check_form("task", t_path, t_form, TASK_FIELDS)

    features = plan["features"]
    if args.only:
        unknown = set(args.only) - {f["id"] for f in features}
        if unknown:
            sys.stderr.write("error: unknown feature(s): %s\n" % ", ".join(sorted(unknown)))
            return 1
        features = [f for f in features if f["id"] in args.only]

    tdd = {s["name"]: s["description"] for s in plan["tdd_methodology"]["steps"]}

    # Repository state ----------------------------------------------------------
    if args.dry_run:
        repo = args.repo or "OWNER/REPO"
        existing = {"feature": {}, "task": {}}
        counter = itertools.count(1)
    else:
        if not shutil.which("gh"):
            sys.stderr.write("error: gh CLI not found in PATH\n")
            return 1
        repo = resolve_repo(args.repo)
        existing = {"feature": {}, "task": {}}
        pats = {"feature": title_pattern(f_form), "task": title_pattern(t_form)}
        for issue in fetch_existing_issues(repo):
            for kind, pat in pats.items():
                m = pat.match(issue["title"])
                if m:
                    existing[kind].setdefault(m.group(1), issue)
        ensure_labels(repo, list(f_form.get("labels") or []) + list(t_form.get("labels") or []))
        counter = itertools.count(1)  # only consumed in dry-run mode
    print("repository: %s%s" % (repo, " (dry run)" if args.dry_run else ""))

    refs = {}      # plan ID -> issue number
    stats = {"created": 0, "existing": 0, "linked": 0}

    def get_or_create(kind, form, ident, text, ctx, providers):
        title = render_title(form, ident, text)
        if ident in existing[kind]:
            issue = dict(existing[kind][ident])
            issue["created"] = False
            stats["existing"] += 1
            print("[%s] exists: #%d %s" % (ident, issue["number"], issue["title"]))
            return issue
        body = render_body(form, build_values(providers, ctx))
        if args.dry_run:
            issue = {"id": None, "number": next(counter), "html_url": "(dry run)", "created": True}
            print("[%s] would create #%d: %s  labels=%s" % (ident, issue["number"], title,
                                                              form.get("labels") or []))
            if args.verbose:
                print("-" * 70 + "\n" + body + "\n" + "-" * 70)
        else:
            issue = create_issue(repo, form, title, body)
            issue["created"] = True
            existing[kind][ident] = issue
            print("[%s] created #%d: %s" % (ident, issue["number"], issue["html_url"]))
            time.sleep(args.delay)
        stats["created"] += 1
        return issue

    # Create features, then their tasks as sub-issues ---------------------------
    for feature in features:
        fctx = {"feature": feature, "refs": refs, "tdd": tdd}
        f_issue = get_or_create("feature", f_form, feature["id"], feature["name"], fctx, FEATURE_FIELDS)
        refs[feature["id"]] = f_issue["number"]

        linked = set()
        if not args.dry_run and not f_issue["created"]:
            linked = list_sub_issue_ids(repo, f_issue["number"])

        for task in feature.get("tasks") or []:
            tctx = {"feature": feature, "task": task, "refs": refs, "tdd": tdd}
            t_issue = get_or_create("task", t_form, task["id"], task["description"], tctx, TASK_FIELDS)
            refs[task["id"]] = t_issue["number"]
            if args.dry_run:
                print("    -> would link #%d as sub-issue of #%d" % (t_issue["number"], f_issue["number"]))
                stats["linked"] += 1
            elif t_issue["id"] in linked:
                continue
            else:
                try:
                    link_sub_issue(repo, f_issue["number"], t_issue["id"])
                    stats["linked"] += 1
                    print("    -> #%d is now a sub-issue of #%d" % (t_issue["number"], f_issue["number"]))
                    time.sleep(args.delay)
                except GhError as exc:
                    sys.stderr.write("warning: could not link #%d to #%d: %s\n"
                                     % (t_issue["number"], f_issue["number"], exc))

    print("\ndone: %(created)d created, %(existing)d already existed, %(linked)d sub-issue links" % stats)
    return 0


if __name__ == "__main__":
    sys.exit(main())