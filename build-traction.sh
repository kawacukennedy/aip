#!/usr/bin/env bash
# Templates live traction numbers into a copy of index.html.
# Reads:  --input (source HTML with {{...}} tokens)
# Writes: --output (templated HTML, all tokens resolved or script fails)
# Numbers come from --py-tests, --rust-tests, --pypi-installs flags. Caller
# is responsible for actually computing those (see build-traction-auto.sh).
set -euo pipefail

INPUT=""
OUTPUT=""
PY_TESTS=""
RUST_TESTS=""
PYPI_INSTALLS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)         INPUT="$2"; shift 2 ;;
    --output)        OUTPUT="$2"; shift 2 ;;
    --py-tests)      PY_TESTS="$2"; shift 2 ;;
    --rust-tests)    RUST_TESTS="$2"; shift 2 ;;
    --pypi-installs) PYPI_INSTALLS="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

[[ -n "${INPUT}" ]]         || { echo "--input is required" >&2; exit 2; }
[[ -n "${OUTPUT}" ]]        || { echo "--output is required" >&2; exit 2; }
[[ -n "${PY_TESTS}" ]]      || { echo "--py-tests is required" >&2; exit 2; }
[[ -n "${RUST_TESTS}" ]]    || { echo "--rust-tests is required" >&2; exit 2; }
[[ -n "${PYPI_INSTALLS}" ]] || { echo "--pypi-installs is required" >&2; exit 2; }

[[ -f "${INPUT}" && -s "${INPUT}" ]] || { echo "input is empty or missing: ${INPUT}" >&2; exit 1; }
grep -q "{{" "${INPUT}" || { echo "input has no template tokens to resolve: ${INPUT}" >&2; exit 1; }

TOTAL_TESTS=$(( PY_TESTS + RUST_TESTS ))

sed \
  -e "s|{{TOTAL_TESTS}}|${TOTAL_TESTS}|g" \
  -e "s|{{PY}}|${PY_TESTS}|g" \
  -e "s|{{RUST}}|${RUST_TESTS}|g" \
  -e "s|{{PYPI_INSTALLS}}|${PYPI_INSTALLS}|g" \
  "${INPUT}" > "${OUTPUT}"

if grep -q "{{" "${OUTPUT}"; then
  echo "ERROR: unresolved template tokens remain in output" >&2
  grep -n "{{" "${OUTPUT}" >&2
  rm -f "${OUTPUT}"
  exit 1
fi

echo "Wrote ${OUTPUT}: TOTAL_TESTS=${TOTAL_TESTS} PYPI_INSTALLS=${PYPI_INSTALLS}"
