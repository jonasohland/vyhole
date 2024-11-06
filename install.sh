#! /bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

set -e

function try_move_id() {
    id_type="${1}"

    id_file="/home/vyos/.ssh/id_${id_type}"
    id_file_pub="/home/vyos/.ssh/id_${id_type}.pub"

    if [[ -f "${id_file}" ]] && ! test -L "${id_file}"; then
        mv -v "${id_file}" "/config/vyos/ssh/id_${id_type}"
    fi

    if [[ -f "${id_file_pub}" ]] && ! test -L "${id_file_pub}"; then
        mv -v "${id_file_pub}" "/config/vyos/ssh/id_${id_type}.pub"
    fi
}

mkdir -p /config/vyos/ssh

try_move_id rsa
try_move_id ecdsa
try_move_id ed25519

if [[ -f "/home/vyos/.ssh/known_hosts" ]] && ! test -L "/home/vyos/.ssh/known_hosts"; then
    mv -v "/home/vyos/.ssh/known_hosts" "/config/vyos/ssh/known_hosts"
fi

if [[ -f "/home/vyos/.gitconfig" ]] && ! test -L "/home/vyos/.gitconfig"; then
    mv -v "/home/vyos/.gitconfig" "/home/vyos/gitconfig"
fi

mkdir -p /config/scripts/commit/post-hooks.d

sudo cp -fv "${SCRIPT_DIR}/10-pdns-adblock-install" /config/scripts/commit/post-hooks.d/
sudo cp -fv "${SCRIPT_DIR}/vyos-postconfig-bootup.script" /config/scripts/

if [[ -f "/config/vyos/ssh/known_hosts" ]]; then
    ln -svf "/config/vyos/ssh/known_hosts" "/home/vyos/.ssh/known_hosts"
fi

mkdir -p out

if [[ ! -f "${SCRIPT_DIR}/config.txt" ]]; then
    echo "allow_out /config/vyhole/out/allow.lua" >>"${SCRIPT_DIR}/config.txt"
    echo "deny_out /config/vyhole/out/deny.lua" >>"${SCRIPT_DIR}/config.txt"

    mkdir -p /config/vyhole/out
fi

"${SCRIPT_DIR}/update.sh" "${SCRIPT_DIR}/config.txt"

/config/scripts/commit/vyos-postconfig-bootup.script
/config/scripts/commit/post-hooks.d/10-pdns-adblock-install
