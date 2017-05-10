#!/usr/bin/env bash
# Experimental script to set up dispnet, with its own custom Caffe, in a
# users's HOME directory with no need for root access.
# Tailored specifically towards Euryale, so assumes *some* basic dependencies,
# such as CUDA and cudnn are available as modules.

set -u
set -o pipefail
# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${SCRIPT_DIR}/util.sh.inc"

export SLURM_JOB_ID=2194
printf >&2 "\n\n\t\n" "!!! Using hardcoded SLURM_JOB_ID=$SLURM_JOB_ID. Be careful!"

################################################################################
# Basic Setup
################################################################################

echo "Setting up Caffe prerequisites for the local user (experimental support)..."

# Load appropriate modules.
# If executing remotely, make sure you source the appropriate system-level
# configs in order to expose the 'module' command.
source setup-modules.sh.inc
echo "Relevant modules loaded OK."

# This is the directory where we will be downloading and building stuff.
WORKDIR=~/work

echo "Will be using ${WORKDIR} as a work directory for fetching and building libraries."

mkdir -p "$WORKDIR"
# TODO(andrei): Support installing crap in some subfolder of home, such as
# ~/foo/{bin,lib,include,man,...}.
# Make sure this 'bin' is on your PATH, and 'lib' on your LD_LIBRARY_PATH.
mkdir -p ~/bin
mkdir -p ~/lib
mkdir -p ~/include
mkdir -p ~/man

source "${SCRIPT_DIR}/setup-conda.sh.inc"


################################################################################
# Setup mdb
################################################################################

# I think this may still be needed even if we install everything else with
# conda.
# TODO(andrei): Put this in a separate script.

if ! [[ -f "${HOME}/bin/mdb_copy" ]]; then
  cd "${WORKDIR}"
  if ! [[ -d mdb ]]; then
    git clone https://gitorious.org/mdb/mdb.git
  fi

  cd mdb/libraries/liblmdb
  # Ensures the right prefix is used. You know, because configuring shit using
  # commandline arguments is for suckers, RIGHT?
  # Yep, the quirky quoting is necessary.
  sed -i 's|prefix\s*=\s*/usr/local|prefix = '"${HOME}"'|g' Makefile || fail "Sed fail"
  make            || fail "Could not build mdb."
  make install    || fail "Could not install mdb."
fi


################################################################################
# Setup Caffe itself
################################################################################

printf "\n\t%s\n" "Dependencies set up OK. Building flownet+Caffe itself."
printf "\t%s\n\n" "This will take a while."

cd "${WORKDIR}"
if ! [[ -d 'dispflownet-release' ]]; then
  # TODO(andrei): WGET stuff.
  fail "No public git avail. Need to wget here instead."
fi

cd "${WORKDIR}/dispflownet-release"

# Next, we build the MTN project's custom Caffe.
GOOD_MAKEFILE_CONFIG="${SCRIPT_DIR}/Makefile.config"
cp "${GOOD_MAKEFILE_CONFIG}" Makefile.config

# Ensure 'libhdf5_hl.so.10' and its friends can be found.
export LD_LIBRARY_PATH="${HOME}/miniconda/envs/mnc/lib:${LD_LIBRARY_PATH}"

# Ensure Caffe uses the right CUDA installation.
sed -i 's|^CUDA_DIR\s*:=\s.*|CUDA_DIR := '"${MODULE_CUDA_DIR}"'|' Makefile.config

# TODO(andrei): Remove arch 60, 61 lines if using CUDA 7.5, and if actually
# present in the file.

printf "\n\t%s\n\n" "Starting main Caffe build."

# Mini hack to get OpenCV work even though it expects CUDA 7.5. Caffe itself
# will use CUDA 8, but OpenCV won't complain either.
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/site/opt/cuda/7.0.28/x64/lib64"
run_gpu make all -j8      || fail "Could not build caffe."
run_gpu make test -j8     || fail "Could not build caffe tests."
run_gpu make tools -j8    || fail "Could not build caffe tools"
# Feel free to disable the tests if you're in a hurry, but they can still be
# very usueful in figuring out if there's something that's misconfigured.
#run_gpu make runtest      || fail "Caffe tests failed."

printf "\n\t%s\n\nBuild OK."


cd models/DispNet
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/site/opt/cuda/7.5.18/x64/lib64"
run_gpu ./demo.py imgL_list.txt imgR_list.txt


#printf "\n\t%s\n\nFetching trained MNC model..."
#cd ${WORKDIR}/MNC
#if ! [[ -f "./data/mnc_model/mnc_model.caffemodel.h5" ]]; then
  #./data/scripts/fetch_mnc_model.sh || fail "Could not download pretrained model."
#else
  #echo "Model was already downloaded."
#fi

#printf "\n\t%s\n" "Finished setting up the Multi-Task Network Cascate (MNC) project (with its custom Caffe)!"
