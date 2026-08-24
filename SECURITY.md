# Security

## Reporting

If you find a security issue in this stack (misconfiguration, exposed ports,
PII leaking into telemetry), open a private report via GitHub Security Advisories
on this repository, or email the maintainer listed on the GitHub profile.

Do not open a public issue for secrets, credentials, or production host details.

## Scope

This project ships **example** credentials for local Grafana (`admin` / `admin`
in `.env.example`). Change them before any shared or production use.

The OpenTelemetry Collector config strips common sensitive attribute keys
(`otp`, `password`, `access_token`, `national_id`). Extend that list for your
domain before pointing real applications at the collector.

## Production notes

- Do not publish Grafana, Loki, Tempo, Prometheus, or collector ports on an
  internet-facing host.
- Prefer a private network / PAM jump host for operator access.
- Keep real `.env` files and TLS private keys out of git (see `.gitignore`).
