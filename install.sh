#! /bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

set -e

mkdir -p /config/scripts/commit/post-hooks.d
cp -v "${SCRIPT_DIR}/10-pdns-adblock-install" /config/scripts/commit/post-hooks.d/

mkdir -p out

if [[ ! -f "${SCRIPT_DIR}/config.txt" ]]; then
  echo "allow_out /config/vyhole/out/allow.lua" >>"${SCRIPT_DIR}/config.txt"
  echo "deny_out /config/vyhole/out/deny.lua" >>"${SCRIPT_DIR}/config.txt"

  mkdir -p /config/vyhole/out
fi

"${SCRIPT_DIR}/update.sh" "${SCRIPT_DIR}/config.txt"

/config/scripts/commit/post-hooks.d/10-pdns-adblock-install
