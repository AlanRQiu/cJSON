#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
command -v clang >/dev/null 2>&1 || {
    printf '%s\n' 'Error: clang is required.' >&2
    exit 1
}
mkdir -p bin
clang -std=c99 -Wall -Wextra -pedantic -g -O1 \
    -fsanitize=address,undefined -fno-sanitize-recover=all \
    -fno-omit-frame-pointer cJSON.c harness/harness.c -lm -o bin/cjson_harness
printf '%s\n' 'Build successful: bin/cjson_harness'