#! /bin/bash

out_allow_file="/var/lib/vyhole/allow.lua"
out_deny_file="/var/lib/vyhole/deny.lua"

config="${1}"

if [[ -z "${config}" ]]; then
  echo "no configuration file"
  exit 1
fi

function load_file_plain() {
  source="${1}"
  output="${2}"

  sed 's/#.*$//;/^$/d' <"${source}" >>"${output}"
}

function load_file_hosts() {
  source="${1}"
  output="${2}"

  sed 's/#.*$// ; /^$/d ; s/^127.0.0.1\ \(.*\)/\1/g ; s/^0.0.0.0\ \(.*\)/\1/g' <"${source}" >>"${output}"
}

function load_file_dnsmasq() {
  source="${1}"
  output="${2}"

  sed -E 's/#.*$// ; /^$/d ; s%^[a-zA-Z-]*=/([^/]*)/?%\1%g' <"${source}" >>"${output}"
}

function load_from_file() {
  format="${1}"
  source="${2}"
  output="${3}"

  echo "load ${format}: ${source} into ${output}"

  case "${format}" in
  dnsmasq)
    load_file_dnsmasq "${source}" "${output}"
    ;;
  hosts)
    load_file_hosts "${source}" "${output}"
    ;;
  plain)
    load_file_plain "${source}" "${output}"
    ;;
  *)
    echo "unknown blocklist type ${blocklist_type}"
    exit 1
    ;;
  esac
}

function load_from_network() {
  format="${1}"
  source="${2}"
  output="${3}"

  tmpfile="$(mktemp)"

  echo "fetch ${source}"

  if ! curl --no-progress-meter --fail -L -o ${tmpfile} "${source}"; then exit 1; fi

  load_from_file "${format}" "${tmpfile}" "${output}"
}

function add_from_source() {
  format="${1}"
  source="${2}"
  output="${3}"

  if [[ "${source}" =~ ^(https?|s?ftp|tftp):\/\/.*$ ]]; then
    load_from_network "${format}" "${source}" "${output}"
  else
    load_from_file "${format}" "${source}" "${output}"
  fi

}

while read line; do
  [[ "${line}" =~ ^\s*$ ]] && continue

  if [[ "${line}" =~ ^\#.*$ ]]; then
    continue
  fi

  if [[ "${line}" =~ ^allow_out* ]]; then
    out_allow_file="$(cut -d' ' -f2 <<<"${line}")"
    continue
  fi

  if [[ "${line}" =~ ^deny_out* ]]; then
    out_deny_file="$(cut -d' ' -f2 <<<"${line}")"
    continue
  fi

  config_entries+=("${line}")
done <"${config}"

deny_master_list="$(mktemp)"
allow_master_list="$(mktemp)"

for config_entry in "${config_entries[@]}"; do
  kind="$(cut -d' ' -f1 <<<"${config_entry}")"
  format="$(cut -d' ' -f2 <<<"${config_entry}")"
  source="$(cut -d' ' -f3 <<<"${config_entry}")"

  if [[ "${kind}" = "allow" ]]; then
    add_from_source "${format}" "${source}" "${allow_master_list}"
  else
    add_from_source "${format}" "${source}" "${deny_master_list}"
  fi
done

echo "sort and format"

echo "return {" >"${out_allow_file}"
echo "return {" >"${out_deny_file}"

sort -u <"${allow_master_list}" | awk '{printf "  \"%s\",\n", $1}' >>"${out_allow_file}"
sort -u <"${deny_master_list}" | awk '{printf "  \"%s\",\n", $1}' >>"${out_deny_file}"

echo "}" >>"${out_allow_file}"
echo "}" >>"${out_deny_file}"
