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
certificate:
  environment: staging
  email: admin@example.com
discord_webhook: testing

network:
  vpc_cidr: 10.20.0.0/16

backup:
  repositories:
    local:
      repository_path: /var/backups/restic
      homedir_archive_path: /var/backups/deleted-homedir-archives
    remote:
      provider: gcs
      project_id: grayhaven
      location: US
      storage_class: STANDARD
  schedule: daily
  retention:
    keep_daily: 7
  include:
    - /home
    - /var/log
  exclude: []

observability:
  grafana_cloud:
    enabled: false
    logs_enabled: false

backupctl_repo_url: https://github.com/dean1012/grayhaven-backupctl.git
backupctl_repo_ref: main
backupctl_checkout_dir: /home/ansible/grayhaven-backupctl
```

Supported keys:

- `certificate.environment`: `staging` or `production`.
- `certificate.email`: email address supplied to Certbot for web certificate
  registration and renewal.
- `discord_webhook`: `testing` or `production`.
- `network.vpc_cidr`: environment VPC CIDR block. This value is read by
  OpenTofu when creating the environment VPC and by Ansible when deriving
  private-source fallback rules.
- `backup.repositories.local.repository_path`: local restic repository path.
- `backup.repositories.local.homedir_archive_path`: local path for removed user
  home directory archives.
- `backup.repositories.remote`: optional remote restic repository settings.
  Only Google Cloud Storage is supported at this time.
- `backup.repositories.remote.provider`: remote repository provider. The
  supported value is `gcs`.
- `backup.repositories.remote.project_id`: Google Cloud project ID.
- `backup.repositories.remote.location`: optional Google Cloud Storage bucket
  location. Defaults to `US`.
- `backup.repositories.remote.storage_class`: optional Google Cloud Storage
  bucket storage class. Defaults to `STANDARD`.
- `backup.schedule`: backup schedule. Only `daily` is supported at this time.
- `backup.retention.keep_daily`: number of daily restic snapshots retained.
- `backup.include`: optional list of additional paths to include in backups.
  The configured homedir archive path is always included automatically.
- `backup.exclude`: optional list of additional paths to exclude from backups.
  Excludes can override automatically included paths, including the configured
  homedir archive path.
- `observability.grafana_cloud.enabled`: optional boolean. When true in
  production, enables Grafana Cloud metrics and managed alert-rule automation.
  Defaults to false.
- `observability.grafana_cloud.logs_enabled`: optional boolean. When true and
  Grafana Cloud observability is enabled, enables Grafana Cloud log shipping.
  Defaults to false.
- `backupctl_repo_url`: Git repository URL used by Ansible to install
  `grayhaven-backupctl`. Defaults to
  `https://github.com/dean1012/grayhaven-backupctl.git` if unset.
- `backupctl_repo_ref`: Git ref used by Ansible when checking out
  `grayhaven-backupctl`. Defaults to `main` if unset.
- `backupctl_checkout_dir`: local checkout path for `grayhaven-backupctl` on
  managed hosts. Defaults to `/home/ansible/grayhaven-backupctl` if unset. The
  checkout path must remain below `/home/ansible`.

### Remote Backup Repository

Remote restic repositories are optional. When enabled, Ansible creates one
Google Cloud Storage bucket per managed host before configuring restic. Bucket
names use the short hostname with `-restic` appended.

```yaml
backup:
  repositories:
    local:
      repository_path: /var/backups/restic
      homedir_archive_path: /var/backups/deleted-homedir-archives
    remote:
      provider: gcs
      project_id: grayhaven
      location: US
      storage_class: STANDARD
```

Remote backup buckets are created without object versioning. They are labeled
with operational metadata such as `managed_by=ansible`, `client=grayhaven`,
`env=<environment>`, `project=<project>`, `role=<role>`, `purpose=restic`, and
`host=<short-hostname>`.

