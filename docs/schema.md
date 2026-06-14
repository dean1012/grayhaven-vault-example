# File Schema

This document describes the expected files and data shapes for the private
`grayhaven-vault` repository. Setup instructions are documented in
[Setup](setup.md), and operational procedures are documented in
[Operations](operations.md).

## Table of Contents

- [Required Files](#required-files)
- [`config.yml`](#configyml)
- [`firewall.yml`](#firewallyml)
- [`vault/common.yml`](#vaultcommonyml)
- [`vault/bastion.yml`](#vaultbastionyml)
- [`vault/web.yml`](#vaultwebyml)

## Required Files

Each environment branch must include these files:

```text
config.yml
firewall.yml
vault/common.yml
vault/bastion.yml
vault/web.yml
```

Infrastructure automation does not provide fallback defaults for missing
`config.yml`, `firewall.yml`, or vault files.

[Back to top](#file-schema)

## `config.yml`

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
    - /var/backups/deleted-homedir-archives
    - /home
    - /var/log
  exclude: []
```

Supported keys:

- `certificate_environment`: `staging` or `production`.
- `discord_webhook`: `testing` or `production`.
- `backup.repositories.local.repository_path`: local restic repository path.
- `backup.repositories.local.homedir_archive_path`: local path for removed user
  home directory archives.
- `backup.schedule`: backup schedule. Only `daily` is supported at this time.
- `backup.retention.keep_daily`: number of daily restic snapshots retained.
- `backup.include`: optional list of paths to include in backups. When set,
  include every desired path, including the configured homedir archive path.
- `backup.exclude`: optional list of additional paths to exclude from backups.

Only `backup.repositories.local` is supported at this time.

[Back to top](#file-schema)

## `firewall.yml`

`firewall.yml` is plaintext and is read by OpenTofu and Ansible.

```yaml
firewalls:
  bastion:
    inbound:
      - protocol: tcp
        port_range: "22"
        source_addresses:
          - 0.0.0.0/0
    outbound:
      - protocol: tcp
        port_range: "443"
        destination_addresses:
          - 0.0.0.0/0

  web:
    inbound:
      - protocol: tcp
        port_range: "80"
        source_addresses:
          - 0.0.0.0/0
    outbound:
      - protocol: tcp
        port_range: "443"
        destination_addresses:
          - 0.0.0.0/0
```

Supported top-level keys:

- `firewalls.bastion`: bastion firewall policy.
- `firewalls.web`: web firewall policy.

Supported rule keys:

- `protocol`: network protocol.
- `port_range`: DigitalOcean/firewalld port range.
- `source_addresses`: optional inbound source CIDR list.
- `source_tags`: optional inbound role alias list. Supported aliases are
  `bastion` and `web`.
- `destination_addresses`: optional outbound destination CIDR list.
- `destination_tags`: optional outbound role alias list. Supported aliases are
  `bastion` and `web`.

OpenTofu maps role aliases to the appropriate DigitalOcean cloud firewall tags.
Ansible firewalld policy currently interprets inbound `source_tags: bastion` to
allow SSH from bastions to managed hosts.

[Back to top](#file-schema)

## `vault/common.yml`

`vault/common.yml` stores secrets and private values shared across managed
hosts.

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

Supported keys:

- `root_password_hash`: Linux password hash for the root account.
- `restic_password`: password used by restic to encrypt backups.
- `users`: list of managed users. User operations are documented in
  [Managing Users](operations.md#managing-users).

[Back to top](#file-schema)

## `vault/bastion.yml`

`vault/bastion.yml` stores secrets used by bastion/control-node automation.

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

Supported keys:

- `ansible_control_private_key`: private key used by the active Ansible control
  node to reach managed hosts.
- `ansible_control_public_key`: public key installed for the `ansible`
  automation user on managed hosts.
- `digitalocean_inventory_api_token`: DigitalOcean API token used for dynamic
  inventory discovery.
- `discord_webhooks.production`: production Discord notification webhook URL.
- `discord_webhooks.testing`: testing Discord notification webhook URL.

[Back to top](#file-schema)

## `vault/web.yml`

`vault/web.yml` stores web-hosting secrets.

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

Supported keys:

- `digitalocean_dns_api_token`: DigitalOcean API token used by Certbot DNS-01
  automation in host TLS mode.
- `hosted_domains`: list of domains served by
  [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible).
- `hosted_domains[].domain`: apex domain name.
- `hosted_domains[].static_site`: optional source directory under
  `files/static-sites/` in
  [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible).
  Omit this value to render the generic placeholder site.
- `hosted_domains[].dev.auth_realm`: optional HTTP basic-auth realm for the
  development vhost.
- `hosted_domains[].dev.htpasswd_entries`: full htpasswd file entries for the
  development vhost.

`hosted_domains[].dev.htpasswd_entries` values are credential material and
belong in encrypted vault files in the real private repository.

### Hosted Domain DNS Coordination

When adding a hosted domain, also add matching DNS policy in
[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu).

For hosted web domains, set both `environment.apex: true` and
`environment.web_aliases: true` in the matching environment DNS policy.
`environment.web_aliases` requires `environment.apex`.

The baseline workspace owns shared DNS zones, mail records, and CAA records.
Environment workspaces own computed runtime DNS records for hosted domains.

[Back to top](#file-schema)
