#!/usr/bin/env bash
# Utility for running the MNC demo on ETHZ's Euryale mini-cluster.
# Useful as a sanity check, after installing everything using 'setup-mnc.sh'.

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to set up Caffe: $1"
  exit $LAST_ERR
}

function run_gpu {
  srun -N 1 --gres=gpu:1 "$@"
}

# Enable module support.
source /etc/profile

CUDA_VERSION="8.0.27"   # 8.0.44 causes weird Qt conflicts.
WORKDIR=~/work

module load cuda/"${CUDA_VERSION}"  || fail 'Could not load CUDA module.'
module load cudnn/v5.1              || fail 'Could not load CUDNN module (v4).'
module load opencv/3.1.0            || fail 'Could not load OpenCV module (v3.1.0)'
module load boost/1.62.0            || fail 'Could not load boost module (v1.62.0).'
module load mpich                   || fail 'Could not load mpi module.'

if ! which conda >/dev/null 2>&1; then
  # Ensure conda is on the PATH.
  export PATH="${HOME}/miniconda/bin:${PATH}"
fi

source activate mnc
# Mini hack to get OpenCV work even though it expects CUDA 7.5. Caffe itself
# will use CUDA 8, but OpenCV won't complain either.
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/site/opt/cuda/7.5.18/x64/lib64"
echo "Setup OK. srun-ing MNC demo..."

echo "MAJOR HACK: REMOVE THIS IN THE FUTURE!!! Manually setting SLURM_JOB_ID."
export SLURM_JOB_ID=1927

cd ${WORKDIR}/MNC
run_gpu tools/demo.py "$@"
