#!/usr/bin/env bash
# Utility for running the MNC demo on ETHZ's Euryale mini-cluster as a Slurm
# batch job.
#
#SBATCH --job-name="mnc-inference"
#SBATCH --output="mnc-inference-%6j.log"
#
# Note: could use 'plongx' if we want longer jobs and have the privileges to do
# so.
#SBATCH --partition=pdefault
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --gres=gpu:1


function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to set up Caffe: $1"
  exit $LAST_ERR
}

tstamp="`date '+%D %T'`"
hn="`hostname -f`"
jobid=${SLURM_JOB_ID}
jobname=${SLURM_JOB_NAME}
if [ -z "${jobid}" ] ; then
  echo "ERROR: SLURM_JOBID undefined, are you running this script directly ?"
    exit 1
fi

printf "%s: starting %s(%s) on host %s\n" "${tstamp}" "${jobname}" "${jobid}" "${hn}"
echo "**"
echo "** SLURM_CLUSTER_NAME="$SLURM_CLUSTER_NAME
echo "** SLURM_JOB_NAME="$SLURM_JOB_NAME
echo "** SLURM_JOB_ID="$SLURM_JOBID
echo "** SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "** SLURM_NUM_NODES"=$SLURM_NUM_NODES
echo "** SLURMTMPDIR="$SLURMTMPDIR
echo "** working directory = "$SLURM_SUBMIT_DIR
echo
echo "Setting up modules and miniconda..."

# TODO(andrei): Common config with CUDA/cuDNN/openCV versions.
CUDA_VERSION="8.0.27"
WORKDIR=~/work

module load cuda/"${CUDA_VERSION}"  || fail 'Could not load CUDA module.'
module load cudnn/v4                || fail 'Could not load CUDNN module (v4).'
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

cd ${WORKDIR}/MNC

dt="`date '+%s'`"
# This is where the magic happens.
srun tools/demo.py "$@" 2>&1
stat="$?"
dt=$(( `date '+%s'` - ${dt} ))
echo "Job finished. Status=$stat, duration=$dt second(s)."

