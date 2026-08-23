#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${1:-}"
EXPECTED_SHA="${2:-}"

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

python3 "${ROOT}/verify-remoting-source.py" "${SOURCE}"

ORIGIN="$(git -C "${SOURCE}" remote get-url origin 2>/dev/null || true)"

cat <<EOF
HYPERSPACE_REVIEWED_REMOTING_SOURCE_OK
source=${SOURCE}
commit=${ACTUAL_SHA}
origin=${ORIGIN:-unknown}
authorizationAuthority=hyperspace
export HYPERSPACE_QUICKDESK_REMOTING_SOURCE='${SOURCE}'
EOF
