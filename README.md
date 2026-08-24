# Observability platform (Loki · Grafana · Tempo · Prometheus + OpenTelemetry)

Self-hosted observability stack for a multi-container app (API + SPA + nginx).
Runs on Docker Compose. Apps send telemetry with OTLP; they never talk to
Loki/Tempo/Grafana directly.

```bash
cp .env.example .env
make up-demo
make smoke
```

Then open Grafana at [http://127.0.0.1:3300](http://127.0.0.1:3300)
(`admin` / `admin`). Explore → Tempo → service `customer-api-demo`.

## What’s included

| Piece | Role | Host port |
|-------|------|-----------|
| otel-collector | OTLP intake (`4317` gRPC / `4318` HTTP) | 4317, 4318, 9464 |
| Loki | Logs | 3100 |
| Tempo | Traces | 3200 |
| Prometheus | Metrics + alert rules | 9090 |
| Grafana | UI | **3300** |
| Alertmanager | Alert routing | 9093 |
| blackbox-exporter | HTTP/TCP probes (optional) | — |
| node-exporter + cAdvisor | Host / container metrics | — |

`M` in LGTM is **Prometheus** here. Mimir is the multi-tenant option; overkill
for a single Compose host.

## Layout

```
.
├── docker-compose.yml
├── cc-obs.sh / Makefile
├── .env.example
├── config/                 # collector, prometheus, loki, tempo, alerts
├── grafana/                # datasources + dashboards
└── docs/                   # architecture + container diagram
```

## Commands

| Command | What it does |
|---------|----------------|
| `make up` | Platform only |
| `make up-demo` | + synthetic traces/metrics/logs |
| `make up-probe` | + blackbox against local app ports |
| `make smoke` | Health checks |
| `make down` | Stop everything |
| `make docs-pdf` | Rebuild the PDF diagram |

## Wiring an application later

Point the app at the collector (not at Grafana):

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4318
```

Optional probes (`make up-probe`) expect health endpoints on the usual local
ports (`8081`/`8082` for APIs, `3000`/`3001` for gateways, SQL on `15433`).
If those processes are down, probe alerts fire — that is expected.

## Production sketch

Same images, split by zone:

- **Edge** — reverse proxy + SPA + a forwarding collector
- **Trust** — APIs + this LGTM stack (gateway collector + storage + Grafana)
- Do not expose Grafana / Loki / Tempo / Prometheus through a public WAF

Details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ·
[docs/customer-club-observability-containers.pdf](docs/customer-club-observability-containers.pdf)

## Not in v0.1 (on purpose)

- Mimir / distributed Loki-Tempo
- Application SDKs (.NET / Vue) — those live in the app repos
- sql-exporter, RUM `/otel/` path, email/SMS alert channels

See [CHANGELOG.md](CHANGELOG.md) and [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
