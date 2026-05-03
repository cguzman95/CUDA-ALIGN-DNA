#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --partition=cuda-ext.q
#SBATCH --gres=gpu:GeForceRTX3080:1
#SBATCH -o out.txt
#SBATCH -e err.txt

set -e
module load nvhpc/21.2
compile(){
  mkdir -p build
  nvcc -g -O2 -Wno-deprecated-gpu-targets main.cu -o build/main
}
compile

build/main AGGTAB GXTXAYB # 4
build/main ACTG ACTGA # 1

# Profiling:
#nsys nvprof --print-gpu-trace build/exec #summary, recommended to run like "run.sh > profiling.txt"

# Detailed Profiling:
#ncu --target-processes application-only --set full -f -o profile.ncu-rep build/exec

# 1. Manually download file "profile.ncu-rep" to your computer
# 2. Download the "Nsys" profiler from the Nvidia website on your computer (https://developer.nvidia.com/nsight-systems).
# 3. Use "ncu" from your computer to open "profile.ncu-rep"
#nsys profile -f true -t nvtx,cuda -o profile.nsys-rep ./exec
# Download "profile.nsys-rep.qdrep" on your computer and use nsys to open the file.

# Profile traces with nsys:
# nsys profile -f true -t nvtx,cuda -o profile.nsys-rep ./main 100 100
# Download "profile.nsys-rep.qdrep" on your computer and use nsys to open the file.