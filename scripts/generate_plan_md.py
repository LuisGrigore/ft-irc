#!/usr/bin/env python3
"""Generate the implementation plan Markdown from its YAML source.

Usage:
    python3 generate_plan_md.py [-i implementation_plan.yml] [-o IMPLEMENTATION_PLAN.md]
    python3 generate_plan_md.py -o -        # write to stdout

Requires PyYAML (pip install pyyaml).

The rendering rules are documented at the top of the YAML file. In short:
  * Tables 1-3 are built from features[*], features[*].tasks[*] and
    features[*].acceptance_criteria[*].
  * Ranges ("T-001 to T-015") and dependency labels are derived, not stored.
"""

import argparse
import sys

import yaml

TDD_STEPS = ("Red", "Green", "Refactor")


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def code(text):
    return "`%s`" % text


def cell(text):
    """Escape a value for use inside a Markdown table cell."""
    return str(text).replace("|", "\\|")


def render_elements(elements):
    """`*.mmd` references become inline code; anything else stays plain text."""
    return ", ".join(code(e) if str(e).endswith(".mmd") else str(e) for e in elements)


def span(ids):
    if not ids:
        return "none"
    return ids[0] if len(ids) == 1 else "%s to %s" % (ids[0], ids[-1])


def depends_text(feature):
    label = feature.get("depends_on_label")
    if label:
        return label
    deps = feature.get("depends_on") or []
    return ", ".join(deps) if deps else "None"


def table(headers, rows):
    """Render a Markdown table with the compact style used by the plan."""
    out = ["| " + " | ".join(headers) + " |"]
    out.append("|" + "|".join("-" * (len(h) + 2) for h in headers) + "|")
    for row in rows:
        out.append("| " + " | ".join(cell(c) for c in row) + " |")
    return out


def id_table(headers, rows):
    """Like `table`, but pads the first column (used for the ID-prefix table)."""
    width = max([len(headers[0])] + [len(str(r[0])) for r in rows])
    out = ["| %s | %s |" % (headers[0].ljust(width), headers[1])]
    out.append("|%s|%s|" % ("-" * (width + 2), "-" * (len(headers[1]) + 2)))
    for r in rows:
        out.append("| %s | %s |" % (str(r[0]).ljust(width), cell(r[1])))
    return out


# --------------------------------------------------------------------------- #
# Validation
# --------------------------------------------------------------------------- #
def validate(data):
    errors = []
    feature_ids = [f["id"] for f in data["features"]]
    seen = set()

    def check_unique(kind, ident):
        if ident in seen:
            errors.append("duplicate %s id: %s" % (kind, ident))
        seen.add(ident)

    for f in data["features"]:
        check_unique("feature", f["id"])
        for dep in f.get("depends_on") or []:
            if dep not in feature_ids:
                errors.append("%s depends on unknown feature %s" % (f["id"], dep))
        for t in f.get("tasks") or []:
            check_unique("task", t["id"])
            if t.get("tdd_step") not in TDD_STEPS:
                errors.append("%s has invalid tdd_step %r" % (t["id"], t.get("tdd_step")))
        for ac in f.get("acceptance_criteria") or []:
            check_unique("acceptance criterion", ac["id"])
    return errors


