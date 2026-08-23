#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${1:-}"
EXPECTED_SHA="${2:-}"
EXPECTED_ORIGIN="${HYPERSPACE_REVIEWED_REMOTING_ALLOWED_ORIGIN:-https://github.com/WhiteLighterIO/quickdesk-remoting.git}"

if [[ -z "${SOURCE}" || -z "${EXPECTED_SHA}" ]]; then
  echo "usage: prepare-reviewed-remoting-source.sh <local-source-checkout> <expected-commit-sha>" >&2
  exit 64
fi

SOURCE="$(cd "${SOURCE}" 2>/dev/null && pwd)" || {
  echo "HYPERSPACE_REVIEWED_REMOTING_SOURCE_MISSING:${SOURCE}" >&2
  exit 20
}

[[ -d "${SOURCE}/.git" ]] || {
  echo "HYPERSPACE_REVIEWED_REMOTING_SOURCE_NOT_GIT:${SOURCE}" >&2
  exit 21
}

ACTUAL_SHA="$(git -C "${SOURCE}" rev-parse HEAD)"
[[ "${ACTUAL_SHA}" == "${EXPECTED_SHA}" ]] || {
  echo "HYPERSPACE_REVIEWED_REMOTING_SOURCE_SHA_MISMATCH expected=${EXPECTED_SHA} actual=${ACTUAL_SHA}" >&2
  exit 22
}

if [[ -n "$(git -C "${SOURCE}" status --porcelain)" ]]; then
  echo "HYPERSPACE_REVIEWED_REMOTING_SOURCE_DIRTY:${SOURCE}" >&2
  exit 23
fi

ORIGIN="$(git -C "${SOURCE}" remote get-url origin 2>/dev/null || true)"
[[ -n "${ORIGIN}" ]] || {
  echo "HYPERSPACE_REVIEWED_REMOTING_SOURCE_ORIGIN_MISSING:${SOURCE}" >&2
  exit 24
}

normalize_origin() {
  local value="$1"
  value="${value%.git}"
  value="${value#git@github.com:}"
  value="${value#ssh://git@github.com/}"
  value="${value#https://github.com/}"
  value="${value#http://github.com/}"
  printf '%s' "${value,,}"
}

ACTUAL_ORIGIN_NORM="$(normalize_origin "${ORIGIN}")"
EXPECTED_ORIGIN_NORM="$(normalize_origin "${EXPECTED_ORIGIN}")"
[[ "${ACTUAL_ORIGIN_NORM}" == "${EXPECTED_ORIGIN_NORM}" ]] || {
  echo "HYPERSPACE_REVIEWED_REMOTING_SOURCE_ORIGIN_REFUSED expected=${EXPECTED_ORIGIN} actual=${ORIGIN}" >&2
  echo "Production remoting source must remain under the explicitly approved WhiteLighterIO-controlled origin." >&2
  exit 25
}

python3 "${ROOT}/verify-remoting-source.py" "${SOURCE}"

cat <<EOF
HYPERSPACE_REVIEWED_REMOTING_SOURCE_OK
source=${SOURCE}
commit=${ACTUAL_SHA}
origin=${ORIGIN}
authorizationAuthority=hyperspace
export HYPERSPACE_QUICKDESK_REMOTING_SOURCE='${SOURCE}'
EOF
