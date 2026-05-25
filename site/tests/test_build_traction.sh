#!/usr/bin/env bash
# Tests for build-traction.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_SCRIPT="${SCRIPT_DIR}/build-traction.sh"

fail() { echo "FAIL: $1"; exit 1; }
pass() { echo "PASS: $1"; }

FIXTURE_DIR="$(mktemp -d)"
trap "rm -rf ${FIXTURE_DIR}" EXIT
cat > "${FIXTURE_DIR}/index.html" <<'EOF'
<!doctype html>
<html><body>
<span>tests: {{TOTAL_TESTS}} ({{PY}} + {{RUST}})</span>
<span>installs: {{PYPI_INSTALLS}}</span>
</body></html>
EOF

[[ -x "${BUILD_SCRIPT}" ]] || fail "build-traction.sh must exist and be executable"
pass "script exists and is executable"

"${BUILD_SCRIPT}" --input "${FIXTURE_DIR}/index.html" --output "${FIXTURE_DIR}/out.html" \
  --py-tests 160 --rust-tests 57 --pypi-installs 802 >/dev/null 2>&1 \
  || fail "script with explicit args should exit 0"
pass "script with explicit args exits 0"

OUTPUT="$(cat "${FIXTURE_DIR}/out.html")"
echo "${OUTPUT}" | grep -q "{{" && fail "output still contains unresolved template tokens"
pass "no unresolved template tokens in output"

echo "${OUTPUT}" | grep -q "tests: 217 (160 + 57)" || fail "total tests should be 217"
pass "TOTAL_TESTS computed and substituted correctly"

echo "${OUTPUT}" | grep -q "installs: 802" || fail "pypi installs should be 802"
pass "PYPI_INSTALLS substituted correctly"

cp /dev/null "${FIXTURE_DIR}/empty.html"
if "${BUILD_SCRIPT}" --input "${FIXTURE_DIR}/empty.html" --output "${FIXTURE_DIR}/empty-out.html" \
   --py-tests 1 --rust-tests 1 --pypi-installs 1 >/dev/null 2>&1; then
  fail "script should fail when input has no template tokens to resolve"
fi
pass "script fails when no tokens present in input"

echo
echo "All tests passed."
