#!/usr/bin/env bash
# Build the reproducers against the library in <src_dir> (default: repository root), with and without ASan, and record the output.
# usage: bash trial4/findings/run_poc.sh [src_dir] [out_file]
set -uo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"; root="$(cd -- "$here/../.." && pwd)"
src="$(cd -- "${1:-$root}" && pwd)"; out="${2:-$here/poc_results.txt}"; CC="${CC:-clang-18}"; tmp="$(mktemp -d)"
{
  echo "# $(date -u +%FT%TZ)  $($CC --version | head -n1)  library: $src"
  for kind in plain asan; do
    flags="-O2 -g"; [[ $kind == asan ]] && flags="-O0 -g -fsanitize=address,undefined"
    $CC $flags -I"$src" "$here/poc_merge_alias.c" "$src/cJSON.c" "$src/cJSON_Utils.c" -o "$tmp/poc_$kind" || exit 1
    for v in 1 2 3 4 5; do
      echo "== $kind variant $v"; timeout 10 "$tmp/poc_$kind" $v 2>&1 | grep -E "SUMMARY|ERROR|result|runtime error" | head -3; echo "exit=${PIPESTATUS[0]}"
    done
    echo "== $kind variant 1, case-sensitive API"; timeout 10 "$tmp/poc_$kind" 1 cs 2>&1 | grep -E "SUMMARY|ERROR|result" | head -2; echo "exit=${PIPESTATUS[0]}"
  done
} > "$out" 2>&1
cat "$out"; rm -rf "$tmp"
