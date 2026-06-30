# Setup

This document describes how to initialize `grayhaven-vault` from this example
repository.

## Table of Contents

- [Create the grayhaven-vault Repository on GitHub](#create-the-grayhaven-vault-repository-on-github)
- [Create the Local grayhaven-vault Repository on Your Workstation](#create-the-local-grayhaven-vault-repository-on-your-workstation)
- [Install the Vault Safety Hook](#install-the-vault-safety-hook)
- [Configure the Production Environment](#configure-the-production-environment)
- [Configure the Staging Environment](#configure-the-staging-environment)
- [Add GitHub Origin to Your Local Repository](#add-github-origin-to-your-local-repository)
- [Push to the GitHub Repository](#push-to-the-github-repository)
- [Add the Deployment SSH Keypair to grayhaven-vault on GitHub](#add-the-deployment-ssh-keypair-to-grayhaven-vault-on-github)
- [Set Up Hosted Domain Repositories](#set-up-hosted-domain-repositories)

## Create the grayhaven-vault Repository on GitHub

Create a new private repository named `grayhaven-vault` on GitHub. In the
private repository settings, disable optional features that are not used for
vault operations: Wiki, issues, sponsorships, discussions, projects, and pull
request features when GitHub exposes a control for them.

[Back to top](#setup)

## Create the Local grayhaven-vault Repository on Your Workstation

Use
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
as the documented starting shape for `grayhaven-vault`.

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

## Set Up Hosted Domain Repositories

Repository-backed hosted domains require a public GitHub repository with:

- a `main` branch for apex and `www` site content;
- a `dev` branch for development site content;
- all deployable files under `site/frontend/`;
- GitHub Actions enabled.

At minimum, the hosted-domain repository should include a deployment workflow
that posts the repository, branch, and commit SHA after a push to `main` or
`dev`:

```yaml
---
name: Deploy

"on":
  push:
    branches:
      - main
      - dev

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: >-
      vars.GRAYHAVEN_DEPLOY_WEBHOOK_DISABLE != 'true'

    steps:
      - name: Notify Grayhaven deployment webhook
        env:
          GRAYHAVEN_DEPLOY_WEBHOOK_SECRET: ${{ secrets.GRAYHAVEN_DEPLOY_WEBHOOK_SECRET }}
          GRAYHAVEN_DEPLOY_WEBHOOK_URL: ${{ vars.GRAYHAVEN_DEPLOY_WEBHOOK_URL }}
          GRAYHAVEN_DEPLOY_DISABLE_SSL_VERIFICATION: ${{ vars.GRAYHAVEN_DEPLOY_DISABLE_SSL_VERIFICATION }}
        run: |
          python3 - <<'PY'
          import hashlib
          import hmac
          import json
          import os
          import ssl
          import urllib.request

          webhook_url = os.environ["GRAYHAVEN_DEPLOY_WEBHOOK_URL"]
          webhook_secret = os.environ["GRAYHAVEN_DEPLOY_WEBHOOK_SECRET"]
          disable_ssl_verification = (
              os.environ.get("GRAYHAVEN_DEPLOY_DISABLE_SSL_VERIFICATION", "").lower()
              == "true"
          )
          ssl_context = ssl._create_unverified_context() if disable_ssl_verification else None
          payload = {
              "ref": os.environ["GITHUB_REF"],
              "after": os.environ["GITHUB_SHA"],
              "repository": {
                  "full_name": os.environ["GITHUB_REPOSITORY"],
                  "clone_url": f"https://github.com/{os.environ['GITHUB_REPOSITORY']}.git",
                  "html_url": f"https://github.com/{os.environ['GITHUB_REPOSITORY']}",
              },
              "sender": {
                  "login": os.environ["GITHUB_ACTOR"],
              },
          }
          body = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode()
          signature = hmac.new(webhook_secret.encode(), body, hashlib.sha256).hexdigest()
          request = urllib.request.Request(
              webhook_url,
              data=body,
              headers={
                  "Content-Type": "application/json",
                  "X-GitHub-Event": "push",
                  "X-Hub-Signature-256": f"sha256={signature}",
              },
              method="POST",
          )
          urllib.request.urlopen(request, timeout=30, context=ssl_context).read()
          PY
```

Create a repository secret named `GRAYHAVEN_DEPLOY_WEBHOOK_SECRET` with a
shared secret generated by:

```bash
openssl rand -base64 48
```

Store the same value in `vault/web.yml` as
`hosted_domains[].deployment.repository.webhook_secret`.

Create a repository variable named `GRAYHAVEN_DEPLOY_WEBHOOK_URL` with this
value:

```text
https://<apex>/.grayhaven/deploy
```

Replace `<apex>` with the hosted domain apex name, such as
`example.com`.

Create a repository variable named `GRAYHAVEN_DEPLOY_WEBHOOK_DISABLE` only when
deployment should be disabled. Set it to `true` to skip the deployment job
entirely. Leave it unset or set it to `false` for normal deployment.

Create a repository variable named `GRAYHAVEN_DEPLOY_DISABLE_SSL_VERIFICATION`
only for temporary testing against a webhook endpoint with a staging or
otherwise untrusted certificate chain. Set it to `true` to bypass TLS
certificate verification for the deployment callback. Leave it unset or set it
to `false` for normal deployment. When the hosted environment uses staging
certificates, set this variable to `true` until the environment is switched to
production certificates.

[Back to top](#setup)
