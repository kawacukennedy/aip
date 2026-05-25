#!/usr/bin/env bash
# Auto mode: computes numbers from the live repo + PyPI and templates index.html.
# Output goes to _build/index.html that gh-pages picks up. Source index.html
# stays unmodified with template tokens intact.
set -euo pipefail

SITE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SITE_DIR}/.." && pwd)"
BUILD_DIR="${SITE_DIR}/_build"
mkdir -p "${BUILD_DIR}"

echo "Counting Python tests..."
PY_TESTS=$(cd "${REPO_DIR}/python" && python -m pytest --collect-only -q 2>/dev/null | tail -1 | awk '{print $1}')
[[ -n "${PY_TESTS}" && "${PY_TESTS}" =~ ^[0-9]+$ ]] || { echo "could not collect Python tests" >&2; exit 1; }
echo "  ${PY_TESTS}"

echo "Counting Rust tests..."
RUST_TESTS=$(cd "${REPO_DIR}/rust" && cargo test 2>&1 | grep -E "^test result:" | awk '{s+=$4} END {print s}')
[[ -n "${RUST_TESTS}" && "${RUST_TESTS}" =~ ^[0-9]+$ ]] || { echo "could not count Rust tests (got: ${RUST_TESTS})" >&2; exit 1; }
echo "  ${RUST_TESTS}"

echo "Fetching PyPI installs..."
A_JSON=$(curl -sL "https://pypistats.org/api/packages/agent-identity-protocol/recent")
[[ -n "${A_JSON}" ]] || { echo "pypistats fetch failed for agent-identity-protocol" >&2; exit 1; }
A=$(echo "${A_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['last_month'])")
sleep 2
B_JSON=$(curl -sL "https://pypistats.org/api/packages/aip-agents/recent")
[[ -n "${B_JSON}" ]] || { echo "pypistats fetch failed for aip-agents" >&2; exit 1; }
B=$(echo "${B_JSON}" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['last_month'])")
PYPI_INSTALLS=$(( A + B ))
echo "  ${PYPI_INSTALLS} (${A} + ${B})"

echo "Templating..."
"${SITE_DIR}/build-traction.sh" \
  --input "${SITE_DIR}/index.html" \
  --output "${BUILD_DIR}/index.html" \
  --py-tests "${PY_TESTS}" \
  --rust-tests "${RUST_TESTS}" \
  --pypi-installs "${PYPI_INSTALLS}"

echo "Built ${BUILD_DIR}/index.html"