When remote backups are enabled, the matching encrypted `vault/common.yml` file
must define the Google Cloud Storage credentials described in
[`vault/common.yml`](#vaultcommonyml).

### Observability

Grafana Cloud observability is supported only for the production environment at
this time. Leave `observability.grafana_cloud.enabled` and
`observability.grafana_cloud.logs_enabled` set to false on the staging
environment.

Staging may still be inspected through the DigitalOcean metrics dashboard.

### Backup Operator Utility

Ansible installs
[`grayhaven-backupctl`](https://github.com/dean1012/grayhaven-backupctl) from
the repository, ref, and checkout path configured in `config.yml`. If those
values are unset, the Ansible role defaults to the public
`grayhaven-backupctl` repository, the `main` branch, and
`/home/ansible/grayhaven-backupctl`.

Keep these values pointed at the reviewed production utility unless
intentionally testing a different branch in a non-production environment. The
checkout path must be below `/home/ansible` so the managed `ansible` user owns
the checkout and convergence can safely clean up old checkout locations when
the configured path changes.

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
        port_range: "80"
        destination_addresses:
          - 0.0.0.0/0
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
      - protocol: tcp
        port_range: "443"
        source_addresses:
          - 0.0.0.0/0
    outbound:
      - protocol: tcp
        port_range: "80"
        destination_addresses:
          - 0.0.0.0/0
      - protocol: tcp
        port_range: "443"
        destination_addresses:
          - 0.0.0.0/0
```

Supported top-level keys:

- `firewalls.bastion`: bastion firewall policy.
- `firewalls.web`: web firewall policy.

The `firewalls.web.inbound` policy must include TCP `80` and TCP `443` rules.
OpenTofu validates this shape before applying the TLS-mode-specific effective
cloud firewall.

It is strongly recommended that each role allow outbound HTTP, HTTPS, DNS, and
NTP traffic unless there is a deliberate reason to narrow egress further. This
normally means TCP `80`, TCP `443`, TCP/UDP `53`, and UDP `123`.

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

restic:
  encryption_password: "example-restic-password"
  remotes:
    gcs:
      credentials_json: |
        {
          "type": "service_account",
          "project_id": "grayhaven",
          "client_email": "restic@example.iam.gserviceaccount.com",
          "private_key": "example-private-key"
        }

users:
  - username: jdoe
    full_name: Jane Doe
    password_hash: "$6$example-admin-password-hash"
    ssh_keys:
      - "ssh-ed25519 AAAAexample jdoe@example"
    sudo: true
    tmux_auto_attach: true
    tmux_workspace: jdoe.tmux
    state: present
```

Supported keys:

- `root_password_hash`: Linux password hash for the root account.
- `restic.encryption_password`: password used by restic to encrypt backups.
- `restic.remotes.gcs.credentials_json`: optional Google Cloud service account
  JSON used to create Google Cloud Storage buckets and access remote restic
  repositories. Required when `backup.repositories.remote.provider` is `gcs`.
- `grafana_cloud`: optional Grafana Cloud credential and endpoint settings.
  Required when `observability.grafana_cloud.enabled` is true.
- `users`: list of managed users. User operations are documented in
  [Managing Users](operations.md#managing-users).

Older vault data may still define the flat `restic_password` key, but new vault
data should use `restic.encryption_password`.

Supported `grafana_cloud` keys:

- `stack_url`: Grafana Cloud stack URL.
- `alloy_api_key`: Grafana Cloud token used by Grafana Alloy for metric and log
  shipping.
- `prometheus.remote_write_url`: Grafana Cloud Prometheus remote-write URL.
- `prometheus.username`: Grafana Cloud Prometheus remote-write username.
- `prometheus.datasource_name`: Grafana Cloud Prometheus datasource name used
  by managed alert-rule automation.
- `loki.push_url`: Grafana Cloud Loki push URL. Required only when
  `observability.grafana_cloud.logs_enabled` is true.
- `loki.username`: Grafana Cloud Loki username. Required only when
  `observability.grafana_cloud.logs_enabled` is true.
- `alerting.api_token`: Grafana Cloud API token used to manage Ansible-owned
  alert rules and initial convergence silences.
- `alerting.folder`: Grafana Cloud folder for managed alert rules. Defaults to
  `Grayhaven Systems LLC`.
- `alerting.evaluation_group`: Grafana Cloud evaluation group for managed alert
  rules. Defaults to `grayhaven-production-1m`.
- `alerting.evaluation_interval`: Grafana Cloud evaluation interval for managed
  alert rules. Defaults to `1m`.
- `alerting.contact_point`: Grafana Cloud contact point for managed alert
  rules. Defaults to `Grafana IRM`.

Supported user keys:

- `username`: Linux username.
- `full_name`: user comment/gecos field.
- `password_hash`: Linux password hash for the account.
- `ssh_keys`: list of public SSH keys installed for the account.
- `sudo`: boolean. When true, password sudo access is enabled for the user.
- `state`: `present` creates and manages the user; `absent` removes the user.
- `home_mode`: optional for absent users. `archive` archives the home directory
  before deletion. `delete` removes the home directory without archiving it.
- `tmux_auto_attach`: optional boolean for sudo users. When true, interactive
  SSH logins to bastion automatically attach to the standard operator tmux
  session. Defaults to false.
- `tmux_workspace`: optional workspace filename for sudo users. The file must
  exist under `files/tmux-workspaces/` and is used by `gtmux` when creating the
  user's tmux session.

The `tmux_*` keys require `sudo: true` because the operator tmux console is for
admin access on bastions.

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
    deployment:
      type: static
      repository:
        url: https://github.com/example/grayhaven-web.git
        webhook_secret: "example_grayhaven_deploy_webhook_secret"
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
- `hosted_domains[].deployment`: optional website deployment configuration.
  Omit this block to render the generic fallback site.
- `hosted_domains[].deployment.type`: website deployment type. Only `static`
  is supported.
- `hosted_domains[].deployment.repository.url`: required public HTTPS Git
  repository used for static website content. For `type: static`, the `main`
  branch deploys `site/frontend/` to the apex and `www` document root, and the
  `dev` branch deploys `site/frontend/` to the development document root.
- `hosted_domains[].deployment.repository.webhook_secret`: required shared
  secret for hosted-domain deployment webhooks. Set this to the matching
  [`GRAYHAVEN_DEPLOY_WEBHOOK_SECRET`](setup.md#set-up-hosted-domain-repositories)
  repository secret value.
  The same setup section documents the matching hosted-domain repository
  variables, including `GRAYHAVEN_DEPLOY_WEBHOOK_URL`,
  `GRAYHAVEN_DEPLOY_WEBHOOK_DISABLE`, and
  `GRAYHAVEN_DEPLOY_DISABLE_SSL_VERIFICATION`.
  Hosted-domain deployment workflows should fail clearly if the required
  webhook URL or shared secret is missing.
- `hosted_domains[].dev`: required development vhost configuration. Every
  hosted domain receives a development vhost.
- `hosted_domains[].dev.auth_realm`: optional HTTP basic-auth realm for the
  development vhost.
- `hosted_domains[].dev.htpasswd_entries`: required full htpasswd file entries
  for the development vhost. At least one entry is required.

`hosted_domains[].dev.htpasswd_entries` values are credential material and
belong in encrypted vault files in `grayhaven-vault`.

### Hosted Domain DNS Coordination

When adding a hosted domain, also add matching
[environment DNS policy](https://github.com/dean1012/grayhaven-infra-opentofu/blob/main/docs/policy.md#environment-dns-policy)
in the
[grayhaven-infra-opentofu](https://github.com/dean1012/grayhaven-infra-opentofu)
repository.

For hosted web domains, set both `environment.apex: true` and
`environment.web_aliases: true` in the matching environment DNS policy.
`environment.web_aliases` requires `environment.apex`.

The baseline workspace owns shared DNS zones, mail records, and CAA records.
Environment workspaces own computed runtime DNS records for hosted domains.

[Back to top](#file-schema)
