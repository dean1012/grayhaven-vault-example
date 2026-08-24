# Contributing

This document is intended for Grayhaven Systems LLC employees and assumes that
this repository has been initialized and configured appropriately.

If you are not a Grayhaven Systems LLC employee, we still welcome your support
and contribution.

This repository documents the expected shape of the private `grayhaven-vault`
repository used by Grayhaven Systems LLC infrastructure automation. It contains
sample values only and must not contain real secrets, private deployment data,
private SSH keys, credentials, or operational state.

Do not encrypt files in this repository.

## Table of Contents

- [Development Setup](#development-setup)
- [Workflow](#workflow)
- [Local Validation](#local-validation)
- [Pull Requests](#pull-requests)
- [Safety Guidelines](#safety-guidelines)

## Development Setup

Install the validation tools used by CI:

```bash
sudo dnf install ShellCheck
python3 -m pip install --upgrade pip
python3 -m pip install yamllint
npm install --global markdownlint-cli2
```

[Back to top](#contributing)

## Workflow

The protected `staging` and `main` branches prohibit direct pushes. Changes must
be delivered through signed, ready-for-review pull requests, with all review
conversations resolved and the required check exactly `validate` passing. Only
squash merges are permitted: merge commits, rebase merges, and bypasses are
prohibited. Automatic source-branch deletion is disabled, so clean up each
source branch manually after its pull request is complete.

1. Create a GitHub issue.
2. Create a focused feature branch for the issue.
3. Sign all commits and reference the issue number.
4. Validate changes locally.
5. Create a ready-for-review, non-draft pull request for code review.

Target pull requests according to the environment affected:

- Staging-facing changes target `staging`.
- Production-only changes target `main`.
- Changes that should apply to both environments must use separate branches and
  pull requests: first create a branch from exact `origin/staging`, and land
  its pull request in `staging`. Then create a fresh branch from exact
  `origin/main`, reapply the same logical change, and land a separate pull
  request in `main`.

Never open a `staging` to `main` pull request or promote by merging `staging`
into `main`. The long-lived branches are squash merged and can have
intentionally different history, so a direct branch-to-branch pull request may
report conflicts even when the file content is already correct.

[Back to top](#contributing)

## Local Validation

Validate formatting and syntax from the repository root:

```bash
git ls-files '*.yml' '*.yaml' | xargs -r yamllint
shellcheck templates/pre-commit files/tmux-workspaces/jdoe.tmux
git ls-files '*.md' | xargs -r markdownlint-cli2
```

Before committing changes, also check the current diff for whitespace errors:

```bash
git diff --check
```

[Back to top](#contributing)

## Pull Requests

Pull requests must meet all of these requirements to be merged:

- Reference or close a GitHub issue as appropriate.
- Contain signed commits.
- Be ready for review and not be a draft.
- Have all review conversations resolved.
- Pass the required `validate` check exactly.
- Use squash merge only; merge commits, rebase merges, and bypasses are not
  permitted.
- Document all changes appropriately.
- Have the source branch cleaned up manually after completion because automatic
  branch deletion is disabled.

[Back to top](#contributing)

## Safety Guidelines

- Do not submit real credentials, private keys, tokens, hashes, passwords,
  customer data, deployment data, or operational state.
- Keep all sample values generic and fake.
- Real-looking sensitive data will not be merged.
- If real information is submitted, rotate it immediately.

Grayhaven Systems LLC is not responsible for third-party contributions that
expose personal data, credentials, keys, or other sensitive material.

[Back to top](#contributing)
