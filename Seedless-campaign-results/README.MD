The sustained fuzzing campaign was conducted within an Oracle VirtualBox virtual machine running Ubuntu 24.04.03 LTS

VM Settings:
Virtualization software: Oracle VirtualBox
Operating System: Ubuntu 24.04.03 LTS
Allocated Processors: 4 CPU Cores
Allocated Base Memory: 8 GB RAM
Allocated Virtual Disk Memory: 60 GB

Fuzzer Configuration:
Fuzzer: AFL++ 4.09c
Number of workers: 1
Execution Timeout: 20 ms
Initial Corpus Size: 0
Dictionary: fuzzing/json.dict

Although the virtual machine was allocated four CPU cores, the campaign used only one AFL++ worker. Therefore, the remaining allocated processor capacity was not utilized by additional fuzzing instances. The campaign's reported execution count and runtime represent the work completed by this single worker.
