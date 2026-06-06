# Contributing

Thank you for your interest in improving `grayhaven-vault-example`.

This repository documents the expected shape of the private `grayhaven-vault`
repository used by Grayhaven Systems LLC infrastructure automation. It contains
sample values only and must not contain real secrets, private deployment data,
private SSH keys, credentials, or operational state.

Do not encrypt files in this repository.

## Branches

Use the branch that matches the environment being documented:

- `main`: production-facing examples and shared documentation.
- `staging`: staging-facing examples.

When a change applies to both environments, update both branches.

## Development Setup

Install the validation tools used by CI:

```bash
python3 -m pip install --upgrade pip
python3 -m pip install yamllint
npm install --global markdownlint-cli2
```

## Validation

Run the same validation commands used by CI:

```bash
yamllint .
markdownlint-cli2 '**/*.md'
```

Before committing changes, also check the current diff for whitespace errors:

```bash
git diff --check
```

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

## Safety Guidelines

- Do not submit real credentials, private keys, tokens, hashes, passwords,
  customer data, deployment data, or operational state.
- Keep all sample values generic and fake.
- Real-looking sensitive data will not be merged.
- If real information is submitted, rotate it immediately.

Grayhaven Systems LLC is not responsible for third-party contributions that
expose personal data, credentials, keys, or other sensitive material.
