#!/bin/bash
#
# Batch script to install tensorflow 
# 
#SBATCH --job-name="tf-install"
#SBATCH --output=tf-install.out
#SBATCH --error=tf-install.out
#
# run on all cores minus one of the node, require 2GB per core = 14GB
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=7
#SBATCH --mem-per-cpu=2048
#SBATCH --gres=gpu:1

################################################################################
# Helpers and Miscellaneous
################################################################################

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to set up Tensorflow: $1"
  exit $LAST_ERR
}

# Uses a proper machine and not the login node to run stuff.
# If SLURM is not present, simply replace the 'srun -N 1' part with 'eval'.
function run {
  srun "$@"
}

function run_gpu {
  srun --gres=gpu:1 "$@"
}

################################################################################
# Printing Info
################################################################################
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

################################################################################
# Basic Setup
################################################################################
echo "SCRIPT_OUT:loading modules:"

# Load appropriate modules.
# If executing remotely, make sure you source the appropriate system-level configs
# in order to expose the 'module' command.

# Brotip: The Euryale Titan X cards are the Pascal version. CUDA 7.5 does NOT
# support them!
CUDA_VERSION="8.0.44"
# CUDA_VERSION="7.5.18"

MODULE_CUDA_DIR="/site/opt/cuda/${CUDA_VERSION}/x64"
module load cuda/"${CUDA_VERSION}"  || fail 'Could not load CUDA module.'
# As of May 2017, Caffe (or at least the version used with MTN) does NOT
# support cuDNN 5 or higher, and cuDNN 4 leads to errors, so it's disabled.
module load cudnn/v5.1              || fail 'Could not load cuDNN module.'
#module load opencv/3.1.0            || fail 'Could not load OpenCV module (v3.1.0)'
# Fun fact: Boost 1.60 had a bug preventing it from being used to compile Caffe.
module load boost/1.62.0            || fail 'Could not load boost module (v1.62.0).'
module load mpich                   || fail 'Could not load mpi module.'
module load openmpi                 || fail 'Could not load openmpi.'

# added to remove /usr/lib/x86_64-linux-gnu/libgomp.so.1: version `GOMP_4.0' not found (required by /home/shekhars/torch/install/lib/libTH.so.0) on -llibtorch
# default load is gcc 4.9, but we need the same version as libgomp.so.1 
module unload gcc                   || fail 'Could not load gcc'
# module load gcc                   || fail 'Could not load gcc'

echo "SCRIPT_OUT:Relevant modules loaded OK."

################################################################################
# Miniconda and related packages
################################################################################

INSTALL_DIR="/import/euryale/projects/shekhars"

if ! [[ -d "${INSTALL_DIR}/miniconda" ]]; then
  echo "Setting up miniconda in" $INSTALL_DIR
  cd "$(mktemp -d)"
  wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
  run_gpu bash miniconda.sh -b -p "${INSTALL_DIR}/miniconda" || fail 'Could not install anaconda'
  ln -s $INSTALL_DIR/miniconda $HOME/miniconda
  export PATH="${HOME}/miniconda/bin:${PATH}"
  conda create -y --quiet --name tensorflow python=3.4
else
  echo "Miniconda seems to already be installed."
fi

if ! which conda >/dev/null 2>&1; then
  # Ensure conda is on the PATH.
  export PATH="${HOME}/miniconda/bin:${PATH}"
fi

source activate tensorflow

PIP_VERSION="$(which pip)"
if [[ "$PIP_VERSION" =~ 'miniconda' ]]; then
  echo "SCRIPT_OUT:pip is from anaconda"
  run_gpu pip install --ignore-installed --upgrade \
    https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.1.0-cp34-cp34m-linux_x86_64.whl || fail 'conda could not install tensorflow'
else
  echo "SCRIPT_OUT:pip not from anaconda, aborting"
  fail 'pip not from anaconda, check path and stuff'
fi

run_gpu python3 -c 'import tensorflow as tf' || fail 'Could not import tensorflow, cry '
