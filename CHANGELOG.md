# Changelog

All notable changes to this project are documented here.

## [0.1.0] — 2026-08-24

### Added

- Docker Compose stack: OpenTelemetry Collector, Loki, Tempo, Prometheus,
  Grafana, Alertmanager, blackbox-exporter, node-exporter, cAdvisor
- `cc-obs.sh` / `Makefile` helpers (`up`, `up-demo`, `probe-apps`, `smoke`, `down`)
- Starter Prometheus alert rules and one Grafana stack-health dashboard
- Architecture notes and C4 container diagram under `docs/`
