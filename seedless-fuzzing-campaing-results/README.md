The contents within this folder contain the sustained campaign on an Oracle VirtualBox Ubuntu 24.04.03 LTS 

VirtualBox Settings:
- Processors: 4
- Base Memory: 8 GB
- Storage: 60 GB

Fuzzer Settings:
- Fuzzer: AFL++ 4.09c
- Workers: 1
- Execution timeout: 20ms
- Initial Corpus Size: 0
- Dictionary: fuzzing/json.dict

*Note: Although 4 CPU Cores were available, the AFL++ fuzzer only used one processor. The results contained in this folder are the result of one AFL++ worker.*
