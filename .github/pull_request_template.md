# Pull Request Template

## PR type
Mark with an `x` the corresponding type:

- [ ] `feature` — implements a new feature (branch `feature/`)
- [ ] `hotfix` — one-off bug fix (branch `hotfix/`)
- [ ] `devops` — infrastructure, CI, scripts, documentation or repository configuration (branch `devops/`)
- [ ] `release` — synchronizes `develop` into `main` (branch `release/`)

## Source and target branches

- **Source branch:** `feature/…`, `hotfix/…`, `devops/…` or `release/…`
- **Target branch:** `develop` (for feature/hotfix/devops) or `main` (for release)

## Related issue(s)

Indicate the traceability ID of the issue closed by this PR:

- Feature: `FEAT-001`
- Task: `T-001`
- Hotfix: `HOTFIX-001`

> Example: `Closes #123 — FEAT-001`

## Acceptance criteria completed

List the acceptance criteria IDs fulfilled by this PR:

- [ ] `AC-001` — …
- [ ] `AC-002` — …

## Changes made

Briefly describe what was modified, added or removed.

## Checklist before requesting review

- [ ] Branch created from `develop` (`git checkout develop && git pull && git checkout -b feature/…`)
- [ ] Code complies with C++98 (`-std=c++98`, no `unique_ptr`, lambdas, `auto`, etc.)
- [ ] Compiled with `-Wall -Wextra -Werror -Wpedantic -std=c++98`
- [ ] `make build` completes without errors
- [ ] `make test` passes (unit + integration)
- [ ] `make valgrind` passes with no leaks or errors
- [ ] `make sanitize` passes (if applicable)
- [ ] Documentation updated if necessary
- [ ] Traceability IDs used in commit messages and PR description

## Merge instructions

- **For PRs of type `feature`, `hotfix` or `devops`:** merge into `develop`, **delete the branch** after merge, and **close the corresponding issue** (feature/task/hotfix) when all its acceptance criteria are completed.
- **For PRs of type `release`:** merge `develop` into `main` (direct synchronization, no release pipeline). After merge on `main`, create a version tag (e.g. `v1.0.0`).
