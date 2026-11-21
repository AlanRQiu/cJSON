# CPTS 428: cJSON Harness

## Prerequisites: 
Ubuntu/Debian Linux (or WSL), Bash, Clang with AddressSanitizer
and UndefinedBehaviorSanitizer runtimes, Git, and coreutils. No Docker, Make,
or external C libraries are required.

## How To Set Up Environment

```bash
sudo apt-get update
sudo apt-get install -y clang libclang-rt-dev git
git clone https://github.com/AlanRQiu/cJSON.git
cd cJSON
chmod +x build.sh && ./build.sh
chmod +x run.sh && ./run.sh
```

### Expected build output:

```text
Build successful: bin/cjson_harness
```

### Expected default run output (10-byte seed, no trailing newline):

```text
Executions: 1, Bytes processed: 10, Parse successes: 1
```

### Custom file or raw stdin:

```bash
./run.sh path/to/input.json
printf '%s' '{"seed":1}' | ./bin/cjson_harness
```

**Important: `./run.sh path/to/input.json` is not the execution of an active fuzzing campaign.

`./run.sh` executes the harness against the specified `path/to/input.json`**

## Current Harness Limitations

The C99 harness calls `cJSON_ParseWithLengthOpts(buffer, length, NULL, 0)`
without appending a NUL. Buffers grow dynamically up to 16 MiB; empty inputs
are tested, and oversized inputs or I/O/allocation failures exit nonzero.
Rejected JSON is a completed execution, not a crash. Trailing data is allowed
by the selected API options. Successful trees are freed with `cJSON_Delete`.
Sanitizer failures stop execution; a crash may prevent printing metrics.

The cJSON sources are vendored at baseline commit
`6d9f2443ab071f86e5d9b43025a40929ec41c46c` (version 1.7.19), with no fetched
build dependencies. Compiler flags are fixed in the build script; the host
Clang version is not pinned. Record `clang --version` with experiment results.
The submission must include these harness files in the remote repository;
for an immutable reproduction, check out the submitted commit after cloning.

### Fuzzing Campaign Results

No fuzzing campaign has been carried out as of yet. 

However, the absence of any crash reports means that our methodology for fuzzing did not find any vulnerabilities. It ***does not*** mean there aren't any vulnerablilities. 