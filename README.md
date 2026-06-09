# Grayhaven Vault Example

This repository documents the expected shape of the private `grayhaven-vault`
repository used by Grayhaven Systems LLC infrastructure automation.

The Grayhaven infrastructure repositories are public for transparency and
operational demonstration. They show how Grayhaven Systems LLC manages its own
infrastructure, but they do not store client infrastructure, client credentials,
private deployment data, private SSH keys, secrets, or operational state.

This example repository intentionally contains fake plaintext sample data. It
should not be used operationally without configuration and appropriate
encryption.

## Table of Contents

- [Repository Purpose](#repository-purpose)
- [Branch Model](#branch-model)
- [Required Files](#required-files)
- [Vault Encryption](#vault-encryption)
- [Vault Password Rotation](#vault-password-rotation)
- [Generating Password Hashes](#generating-password-hashes)
- [Generating API Keys](#generating-api-keys)
- [Deploy Key](#deploy-key)

## Repository Purpose

`grayhaven-vault` separates private operational data from public automation
code while preserving a documented interface between the repositories.

- [`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
  reads `config.yml` from a workspace-selected Git ref in a local checkout
  during OpenTofu planning and apply.
- [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
  pulls the private repository on the active control bastion during
  convergence.
- `config.yml` remains plaintext because it contains selectors and operational
  settings, not secrets.
- Files under `vault/` are intentionally unencrypted for demonstration
  purposes. They should be encrypted with Ansible Vault before committing to a
  private operational repository.

This repository is not a general-purpose deployment template. Deploying similar
automation for another organization requires review and adaptation.

[Back to top](#grayhaven-vault-example)

## Branch Model

The private repository uses branches to represent environments:

- `main`: production values.
- `staging`: staging values.

[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
reads `config.yml` from the appropriate Git ref:

- staging workspace: `staging:config.yml`
- production workspace: `main:config.yml`

[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
checks out the same environment ref on the active control bastion and reads
the matching `config.yml` and `vault/*.yml` files during convergence.

The local checkout branch does not need to match the OpenTofu workspace, but
the required refs must be fetched locally.

Each branch contains the same file layout:

```text
config.yml
vault/common.yml
vault/bastion.yml
vault/web.yml
```

[Back to top](#grayhaven-vault-example)

## Required Files

### `config.yml`

`config.yml` is plaintext and is read by both OpenTofu and Ansible.

```yaml
certificate_environment: staging
discord_webhook: testing

backup:
  repositories:
    local:
      repository_path: /var/backups/restic
      homedir_archive_path: /var/backups/deleted-homedir-archives
  schedule: daily
  retention:
    keep_daily: 7
  include:
    - /home
    - /var/log
  exclude: []
```

Variables:

- `certificate_environment`: `staging` or `production`.
  - TLS mode is selected by the compute policy in
    [`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu).
  - Host TLS mode:
    - `staging`: Certbot uses Let's Encrypt staging.
    - `production`: Certbot uses live Let's Encrypt.
  - Load balancer TLS mode:
    - `staging`: OpenTofu uses a self-signed load balancer certificate.
    - `production`: OpenTofu uses a DigitalOcean-managed live Let's Encrypt
      certificate.
- `discord_webhook`: `testing` or `production`.
  - Selects which Discord webhook secret is used by automation notifications.
- `backup.repositories.local.repository_path`:
  - Local restic repository path on each managed server.
- `backup.repositories.local.homedir_archive_path`:
  - Local path where removed user home directories are archived.
- `backup.schedule`:
  - Backup schedule. Only `daily` is supported at this time.
- `backup.retention.keep_daily`:
  - Number of daily restic snapshots retained.
- `backup.include`:
  - Optional list of paths to include in backups.
  - If omitted, automation includes `homedir_archive_path`, `/home`, and
    `/var/log`.
- `backup.exclude`:
  - Optional list of additional paths to exclude from backups.

Only `backup.repositories.local` is supported at this time.

[Back to top](#grayhaven-vault-example)

### `vault/common.yml`

`vault/common.yml` stores secrets and private values shared across managed
hosts.

Sample shape:

```yaml
root_password_hash: "$6$example-root-password-hash"
restic_password: "example-restic-password"

users:
  - username: jdoe
    full_name: Jane Doe
    password_hash: "$6$example-admin-password-hash"
    ssh_keys:
      - "ssh-ed25519 AAAAexample jdoe@example"
    sudo: true
    state: present
```

Variables:

- `root_password_hash`:
  - Linux password hash for the root account.
- `restic_password`:
  - Password used by restic to encrypt backups.
- `users`:
  - List of managed users.
- `users[].username`:
  - Linux username.
- `users[].full_name`:
  - User comment/gecos field.
- `users[].password_hash`:
  - Linux password hash for the user account.
- `users[].ssh_keys`:
  - List of public SSH keys installed for the user account.
- `users[].sudo`:
  - Boolean. When true, password sudo access is enabled for the user.
- `users[].state`:
  - `present` creates and manages the user.
  - `absent` removes the user. Requires `username` to be defined. See
    `home_mode`.
- `users[].home_mode`:
  - May be optionally specified when `state` is set to `absent`.
  - `archive` archives and compresses the user's home directory before user
    deletion. This is the default.
  - `delete` removes the user's home directory alongside user deletion.
    Warning: this results in data loss.

[Back to top](#grayhaven-vault-example)

### `vault/bastion.yml`

`vault/bastion.yml` stores secrets used by bastion/control-node automation.

Sample shape:

```yaml
ansible_control_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  example
  -----END OPENSSH PRIVATE KEY-----
ansible_control_public_key: "ssh-ed25519 AAAAexample ansible@example"

digitalocean_inventory_api_token: "dop_v1_example_inventory_token"

discord_webhooks:
  production: "https://discord.com/api/webhooks/example/production"
  testing: "https://discord.com/api/webhooks/example/testing"
```

Variables:

- `ansible_control_private_key`:
  - Private key used by the active Ansible control node to reach managed hosts.
- `ansible_control_public_key`:
  - Public key installed for the `ansible` automation user on managed hosts.
- `digitalocean_inventory_api_token`:
  - DigitalOcean token used for dynamic inventory discovery.
- `discord_webhooks.production`:
  - Production Discord notification webhook URL.
- `discord_webhooks.testing`:
  - Testing Discord notification webhook URL.

[Back to top](#grayhaven-vault-example)

### `vault/web.yml`

`vault/web.yml` stores web-hosting secrets.

Sample shape:

```yaml
digitalocean_dns_api_token: "dop_v1_example_dns_token"

hosted_domains:
  - domain: grayhavensystems.com
    static_site: grayhavensystems.com
    dev:
      auth_realm: Grayhaven Systems LLC Development Environment
      htpasswd_entries:
        - "developer:$2y$05$example-grayhaven"

  - domain: example.com
    dev:
      htpasswd_entries:
        - "developer:$2y$05$example-generic"
```

Variables:

- `digitalocean_dns_api_token`:
  - DigitalOcean token used by Certbot DNS-01 automation in host TLS mode.
- `hosted_domains`:
  - List of domains served by
    [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible).
- `hosted_domains[].domain`:
  - Apex domain name. Staging derives `staging.<domain>`,
    `www.staging.<domain>`, and `dev.staging.<domain>`. Production derives
    `<domain>`, `www.<domain>`, and `dev.<domain>`.
- `hosted_domains[].static_site`:
  - Optional source directory under `files/static-sites/` in
    [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible).
    Omit this value to render the generic placeholder site.
- `hosted_domains[].dev.auth_realm`:
  - Optional HTTP basic-auth realm for the development vhost. If omitted,
    Ansible uses `<domain> Development Environment`.
- `hosted_domains[].dev.htpasswd_entries`:
  - Full htpasswd file entries for the development vhost. These entries are
    credential material and belong in encrypted vault files in the real private
    repository.

When adding a new hosted domain, also add matching DNS policy in
[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu).
The baseline workspace owns shared DNS and mail records; staging and
production own only environment web records.

[Back to top](#grayhaven-vault-example)

## Vault Encryption

The real private repository keeps `config.yml` plaintext and encrypts all files
under `vault/` with Ansible Vault before use.

This example repository keeps `vault/` files in plaintext only so the expected
variable names and data shapes can be inspected safely. The sample values are
fake, intentionally generic, and unsafe for operational use.

Use a strong, randomly generated vault password. A shell-friendly generated
password can be produced with:

```bash
openssl rand -hex 48
```

[Back to top](#grayhaven-vault-example)

## Vault Password Rotation

In the real private repository, rotate each environment branch deliberately:

1. Generate a new strong vault password.
2. Check out the target environment branch, such as `staging` or `main`.
3. Rekey all encrypted vault files with Ansible Vault:

   ```bash
   ansible-vault rekey vault/common.yml vault/bastion.yml vault/web.yml
   ```

4. Lint the plaintext `config.yml` and confirm the vault files remain
   encrypted before committing.
5. Update the matching infra environment variable:
   `TF_VAR_grayhaven_vault_password_staging` for staging or
   `TF_VAR_grayhaven_vault_password_prod` for production.
6. In
   [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible),
   run `playbooks/rotate-vault-password.yml` from the active control bastion so
   deployed bastions persist the new password.
7. Start a manual runner invocation and confirm it can decrypt the vault.

If the OpenTofu state encryption passphrase is also being rotated, follow the
state passphrase rotation procedure documented in
[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
so OpenTofu writes state with the new state encryption passphrase. Updating the
Ansible Vault password variables alone does not re-encrypt OpenTofu state.

[Back to top](#grayhaven-vault-example)

## Generating Password Hashes

Generate Linux password hashes for user accounts by using:

```bash
openssl passwd -6
```

Generate an htpasswd line for development HTTP basic authentication:

```bash
htpasswd -nB username
```

The `htpasswd` command is provided by the `httpd-tools` package on Red Hat
distributions.

[Back to top](#grayhaven-vault-example)

## Generating API Keys

DigitalOcean API keys should be tightly scoped to the access required by the
automation that uses them.

The `digitalocean_inventory_api_token` value should be scoped as follows:

| Resource Type | Permissions |
| ------------- | ----------- |
| actions       | read        |
| regions       | read        |
| sizes         | read        |
| domain        | read        |
| droplet       | read        |
| firewall      | read        |
| image         | read        |
| project       | read        |
| snapshot      | read        |
| ssh_key       | read        |
| tag           | read        |
| vpc           | read        |

The `digitalocean_dns_api_token` value should be scoped as follows:

| Resource Type | Permissions                         |
| ------------- | ----------------------------------- |
| domain        | create, read, update, delete        |

[Back to top](#grayhaven-vault-example)

## Deploy Key

Automation accesses the private vault repository through a read-only GitHub
deploy key. The key is configured in GitHub for that repository and is supplied
to deployed infrastructure through
[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu).

[Back to top](#grayhaven-vault-example)
