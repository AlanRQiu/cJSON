#!/usr/bin/env bash
# Build the Trial 4 targets from the library sources in this repository (or $1).
#   build/fuzz_parse build/fuzz_utils build/fuzz_utils_alias   libFuzzer + ASan + UBSan
#       (fuzz_utils compiles out the known MergePatch aliasing calls; fuzz_utils_alias runs them)
#   build/cov_parse build/cov_utils                           libFuzzer driver + llvm source coverage, no sanitizers
# Env: CC (default clang-18), BUILD_DIR (default trial4/build)
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; root="$(cd -- "$here/.." && pwd)"
src="$(cd -- "${1:-$root}" && pwd)"; out="${BUILD_DIR:-$here/build}"; CC="${CC:-clang-18}"; mkdir -p "$out"
SAN="-fsanitize=fuzzer,address,undefined -fno-sanitize-recover=undefined"; OPT="-g -O1 -fno-omit-frame-pointer"
COV="-fsanitize=fuzzer -fprofile-instr-generate -fcoverage-mapping -g -O0"
$CC $OPT $SAN -I"$src" "$here/harness/fuzz_parse.c" "$src/cJSON.c" -o "$out/fuzz_parse"
$CC $OPT $SAN -I"$src" -DNAN_SKIP_MERGE_ALIAS=1 "$here/harness/fuzz_utils.c" "$src/cJSON.c" "$src/cJSON_Utils.c" -o "$out/fuzz_utils"
$CC $OPT $SAN -I"$src" "$here/harness/fuzz_utils.c" "$src/cJSON.c" "$src/cJSON_Utils.c" -o "$out/fuzz_utils_alias"
$CC $COV -I"$src" "$here/harness/fuzz_parse.c" "$src/cJSON.c" -o "$out/cov_parse"
$CC $COV -I"$src" -DNAN_SKIP_MERGE_ALIAS=1 "$here/harness/fuzz_utils.c" "$src/cJSON.c" "$src/cJSON_Utils.c" -o "$out/cov_utils"
echo "built in $out with $($CC --version | head -n1); library source: $src"