# --------------------------------------------------------------------------- #
# Rendering
# --------------------------------------------------------------------------- #
def render(data):
    doc = data["document"]
    features = data["features"]
    all_tasks = [(f, t) for f in features for t in (f.get("tasks") or [])]
    all_acs = sorted(
        ((f, ac) for f in features for ac in (f.get("acceptance_criteria") or [])),
        key=lambda pair: pair[1]["id"],
    )

    out = []
    sep = ["---", ""]

    # Header ---------------------------------------------------------------
    out += ["# " + doc["title"], "", doc["intro"], ""]
    for src in doc["sources"]:
        path, _, rest = str(src).partition(" ")
        out.append("- %s%s" % (code(path), (" " + rest) if rest else ""))
    out += ["", doc["id_scheme_intro"], ""]
    out += id_table(
        ["Prefix", "Meaning"],
        [(p["prefix"], p["meaning"]) for p in doc["id_prefixes"]],
    )
    out += ["", "---", ""]

    # 1. Features table ----------------------------------------------------
    out += ["## 1. Features Table", ""]
    out += table(
        ["ID", "Name", "Short Description", "Related Elements"],
        [
            (f["id"], f["name"], f["short_description"], render_elements(f["related_elements"]))
            for f in features
        ],
    )
    out += ["", "---", ""]

    # 2. Tasks table -------------------------------------------------------
    out += ["## 2. Tasks Table", ""]
    out += table(
        ["ID", "Description", "TDD Step", "Feature ID", "Related Elements"],
        [
            (t["id"], t["description"], t["tdd_step"], f["id"], render_elements(t["related_elements"]))
            for f, t in all_tasks
        ],
    )
    out += ["", "---", ""]

    # 3. Acceptance criteria table ----------------------------------------
    out += ["## 3. Acceptance Criteria Table", ""]
    out += table(
        ["ID", "Description", "Associated Element"],
        [(ac["id"], ac["description"], f["id"]) for f, ac in all_acs],
    )
    out += ["", "---", ""]

    # Constraints ----------------------------------------------------------
    constraints = data["constraints"]
    out += ["## " + constraints["title"], ""]
    for c in constraints["items"]:
        if "items" in c:
            body = ", ".join(code(x) for x in c["items"])
        else:
            body = c["text"]
        out.append("- **%s**%s%s" % (c["label"], c.get("separator", ": "), body))
    out += ["", "---", ""]

    # TDD methodology ------------------------------------------------------
    tdd = data["tdd_methodology"]
    out += ["## " + tdd["title"], "", tdd["intro"], ""]
    for i, step in enumerate(tdd["steps"], 1):
        out.append("%d. **%s** — %s" % (i, step["name"], step["description"]))
    out += ["", tdd["ordering_note"], "", "---", ""]

    # 4. Detailed breakdown ------------------------------------------------
    out += ["## 4. Detailed Breakdown by Feature", ""]
    for f in features:
        task_ids = [t["id"] for t in (f.get("tasks") or [])]
        ac_ids = sorted(ac["id"] for ac in (f.get("acceptance_criteria") or []))
        out += ["### %s — %s" % (f["id"], f["name"]), "", f["detailed_description"], ""]
        out.append("**Tasks:** %s  " % span(task_ids))
        out.append("**Acceptance Criteria:** %s  " % span(ac_ids))
        out.append("**Depends on:** %s" % depends_text(f))
        out.append("")
    out += ["---", ""]

    # Dependency summary ---------------------------------------------------
    out += ["## Dependency Summary", ""]
    rows = []
    for f in features:
        text = depends_text(f)
        if f.get("dependency_rationale"):
            text += " (%s)" % f["dependency_rationale"]
        rows.append((f["id"], text))
    out += table(["Feature", "Depends On"], rows)

    return "\n".join(out) + "\n"


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #
def main():
    parser = argparse.ArgumentParser(description="Generate the plan Markdown from YAML.")
    parser.add_argument("-i", "--input", default="implementation_plan.yml",
                        help="YAML source (default: implementation_plan.yml)")
    parser.add_argument("-o", "--output", default="IMPLEMENTATION_PLAN.md",
                        help="Markdown output path, or '-' for stdout (default: IMPLEMENTATION_PLAN.md)")
    args = parser.parse_args()

    with open(args.input, encoding="utf-8") as fh:
        data = yaml.safe_load(fh)

    errors = validate(data)
    if errors:
        for e in errors:
            sys.stderr.write("error: %s\n" % e)
        return 1

    markdown = render(data)
    if args.output == "-":
        sys.stdout.write(markdown)
    else:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(markdown)
        sys.stderr.write("wrote %s\n" % args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())