#!/usr/bin/env bash
set -euo pipefail
input=''
if (( $# > 1 )); then
    printf 'Usage: %s [input-file]\n' "$0" >&2
    exit 1
fi
if (( $# == 1 )); then
    input="$(realpath -- "$1")"
fi
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
if [[ ! -x bin/cjson_harness ]]; then
    bash ./build.sh
fi
if (( $# == 0 )); then
    input="$(mktemp)"
    trap 'rm -f -- "$input"' EXIT
    printf '%s' '{"seed":1}' > "$input"
fi
export ASAN_OPTIONS=detect_leaks=1:halt_on_error=1
export UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1
result="$(./bin/cjson_harness "$input")"
if [[ ! "$result" =~ ^Executions:\ 1,\ Bytes\ processed:\ [0-9]+,\ Parse\ successes:\ [01]$ ]]; then
    printf '%s\n' 'Error: unexpected harness metrics.' >&2
    exit 1
fi
printf '%s\n' "$result"