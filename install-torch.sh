#!/bin/bash
#
# demo job to test the pbig partition
#   job name is big hello (yeah, big job,small result as usual)
# 
#SBATCH --job-name="torch-install"
#SBATCH --output=torch-install.out
#SBATCH --error=torch-install.out
#
# run on all cores minus one of the node, require 2GB per core = 14GB
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=7
#SBATCH --mem-per-cpu=2048
#

################################################################################
# Helpers and Miscellaneous
################################################################################

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to set up Torch: $1"
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
# Local libraries
################################################################################
INSTALL_DIR="${HOME}/user"
echo "SCRIPT_OUT:Install dir is ${INSTALL_DIR}"
# INSTALL_DIR added to PATH and LD_LIBRARY_PATH in .bashrc

CMAKE_VERSION="$(cmake --version)"
if [[ "$CMAKE_VERSION" =~ '3.' ]]; then
  echo "SCRIPT_OUT:CMake Version Ok"
else
  echo "SCRIPT_OUT:Installing CMake 3.7 locally"
  wget https://cmake.org/files/v3.7/cmake-3.7.2.tar.gz
  tar -xvzf cmake-3.7.2.tar.gz
  cd cmake-3.7.2
  ./bootstrap --prefix="${INSTALL_DIR}"
  make -j4
  make check -j4
  make install
  echo "SCRIPT_OUT:CMake installed"
fi

################################################################################
# Install Torch dependencies and Torch distro
################################################################################
if [[ -d "${HOME}/torch" ]]; then
  echo "SCRIPT_OUT:Torch already installed, why are you running this script??"
else
  echo "SCRIPT_OUT:Installing torch dependencies, modified version of install-deps script in torch/"
  git clone https://github.com/torch/distro.git ~/torch --recursive
  cd ~/torch; 
  #bash install-deps;
  #Probably not needed :/
  #bash ../install-deps-local.sh "${INSTALL_DIR}"

  echo "SCRIPT_OUT:Installing torch"
  export CMAKE_LIBRARY_PATH=${INSTALL_DIR}/lib:$CMAKE_LIBRARY_PATH
  export CMAKE_INCLUDE_PATH=${INSTALL_DIR}/include:$CMAKE_INCLUDE_PATH
  export CMAKE_PREFIX_PATH=${INSTALL_DIR}:$CMAKE_PREFIX_PATH
  # install.sh has a batch-install prompt, check that
  ./install.sh
  echo "SCRIPT_OUT:Torch installed! Party!!"
fi

################################################################################
# Install Luarocks and sample packages
################################################################################
if which luarocks >/dev/null 2>&1; then
  echo "SCRIPT_OUT:Luarocks already installed"
else
  echo "SCRIPT_OUT:Installing luarocks"
  wget https://luarocks.org/releases/luarocks-2.4.1.tar.gz
  tar zxpf luarocks-2.4.1.tar.gz
  cd luarocks-2.4.1
  ./configure --prefix="${INSTALL_DIR}"
  make build -j4
  make install
  echo "SCRIPT_OUT:Luarocks installed"
fi
