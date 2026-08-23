#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${ROOT}/linux/hyperspace/host-bootstrap.cpp"
OUT_DIR="${HYPERSPACE_LINUX_OUT:-${ROOT}/output/linux-hyperspace}"
BIN="${OUT_DIR}/hyperspace-linux-host-bootstrap"
CXX="${CXX:-c++}"

command -v "${CXX}" >/dev/null 2>&1 || { echo "C++ compiler not found: ${CXX}" >&2; exit 10; }
mkdir -p "${OUT_DIR}"
"${CXX}" -std=c++17 -O2 -Wall -Wextra -Werror "${SRC}" -o "${BIN}"
[[ -x "${BIN}" ]] || { echo "bootstrap binary missing: ${BIN}" >&2; exit 11; }
echo "built ${BIN}"
