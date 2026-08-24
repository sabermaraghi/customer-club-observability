#!/usr/bin/env bash
# Render docs/container-diagram.html to PDF via Chrome (no extra npm).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML="${ROOT}/docs/container-diagram.html"
PDF="${ROOT}/docs/customer-club-observability-containers.pdf"
CHROME="${CHROME:-$(command -v google-chrome-stable || command -v google-chrome || command -v chromium)}"
if [[ -z "${CHROME}" ]]; then
  echo "Chrome/Chromium not found." >&2
  exit 1
fi
"${CHROME}" --headless --disable-gpu --no-sandbox --no-pdf-header-footer \
  --print-to-pdf="${PDF}" "file://${HTML}"
echo "Wrote ${PDF}"
