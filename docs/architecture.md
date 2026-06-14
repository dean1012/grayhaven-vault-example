# Architecture

This document describes how the private `grayhaven-vault` repository is used by
Grayhaven Systems LLC infrastructure automation. File formats are documented in
[File Schema](schema.md).

## Table of Contents

- [Repository Role](#repository-role)
- [Branch Model](#branch-model)
- [Automation Consumers](#automation-consumers)

## Repository Role

The private `grayhaven-vault` repository provides environment-specific
configuration, shared plaintext selectors, and encrypted operational values.

In the real private repository:

- `config.yml` and `firewall.yml` remain plaintext.
- Files under `vault/` are encrypted with Ansible Vault.
- Each environment branch carries a complete configured copy of all required
  files.

This public example repository keeps all sample files plaintext so the expected
shape can be inspected safely. All sample values are fake.

[Back to top](#architecture)

## Branch Model

The private repository uses branches to represent environments:

- `main`: production values.
- `staging`: staging values.

The local checkout branch does not need to match the active OpenTofu workspace,
but the required refs must be fetched locally.

[Back to top](#architecture)

## Automation Consumers

[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
reads `config.yml` and `firewall.yml` from the workspace-selected Git ref in a
local checkout during OpenTofu plan and apply.

[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
checks out the same environment ref on the active control bastion during
convergence and reads the matching `config.yml`, `firewall.yml`, and
`vault/*.yml` files.

[Back to top](#architecture)
