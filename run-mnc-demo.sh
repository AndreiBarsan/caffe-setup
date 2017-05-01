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

CUDA_VERSION="8.0.44"
WORKDIR=~/work

module load cuda/"${CUDA_VERSION}"  || fail 'Could not load CUDA module.'
module load opencv/3.1.0            || fail 'Could not load OpenCV module (v3.1.0)'
module load boost/1.62.0            || fail 'Could not load boost module (v1.62.0).'
module load mpich                   || fail 'Could not load mpi module.'

if ! which conda >/dev/null 2>&1; then
  # Ensure conda is on the PATH.
  export PATH="${HOME}/miniconda/bin:${PATH}"
fi

source activate mnc

echo "Setup OK. srun-ing MNC demo..."

cd ${WORKDIR}/MNC
run_gpu tools/demo.py
