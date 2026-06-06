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

## Repository Purpose

`grayhaven-vault` separates private operational data from public automation
code while preserving a documented interface between the repositories.

- [`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
  reads `config.yml` from a local checkout during OpenTofu planning and apply.
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

## Branch Model

The private repository uses branches to represent environments:

- `main`: production values.
- `staging`: staging values.

Each branch contains the same file layout:

```text
config.yml
vault/common.yml
vault/bastion.yml
vault/web.yml
```

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

### `vault/web.yml`

`vault/web.yml` stores web-hosting secrets.

Sample shape:

```yaml
digitalocean_dns_api_token: "dop_v1_example_dns_token"
dev_basic_auth_htpasswd_line: "developer:$2y$05$example"
```

Variables:

- `digitalocean_dns_api_token`:
  - DigitalOcean token used by Certbot DNS-01 automation in host TLS mode.
- `dev_basic_auth_htpasswd_line`:
  - htpasswd line used for development-site HTTP basic authentication. This
    value is shared across all hosted domains.

## Vault Encryption

The real private repository keeps `config.yml` plaintext and encrypts all files
under `vault/` with Ansible Vault before use.

This example repository keeps `vault/` files in plaintext only so the expected
variable names and data shapes can be inspected safely. Plaintext `vault/`
files are unsafe for operational use.

Use a strong, randomly generated vault password. A shell-friendly generated
password can be produced with:

```bash
openssl rand -hex 48
```

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

## Deploy Key Setup

The real private repository is accessed by automation through a dedicated
read-only GitHub deploy key. The deploy key should be unique to the private
vault repository. Do not use a personal SSH key.

The private key is handed to bastion hosts through OpenTofu during environment
deployment. Each deployment environment should use a separate deploy key.
