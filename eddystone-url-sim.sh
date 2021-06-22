#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-t]

Simulation Raspberry Pi beacon / BLE advertisement

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-t, --time      Cooldown time, default 10
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  ./advertise-url -s
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  TIME=10

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -t | --time) # example named parameter
      TIME="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  return 0
}

parse_params "$@"
setup_colors

CURRENT_STATE="inuse"
USER_INPUT="foo"

# init cooldown timer
COOLDOWN_TIME=$(($(date +%s) + $TIME))


# advertising states / URLs

set_state_ready() {
  CURRENT_STATE="ready"
  msg "${GREEN}ready${NOFORMAT}"
  ./advertise-url -u http://p3d.net/1/ready
}

set_state_inuse() {
  CURRENT_STATE="inuse"
  msg "${ORANGE}inuse${NOFORMAT}"
  ./advertise-url -u http://p3d.net/1/inuse
}

set_state_error() {
  CURRENT_STATE="error"
  msg "${RED}error${NOFORMAT}"
  ./advertise-url -u http://p3d.net/1/error
}


# event listener

process_event() {
  case "$CURRENT_STATE" in
  ready)
    COOLDOWN_TIME=$(($(date +%s) + $TIME))
    set_state_inuse
    ;;
  inuse | error)
    COOLDOWN_TIME=$(($(date +%s) + $TIME))
    set_state_error
    ;;
  esac
}


# set advertising mode on bluetooth device

sudo hciconfig hci0 noleadv || sudo hciconfig hci0 leadv 3

msg "${CYAN}Press [x] to exit, any other letter to trigger event${NOFORMAT}"

# On start -> inuse
set_state_inuse

while [[ "${USER_INPUT}" != "x" ]] ; do
  read -t .1 -n 1 -s USER_INPUT || true
  # at cooldown time back to ready state
  if [ $COOLDOWN_TIME -lt $(date +%s) ] && [ $CURRENT_STATE != "ready" ]; then
    set_state_ready
  fi
  if [[ "${USER_INPUT}" != "" ]] ; then
    process_event
  fi

done
