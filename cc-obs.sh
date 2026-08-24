#!/usr/bin/env bash
# Customer Club observability helper. Never bash-sources .env files.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

ENV_FILE="${ROOT}/.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  cp "${ROOT}/.env.example" "${ENV_FILE}"
  echo "Wrote ${ENV_FILE} from .env.example"
fi

env_get() {
  local key="$1"
  local default="${2:-}"
  local line
  line="$(grep -E "^${key}=" "${ENV_FILE}" | tail -n1 || true)"
  if [[ -z "${line}" ]]; then
    printf '%s' "${default}"
  else
    printf '%s' "${line#*=}"
  fi
}

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${ROOT}/docker-compose.yml")

write_empty_probes() {
  printf '[]\n' > "${ROOT}/config/blackbox-http-targets.yml"
  printf '[]\n' > "${ROOT}/config/blackbox-tcp-targets.yml"
}

write_app_probes() {
  local admin_health customer_health admin_ui customer_ui sql
  admin_health="$(env_get APP_ADMIN_HEALTH_URL http://host.docker.internal:8081/healthz)"
  customer_health="$(env_get APP_CUSTOMER_HEALTH_URL http://host.docker.internal:8082/healthz)"
  admin_ui="$(env_get APP_ADMIN_UI_URL http://host.docker.internal:3001/)"
  customer_ui="$(env_get APP_CUSTOMER_UI_URL http://host.docker.internal:3000/)"
  sql="$(env_get APP_SQL_TARGET host.docker.internal:15433)"

  cat > "${ROOT}/config/blackbox-http-targets.yml" <<EOF
- targets:
    - ${admin_health}
  labels:
    app: admin-api
- targets:
    - ${customer_health}
  labels:
    app: customer-api
- targets:
    - ${admin_ui}
  labels:
    app: admin-nginx
- targets:
    - ${customer_ui}
  labels:
    app: customer-nginx
EOF

  cat > "${ROOT}/config/blackbox-tcp-targets.yml" <<EOF
- targets:
    - ${sql}
  labels:
    app: sqlserver
EOF
}

usage() {
  cat <<'EOF'
Usage:
  ./cc-obs.sh up [--demo] [--probe-apps]
  ./cc-obs.sh down
  ./cc-obs.sh ps
  ./cc-obs.sh smoke
  ./cc-obs.sh logs [service]

  --demo         synthetic OTLP (traces/metrics/logs) into the collector
  --probe-apps   blackbox Customer Club local-dev ports on this laptop
EOF
}

cmd="${1:-}"
shift || true

DEMO=0
PROBE_APPS=0
for arg in "$@"; do
  case "${arg}" in
    --demo) DEMO=1 ;;
    --probe-apps) PROBE_APPS=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown flag: ${arg}" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "${cmd}" in
  up)
    if [[ "${PROBE_APPS}" -eq 1 ]]; then
      write_app_probes
      echo "Blackbox will probe Customer Club local-dev ports."
    else
      write_empty_probes
    fi
    profiles=()
    if [[ "${DEMO}" -eq 1 ]]; then
      profiles+=(--profile demo)
    fi
    "${COMPOSE[@]}" "${profiles[@]}" up -d
    echo
    echo "Grafana:      http://127.0.0.1:$(env_get GRAFANA_PORT 3300)  (admin / admin)"
    echo "Prometheus:   http://127.0.0.1:$(env_get PROMETHEUS_PORT 9090)"
    echo "Alertmanager: http://127.0.0.1:$(env_get ALERTMANAGER_PORT 9093)"
    echo "OTLP HTTP:    http://127.0.0.1:$(env_get OTLP_HTTP_PORT 4318)"
    echo "OTLP gRPC:    127.0.0.1:$(env_get OTLP_GRPC_PORT 4317)"
    ;;
  down)
    "${COMPOSE[@]}" --profile demo down
    write_empty_probes
    ;;
  ps)
    "${COMPOSE[@]}" --profile demo ps
    ;;
  smoke)
    grafana="http://127.0.0.1:$(env_get GRAFANA_PORT 3300)/api/health"
    prom="http://127.0.0.1:$(env_get PROMETHEUS_PORT 9090)/-/ready"
    loki="http://127.0.0.1:$(env_get LOKI_PORT 3100)/ready"
    tempo="http://127.0.0.1:$(env_get TEMPO_PORT 3200)/ready"
    metrics="http://127.0.0.1:$(env_get COLLECTOR_PROM_PORT 9464)/metrics"
    fail=0
    check() {
      local url="$1"
      local tries=12
      local i
      for ((i = 1; i <= tries; i++)); do
        if curl -fsS --max-time 5 "${url}" >/dev/null; then
          echo "OK  ${url}"
          return 0
        fi
        sleep 2
      done
      echo "FAIL ${url}" >&2
      return 1
    }
    check "${grafana}" || fail=1
    check "${prom}" || fail=1
    check "${loki}" || fail=1
    check "${tempo}" || fail=1
    check "${metrics}" || fail=1
    exit "${fail}"
    ;;
  logs)
    "${COMPOSE[@]}" logs -f --tail=100
    ;;
  -h|--help|"")
    usage
    ;;
  *)
    echo "Unknown command: ${cmd}" >&2
    usage >&2
    exit 1
    ;;
esac
