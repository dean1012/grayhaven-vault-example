# Setup

This document describes how to initialize a private `grayhaven-vault`
repository from this example repository.

## Table of Contents

- [Set Up the Vault Repository](#set-up-the-vault-repository)

## Set Up the Vault Repository

Create a new private repository named `grayhaven-vault` on GitHub. In the
private repository settings, disable optional features that are not used for
vault operations: Wiki, issues, sponsorships, discussions, projects, and pull
request features when GitHub exposes a control for them.

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

Install the provided pre-commit hook before the first commit. This hook rejects
commits when required vault files are missing or staged without Ansible Vault
encryption.

```bash
mkdir -p .githooks
cp ../grayhaven-infra-opentofu/templates/vault/pre-commit .githooks/pre-commit
chmod 0755 .githooks/pre-commit
git config core.hooksPath .githooks
```

Edit `config.yml`, `firewall.yml`, and the files under `vault/` for production
and staging as shown below. File formats are documented in detail in the
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
repository.

Configure production first so the initial commit creates the `main` branch:

```bash
git branch -M main
```

Edit `config.yml`, `firewall.yml`, and the files under `vault/` using the
generated production values from above where applicable.

Encrypt the `vault/*.yml` files with the production Ansible Vault passphrase
generated above, then commit and push `main` to the new private GitHub
repository.

```bash
yamllint .
ansible-vault encrypt vault/*.yml
git add .
git commit -S -m "Initialize production vault data"
git remote add origin git@github.com:dean1012/grayhaven-vault.git
git push -u origin main
```

Create the staging branch from the initialized main branch, then decrypt the
copied production vault files with the production Ansible Vault passphrase:

```bash
git switch -c staging
ansible-vault decrypt vault/*.yml
```

Edit `config.yml`, `firewall.yml`, and the files under `vault/` using the
generated staging values from above where applicable.

Encrypt the `vault/*.yml` files with the staging Ansible Vault passphrase
generated above, then commit and push `staging` to the new private GitHub
repository.

```bash
yamllint .
ansible-vault encrypt vault/*.yml
git add .
git commit -S -m "Initialize staging vault data"
git push -u origin staging
```

Add the deploy public key generated earlier as a read-only deploy key on the
`grayhaven-vault` repository through GitHub's website.

[Back to top](#setup)
