# Setup

This document describes how to initialize a private `grayhaven-vault`
repository from this example repository.

## Table of Contents

- [Create the Private grayhaven-vault Repository on GitHub](#create-the-private-grayhaven-vault-repository-on-github)
- [Create the Local grayhaven-vault Repository on Your Workstation](#create-the-local-grayhaven-vault-repository-on-your-workstation)
- [Install the Vault Safety Hook](#install-the-vault-safety-hook)
- [Configure the Production Environment](#configure-the-production-environment)
- [Configure the Staging Environment](#configure-the-staging-environment)
- [Add GitHub Origin to Your Local Repository](#add-github-origin-to-your-local-repository)
- [Push to the GitHub Repository](#push-to-the-github-repository)
- [Add the Deployment SSH Keypair to grayhaven-vault on GitHub](#add-the-deployment-ssh-keypair-to-grayhaven-vault-on-github)

## Create the Private grayhaven-vault Repository on GitHub

Create a new private repository named `grayhaven-vault` on GitHub. In the
private repository settings, disable optional features that are not used for
vault operations: Wiki, issues, sponsorships, discussions, projects, and pull
request features when GitHub exposes a control for them.

[Back to top](#setup)

## Create the Local grayhaven-vault Repository on Your Workstation

Use
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
as the documented starting shape for the private vault repository.

Example setup flow:

```bash
git clone git@github.com:dean1012/grayhaven-vault-example.git grayhaven-vault
cd grayhaven-vault
```

Remove the `.git` directory so the new private repository does not retain the
example repository history, then initialize a fresh repository:

```bash
git init
```

[Back to top](#setup)

## Install the Vault Safety Hook

Install the provided pre-commit hook before the first commit. This hook rejects
commits when required vault files are missing or staged without Ansible Vault
encryption.

```bash
mkdir -p .githooks
cp templates/pre-commit .githooks/pre-commit
chmod 0755 .githooks/pre-commit
git config core.hooksPath .githooks
```

[Back to top](#setup)

## Configure the Production Environment

Edit `config.yml`, `firewall.yml`, and the files under `vault/` for production
using the production values generated during the
[setup process](https://github.com/dean1012/grayhaven-infra-opentofu/blob/main/docs/setup.md)
in the
[`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
repository where applicable.

File formats are documented in [File Schema](schema.md).

Configure production first so the initial commit creates the `main` branch:

```bash
git branch -M main
```

Encrypt the `vault/*.yml` files with the production Ansible Vault passphrase
generated during infrastructure setup, then commit `main`.

```bash
yamllint .
ansible-vault encrypt vault/*.yml
git add .
git commit -S -m "Initialize production vault data"
```

[Back to top](#setup)

## Configure the Staging Environment

Create the staging branch from the initialized main branch, then decrypt the
copied production vault files with the production Ansible Vault passphrase:

```bash
git switch -c staging
ansible-vault decrypt vault/*.yml
```

Edit `config.yml`, `firewall.yml`, and the files under `vault/` using the
staging values generated during infrastructure setup where applicable.

Encrypt the `vault/*.yml` files with the staging Ansible Vault passphrase
generated during infrastructure setup, then commit `staging`.

```bash
yamllint .
ansible-vault encrypt vault/*.yml
git add .
git commit -S -m "Initialize staging vault data"
```

[Back to top](#setup)

## Add GitHub Origin to Your Local Repository

Add the new private GitHub repository as the local repository origin:

```bash
git remote add origin git@github.com:dean1012/grayhaven-vault.git
```

[Back to top](#setup)

## Push to the GitHub Repository

Push both initialized environment branches:

```bash
git push -u origin main
git push -u origin staging
```

[Back to top](#setup)

## Add the Deployment SSH Keypair to grayhaven-vault on GitHub

Add the deployment public key generated during infrastructure setup as a
read-only deploy key on the `grayhaven-vault` repository through GitHub's
website.

[Back to top](#setup)
