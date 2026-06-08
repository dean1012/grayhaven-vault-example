# Contributing

Thank you for your interest in improving `grayhaven-vault-example`.

This repository documents the expected shape of the private `grayhaven-vault`
repository used by Grayhaven Systems LLC infrastructure automation. It contains
sample values only and must not contain real secrets, private deployment data,
private SSH keys, credentials, or operational state.

Do not encrypt files in this repository.

## Table of Contents

- [Development Setup](#development-setup)
- [Validation](#validation)
- [Pull Requests](#pull-requests)
- [Safety Guidelines](#safety-guidelines)

## Development Setup

Install the validation tools used by CI:

```bash
python3 -m pip install --upgrade pip
python3 -m pip install yamllint
npm install --global markdownlint-cli2
```

[Back to top](#contributing)

## Validation

Run the same validation commands used by CI:

```bash
git ls-files '*.yml' '*.yaml' | xargs -r yamllint
git ls-files '*.md' | xargs -r markdownlint-cli2
```

Before committing changes, also check the current diff for whitespace errors:

```bash
git diff --check
```

[Back to top](#contributing)

## Pull Requests

Create an issue and a focused feature branch for each change. Pull requests
must be submitted before changes are merged.

Target pull requests according to the environment affected:

- Production-facing or shared changes target `main`.
- Staging-facing changes target `staging`.
- Changes that should apply to both environments should be merged into
  `staging` first, then promoted through a pull request from `staging` to
  `main`.

Sign each commit so GitHub can verify its authorship:

```bash
git commit -S -m "<message>"
```

CI runs on pushes and pull requests. Pull requests are squash merged after CI
passes and review conversations are resolved.

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
