# Grafana Cloud Setup

This document describes the manually configured Grafana Cloud objects expected
by Grayhaven Systems LLC observability automation. File formats are documented
in [File Schema](schema.md).

## Table of Contents

- [Stack](#stack)
- [Collector Token](#collector-token)
- [Grafana IRM Contact Point](#grafana-irm-contact-point)
- [Notification Policy](#notification-policy)
- [Grafana IRM Routing](#grafana-irm-routing)
- [Alert Rule API Token](#alert-rule-api-token)
- [Vault Values](#vault-values)

## Stack

Create a Grafana Cloud stack in the region closest to the production
infrastructure. The stack URL is stored as `grafana_cloud.stack_url` in
`vault/common.yml`.

Create a folder named `Grayhaven Systems LLC`. Ansible-managed alert rules are
stored in this folder.

[Back to top](#grafana-cloud-setup)

## Collector Token

Create a Grafana Cloud token for Alloy metric and log shipping. Store the token
as `grafana_cloud.alloy_api_key` in `vault/common.yml`.

Record these values from the Grafana Cloud collector setup flow:

- Prometheus remote-write URL;
- Prometheus username;
- Prometheus datasource name;
- Loki push URL;
- Loki username.

Place the values under `grafana_cloud.prometheus` and `grafana_cloud.loki` in
`vault/common.yml`.

[Back to top](#grafana-cloud-setup)

## Grafana IRM Contact Point

Create a Grafana-managed contact point named `Grafana IRM` and connect it to a
Grafana IRM integration. The matching integration should route alerts into the
production escalation chain.

Outgoing Discord webhooks, mobile push behavior, SMS behavior, and phone-call
behavior are configured in Grafana Cloud. Keep those templates short enough for
mobile notifications and make sure they include the host or domain, check
summary, and check value when available.

[Back to top](#grafana-cloud-setup)

## Notification Policy

Configure the Grafana notification policy for managed alert rules to route to
the `Grafana IRM` contact point.

Use these grouping labels:

```text
alertname
environment
host
domain
```

This keeps normal metric and service alerts separated by host while allowing
Grafana-generated no-data alerts to group together sensibly.

[Back to top](#grafana-cloud-setup)

## Grafana IRM Routing

Configure the Grafana IRM integration with the production escalation chain. The
integration should send the initial alert promptly and then escalate through
the notification methods chosen for the on-call operator.

The exact on-call schedule and escalation path are Grafana Cloud operational
configuration, not repository state.

[Back to top](#grafana-cloud-setup)

## Alert Rule API Token

Create a Grafana Cloud API token for Ansible-managed alert rules and initial
convergence silences. Store the token as `grafana_cloud.alerting.api_token` in
`vault/common.yml`.

The token needs these scopes:

| Scope |
| ----- |
| Alerting:Write via Provisioning API |
| Alerting:Silences Writer |
| Data sources:Reader |
| Folders:Reader |

Ansible only manages alert rules labeled `configured_by=ansible`. Manual alert
rules should not use that label.

[Back to top](#grafana-cloud-setup)

## Vault Values

Enable Grafana Cloud in `config.yml` only for production:

```yaml
observability:
  grafana_cloud:
    enabled: true
    logs_enabled: true
```

Place the Grafana Cloud credential and endpoint values in `vault/common.yml`:

```yaml
grafana_cloud:
  stack_url: "https://example.grafana.net"
  alloy_api_key: "glc_example_alloy_token"
  prometheus:
    remote_write_url: "https://prometheus-prod-example.grafana.net/api/prom/push"
    username: "123456"
    datasource_name: "grafanacloud-example-prom"
  loki:
    push_url: "https://logs-prod-example.grafana.net/loki/api/v1/push"
    username: "654321"
  alerting:
    api_token: "glsa_example_alerting_token"
    folder: Grayhaven Systems LLC
    evaluation_group: grayhaven-production-1m
    evaluation_interval: 1m
    contact_point: Grafana IRM
```

If `logs_enabled` is false, the Loki values are not used.

[Back to top](#grafana-cloud-setup)
