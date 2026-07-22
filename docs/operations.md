# Operations

This document describes `grayhaven-vault` maintenance procedures.
Repository initialization is documented in [Setup](setup.md), and file formats
are documented in [File Schema](schema.md).

## Table of Contents

- [Vault Encryption](#vault-encryption)
- [Vault Password Rotation](#vault-password-rotation)
- [Managing Users](#managing-users)
- [Managing Operator Tmux Workspaces](#managing-operator-tmux-workspaces)
- [Remote Backup Bucket Cleanup](#remote-backup-bucket-cleanup)
- [Generating Password Hashes](#generating-password-hashes)
- [Managing Time Tracker Credentials and Data](#managing-time-tracker-credentials-and-data)
- [Generating API Keys](#generating-api-keys)
- [Rotating Website Deployment Secrets](#rotating-website-deployment-secrets)
- [Deploy Key](#deploy-key)

## Vault Encryption

The real private repository keeps `config.yml` and `firewall.yml` plaintext and
encrypts all files under `vault/` with Ansible Vault before use.

This example repository keeps `vault/` files in plaintext only so the expected
variable names and data shapes can be inspected safely. The sample values are
fake, intentionally generic, and unsafe for operational use.

Use a strong, randomly generated vault password. A shell-friendly generated
password can be produced with:

```bash
openssl rand -hex 48
```

[Back to top](#operations)

## Vault Password Rotation

In the real private repository, rotate each environment branch deliberately:

1. Generate a new strong vault password.
2. Check out the target environment branch, such as `staging` or `main`.
3. Rekey all encrypted vault files with Ansible Vault:

   ```bash
   ansible-vault rekey vault/*.yml
   ```

4. Lint the plaintext files and confirm the vault files remain encrypted before
   committing.
5. Update the matching
   [`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
   environment variable: `TF_VAR_grayhaven_vault_password_staging` for staging
   or `TF_VAR_grayhaven_vault_password_prod` for production.
6. In
   [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible),
   run `playbooks/rotate-vault-password.yml` from the active control bastion so
   deployed bastions persist the new password.
7. Start a manual runner invocation and confirm it can decrypt the vault.

If the OpenTofu state encryption passphrase is also being rotated, follow the
state passphrase rotation procedure documented in the
[OpenTofu state encryption passphrase rotation documentation](https://github.com/dean1012/grayhaven-infra-opentofu/blob/main/docs/operations.md#opentofu-state-encryption-passphrase-rotation)
in `grayhaven-infra-opentofu`
so OpenTofu writes state with the new state encryption passphrase. Updating the
Ansible Vault password variables alone does not re-encrypt OpenTofu state.

[Back to top](#operations)

## Managing Users

Managed users are defined in `vault/common.yml` under `users`.

To add or update a managed user:

1. Check out the target environment branch.
2. Decrypt `vault/common.yml`.
3. Add or update the desired `users` entry.
4. Encrypt `vault/common.yml`.
5. Commit and push the branch.

Supported user keys:

- `username`: Linux username.
- `full_name`: user comment/gecos field.
- `password_hash`: Linux password hash for the account.
- `ssh_keys`: list of public SSH keys installed for the account.
- `sudo`: boolean. When true, password sudo access is enabled for the user.
- `state`: `present` creates and manages the user; `absent` removes the user.
- `home_mode`: optional for absent users. `archive` archives the home directory
  before deletion. `delete` removes the home directory without archiving it.

Homedir archives are not encrypted by the archive process. They are included in
the encrypted local restic backup set by default.

[Back to top](#operations)

## Managing Operator Tmux Workspaces

Operator tmux workspaces are optional and apply only to managed users with
`sudo: true`. Store workspace files under `files/tmux-workspaces/`, then set
the user's `tmux_workspace` value in `vault/common.yml` to the workspace
filename.

To automatically attach an administrator to tmux when they connect to bastion,
set `tmux_auto_attach: true` for that user. If `tmux_auto_attach` is omitted,
it defaults to false.

This repository includes `files/tmux-workspaces/jdoe.tmux` as a sanitized
example. Real workspace files can contain private operator preferences and
belong in `grayhaven-vault`.

The
[operator tmux architecture](https://github.com/dean1012/grayhaven-config-ansible/blob/main/docs/operator-tmux-architecture.md)
documentation in
[grayhaven-config-ansible](https://github.com/dean1012/grayhaven-config-ansible)
explains how `gtmux` loads workspace files and how to capture an interactive
tmux layout.

[Back to top](#operations)

## Remote Backup Bucket Cleanup

When optional Google Cloud Storage remote backups are enabled, one restic bucket
is created for each managed host. Removing a host from the live inventory does
not automatically delete its remote backup bucket.

The
[GCS restic bucket cleanup](https://github.com/dean1012/grayhaven-config-ansible/blob/main/docs/operations.md#gcs-restic-bucket-cleanup)
procedure in
[grayhaven-config-ansible](https://github.com/dean1012/grayhaven-config-ansible)
compares the live inventory with labeled remote backup buckets. Treat that
procedure as destructive maintenance and review the dry-run output carefully
before allowing deletion.

[Back to top](#operations)

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

[Back to top](#operations)

## Managing Time Tracker Credentials and Data

Time Tracker public deployment settings belong in `config.yml` under
`timetracker`. Credential material belongs in encrypted `vault/web.yml` under
the separate `timetracker_secrets` mapping.

Generate bootstrap password hashes and optional TOTP secrets with the approved
published application image. Follow the authoritative
[Time Tracker configuration documentation](https://github.com/dean1012/grayhaven-timetracker/blob/main/docs/configuration.md)
rather than reproducing application commands in this repository. Bootstrap
users are created only for an empty application database and must change their
initial passwords at first sign-in.

Backup, restore verification, SQLCipher rekey, rollback, and disaster-recovery
procedures are maintained in the authoritative
[Time Tracker operations documentation](https://github.com/dean1012/grayhaven-timetracker/blob/main/docs/operations.md).
Treat the SQLCipher passphrase and encrypted database artifacts as one recovery
set. Never replace the configured passphrase for an existing database without
completing that documented workflow.

[Back to top](#operations)

## Generating API Keys

DigitalOcean API tokens should be tightly scoped to the access required by the
automation that uses them.

The `digitalocean_inventory_api_token` value should be scoped as follows:

| Resource Type | Permissions |
| ------------- | ----------- |
| actions       | read        |
| regions       | read        |
| sizes         | read        |
| droplet       | read        |
| image         | read        |
| tag           | read        |
| snapshot      | read        |

The `digitalocean_dns_api_token` value should be scoped as follows:

| Resource Type | Permissions                  |
| ------------- | ---------------------------- |
| domain        | create, read, update, delete |

[Back to top](#operations)

## Rotating Website Deployment Secrets

Hosted-domain deployment webhook secrets are shared between GitHub repository
secrets and `vault/web.yml`.

To rotate a hosted-domain deployment webhook secret:

1. Generate a new secret:

   ```bash
   openssl rand -base64 48
   ```

2. Update `hosted_domains[].deployment.repository.webhook_secret` in
   `vault/web.yml` on the target environment branch.
3. Commit and publish the vault change.
4. Run convergence so web hosts receive the new vault value.
5. Update the hosted-domain repository secret named
   `GRAYHAVEN_DEPLOY_WEBHOOK_SECRET` to the same value.

During rotation, deployment webhooks can fail if GitHub sends a request signed
with a different value than the one currently deployed on web hosts. Rotate
during a quiet deployment window, and avoid pushing site changes until
convergence and the GitHub secret update are both complete.

The `web_deploy_fanout_secret` value is separate from hosted-domain repository
webhook secrets. It authenticates private web-to-web fanout requests between web
hosts and should be rotated through the vault followed by convergence.

[Back to top](#operations)

## Deploy Key

Automation accesses `grayhaven-vault` through a read-only GitHub deploy key.
The key is configured in GitHub for that repository and is supplied
to deployed infrastructure through
[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu).

[Back to top](#operations)
