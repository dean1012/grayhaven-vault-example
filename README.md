# Grayhaven Systems LLC Vault (Example)

This repository documents the expected shape of `grayhaven-vault` as used by
Grayhaven Systems LLC infrastructure automation.

The Grayhaven Systems LLC infrastructure repositories are public for
transparency and operational demonstration. They show how Grayhaven Systems LLC
manages its own infrastructure, but they do not store client infrastructure,
client credentials, private deployment data, private SSH keys, secrets, or
operational state.

This example repository intentionally contains fake plaintext sample data. It
should not be used operationally without configuration and appropriate
encryption.

## Table of Contents

- [Repository Purpose](#repository-purpose)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Repository Purpose

`grayhaven-vault` separates private operational data from public automation
code while preserving a documented interface between these repositories:

- [`grayhaven-infra-opentofu`](https://github.com/dean1012/grayhaven-infra-opentofu)
- [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)

This repository is not a general-purpose deployment template. Deploying similar
automation for another organization requires review and adaptation.

[Back to top](#grayhaven-systems-llc-vault-example)

## Documentation

- [Setup](docs/setup.md)
- [Vault Architecture](docs/vault-architecture.md)
- [File Schema](docs/schema.md)
- [Grafana Cloud Setup](docs/grafana-cloud-setup.md)
- [Operations](docs/operations.md)

[Back to top](#grayhaven-systems-llc-vault-example)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation commands and contribution
guidelines.

[Back to top](#grayhaven-systems-llc-vault-example)

## License

[MIT](LICENSE)

[Back to top](#grayhaven-systems-llc-vault-example)
