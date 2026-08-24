# Customer Club — Observability (standalone)

This repo is **not** the backend or frontend. It is the Grafana LGTM + OpenTelemetry platform for Customer Club.

Do not put this compose into `customer-club-api` or `customer-club`. Those apps stay unchanged until you later add an OTLP exporter. Until then this stack runs alone on a laptop.

```
~/Desktop/
  novintech_data/bank_deploy/customer-club-api     # .NET — untouched
  novintech_data/bank_deploy/customer-club         # Vue — untouched
  customer-club-observability                      # this repo
```

**Docs**

- Architecture + inventory: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- C4 container diagram (PDF): [docs/customer-club-observability-containers.pdf](docs/customer-club-observability-containers.pdf)
- Diagram HTML source: [docs/container-diagram.html](docs/container-diagram.html)

## What LGTM means here

| Letter | In this repo | Notes |
|--------|----------------|--------|
| **L** | Loki | Logs |
| **G** | Grafana | UI on **:3300** (not 3000 — that is customer-nginx) |
| **T** | Tempo | Traces |
| **M** | Prometheus | Grafana’s scaled-out M is **Mimir**. Not used on this laptop. |

The OpenTelemetry Collector sits in front. Apps never send to Loki, Tempo, or Grafana directly.

## Components in this Compose project

| Component | Status | Role | Laptop port |
|-----------|--------|------|-------------|
| Loki | Has | Log store | 3100 |
| Grafana | Has | UI, Explore, one stack-health dashboard | 3300 |
| Tempo | Has | Trace store + span-metrics | 3200 |
| Prometheus | Has | Metrics (stands in for Mimir) | 9090 |
| otel-collector | Has | OTLP intake, PII filter, routing | 4317 / 4318 / 9464 |
| Alertmanager | Has | Alert routing UI — no bank webhook yet | 9093 |
| blackbox-exporter | Has | HTTP/TCP probes of the apps | internal |
| node-exporter | Has | Host CPU / disk / memory | internal |
| cAdvisor | Has | Container metrics | internal |
| telemetrygen ×3 | Has (`--demo`) | Synthetic traces / metrics / logs | — |

Grafana is `http://127.0.0.1:3300` — user `admin` / password `admin` (change in `.env`).

## Intentionally not in this repo

| Component | Why |
|-----------|-----|
| Mimir | Multi-cluster metrics. Prometheus is enough for Compose. |
| Distributed Tempo / Loki | Single-binary is the laptop and first prod shape. |
| Pyroscope | CPU profiling — later, not required for LGTM. |
| Grafana Alloy | Chose CNCF `otel-collector-contrib` instead. |
| Seq / Elasticsearch | Replaced by Loki + OTLP. |
| .NET / Vue instrumentation | Lives in `customer-club-api` / `customer-club`. |

## Target architecture, not built in this compose yet

| Component | Notes |
|-----------|--------|
| sql-exporter | SQL wait stats, deadlocks, index DMVs |
| Edge collector (second agent) | Laptop uses one collector; prod Edge needs a forwarder |
| nginx log scrape + `/otel/` RUM path | App deploy / nginx |
| RED dashboards for customer-api / login / nginx | Only `grafana/dashboards/stack-health.json` exists |
| Real alert channels | Email / SMS / bank SOAR |
| Grafana OnCall | Alertmanager UI only |

## Laptop quick start

```bash
cd ~/Desktop/customer-club-observability
chmod +x cc-obs.sh
./cc-obs.sh up --demo
./cc-obs.sh smoke
```

`--demo` sends fake traces, metrics, and logs so Grafana is not empty before the APIs are instrumented.

Then:

1. Grafana → **Explore** → Tempo → Search service `customer-api-demo`
2. Dashboards → folder **Customer Club** → **Observability stack health**
3. Alertmanager `http://127.0.0.1:9093` — platform-down rules are live; app probes stay silent until `--probe-apps`

```bash
./cc-obs.sh down
```

Regenerate the PDF after diagram HTML edits:

```bash
chmod +x docs/render-container-pdf.sh
./docs/render-container-pdf.sh
```

## Optional: probe the real Customer Club on this laptop

If `customer-club-api` local-dev is already up (ports 3000, 3001, 8081, 8082, 15433):

```bash
./cc-obs.sh up --demo --probe-apps
```

Blackbox then hits `/healthz` and SQL TCP. If those containers are **not** running, P0 alerts fire — that is expected. This still does not modify the app repos.

## Later: connect the real APIs (app repos)

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4318
```

That line belongs in `customer-club-api` / frontend RUM, not here.

## Production (bank) later

Same images and config shape:

- Edge host: a second collector (agent) that only forwards OTLP
- Trust host: this compose (gateway + LGTM)
- Grafana / Loki / Tempo / Prometheus never published to the WAF

Laptop is a single-host version of that (one collector = both agent and gateway).

## Files

| Path | Purpose |
|------|---------|
| `docker-compose.yml` | All platform containers |
| `config/otel-collector.yml` | Receive OTLP → Tempo / Loki / Prometheus |
| `config/prometheus-alerts.yml` | First P0/P1 rules |
| `grafana/provisioning/` | Datasources + dashboard auto-load |
| `docs/ARCHITECTURE.md` | C4 description + inventory |
| `docs/customer-club-observability-containers.pdf` | Printable container diagram |
| `cc-obs.sh` | `up` / `down` / `smoke` — does not `source` `.env` |
