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

1. Create a GitHub issue.
2. Create a focused feature branch for the issue.
3. Sign all commits and reference the issue number.
4. Validate changes locally.
5. Create a pull request for code review.

Target pull requests according to the environment affected:

- Staging-facing changes target `staging`.
- Production-only changes target `main`.
- Changes that should apply to both environments should be validated through a
  pull request from a branch based on `staging` into `staging` first. To promote
  the same approved content to `main`, create a fresh branch from `main`,
  cherry-pick or reapply the staging change, and open that branch against
  `main`.

Do not rely on a direct `staging` to `main` pull request for promotion. The
long-lived branches are squash merged and can have intentionally different
history, so a direct branch-to-branch pull request may report conflicts even
when the file content is already correct.

[Back to top](#contributing)

## Local Validation

Validate formatting and syntax from the repository root:

```bash
git ls-files '*.yml' '*.yaml' | xargs -r yamllint
shellcheck templates/pre-commit
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
- Have no open review conversations.
- Pass all CI checks.
- Document all changes appropriately.

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
