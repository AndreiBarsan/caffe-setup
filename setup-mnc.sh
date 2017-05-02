#!/usr/bin/env bash
# Experimental script to set up Multi-Task Network Cascades (with their own
# Caffe in a users's HOME directory).
# Tailored specifically towards Euryale, so assumes *some* basic dependencies,
# such as CUDA and cudnn are available as modules.
#
# Loosely based on the guide from:
# https://autchen.github.io/guides/2015/04/03/caffe-install.html


################################################################################
# Helpers and Miscellaneous
################################################################################

function fail {
  LAST_ERR="$?"
  echo >&2 "Failed to set up Caffe: $1"
  exit $LAST_ERR
}

# Uses a proper machine and not the login node to build stuff.
# If SLURM is not present, simply replace the 'srun -N 1' part with 'eval'.
function run {
  srun -N 1 "$@"
  # TODO(andrei): Test everything with slurm once there's a free machine.
  #eval "$@"
}

function run_gpu {
  srun -N 1 --gres=gpu:1 "$@"
}

# Directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


################################################################################
# Basic Setup
################################################################################

echo "Setting up MNC Caffe for the local user (experimental support)..."

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
#module load cudnn/v5.1              || fail 'Could not load cuDNN module.'
module load opencv/3.1.0            || fail 'Could not load OpenCV module (v3.1.0)'
# Fun fact: Boost 1.60 had a bug preventing it from being used to compile Caffe.
module load boost/1.62.0            || fail 'Could not load boost module (v1.62.0).'
module load mpich                   || fail 'Could not load mpi module.'

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


################################################################################
# Miniconda and related packages
################################################################################

# TODO(andrei): Install in scratch folder and create symlink in HOME.
if ! [[ -d "${HOME}/miniconda" ]]; then
  echo "Setting up miniconda..."
  cd "$(mktemp -d)"
  wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
  bash miniconda.sh -b -p "${HOME}/miniconda"
  export PATH="${HOME}/miniconda/bin:${PATH}"
  conda create -y --quiet --name mnc python=2.7
else
  echo "Miniconda seems to already be installed."
fi

if ! which conda >/dev/null 2>&1; then
  # Ensure conda is on the PATH.
  export PATH="${HOME}/miniconda/bin:${PATH}"
fi

source activate mnc

echo "Running most commands on node:"
run hostname

# Python dependencies for caffe-mnc. Note that they are roughly based on the
# requirements in 'MNC/caffe-mnc/python/requirements.txt', but are installed
# via Conda for consistency.
run conda install -y --quiet Cython numpy scipy scikit-image matplotlib h5py \
  leveldb networkx nose pandas protobuf python-gflags Pillow six \
  python-dateutil pyyaml hdf5 h5py
# Little guys not available via Conda.
yes | pip install easydict opencv-python

# Note: Caffe compilation is after this giant commented-out block!

################################################################################
# Setup ATLAS with LAPACK
################################################################################

# This may not be necessary on Euryale, provided that the readily-available
# ATLAS version is good enough.

# ATLAS_FNAME="atlas3.10.0.tar.bz2"
# LAPACK_FNAME="lapack-3.4.2.tgz"
#
# if ! [[ -f "$LAPACK_FNAME" ]]; then
#   echo "Downloading lapack: ${LAPACK_FNAME}..."
#  wget -O "$LAPACK_FNAME" http://www.netlib.org/lapack/lapack-3.4.2.tgz
#fi
#
#if ! [[ -f "$ATLAS_FNAME" ]]; then
#  echo "Downloading ATLAS: $ATLAS_FNAME..."
#  wget -O "$ATLAS_FNAME" https://downloads.sourceforge.net/project/math-atlas/Stable/3.10.0/atlas3.10.0.tar.bz2
#  echo "Download complete."
#else
#  echo "ATLAS already present. Not downloading."
#fi
#
#if ! [[ -d "ATLAS" ]]; then
#  echo "Untaring ATLAS."
#  tar jxvf "$ATLAS_FNAME" 1>/dev/null || fail "Could not unpack ATLAS."
#fi

# cd ATLAS
# rm -rf build_obj && mkdir -p build_obj && cd build_obj

#run ../configure -b 64 -Fa alg -fPIC --shared --prefix=$(pwd) --with-netlib-lapack-tarfile=../../${LAPACK_FNAME} || fail "Could not configure ATLAS."
#run make -j8	    || fail "Could not build ATLAS."
#run make check -j8  || fail "ATLAS tests failed."
#run make time       || fail "ATLAS 'make time' failed."
#run make install    || fail "Could not install ATLAS."

# Note: the next dependencies which are commented-out may still be necessary if
# you get errors when installing them with conda. Doing the "manual" install
# can solve many problems.

################################################################################
# Setup Protobuf
################################################################################

#if ! [[ -f "${HOME}/bin/protoc" ]]; then
  #cd ${WORKDIR}
  #if ! [[ -d protobuf ]]; then
    #git clone https://github.com/google/protobuf.git
  #fi

  #cd protobuf/
  #run ./autogen.sh                        || fail "protobuf autogen failed"
  #run ./configure --prefix="${HOME}"      || fail "protobuf configure failed"
  #run make -j4                            || fail "protobuf make failed"
  #run make install                        || fail "protobuf install failed"

  ## TODO(andrei): May need to also adjust the C++ include path for this to work
  ## properly when building Caffe.
#else
  #echo "Found ~/bin/protoc. Not installing protobuf."
#fi


################################################################################
# Setup gflags
################################################################################

#if ! [[ -f "${HOME}/lib/libgflags.a" ]]; then
  #cd ${WORKDIR}
  #if ! [[ -d gflags ]]; then
    #git clone https://github.com/gflags/gflags.git
  #fi

  #cd gflags
  #mkdir build
  #cd build
  #run cmake -DCMAKE_INSTALL_PREFIX:PATH=${HOME} -DCMAKE_CXX_FLAGS:STRING=-fPIC .. || fail "Could not configure gflags"
  #run make         || fail "Could not build gflags"
  #run make install || fail "Could not install glags"
#else
  #echo "Found local gflags installation. Not installing gflags."
#fi


################################################################################
# Setup LevelDB
################################################################################

#if ! [[ -f "${HOME}/lib/libleveldb.so" ]]; then
  #cd ${WORKDIR}
  #if ! [[ -d leveldb ]]; then
    #git clone https://github.com/google/leveldb.git
  #fi
  #cd leveldb/
  #make
  #cp --preserve=links out-static/libleveldb.* "${HOME}/lib"
  #cp --preserve=links out-shared/libleveldb.* "${HOME}/lib"
  #cp -r include/leveldb "${HOME}/include"
#else
  #echo "Found local leveldb installation. Not installing leveldb."
#fi


################################################################################
# Setup Snappy
################################################################################

#if ! [[ -f "${HOME}/lib/libsnappy.so" ]]; then
  #cd ${WORKDIR}
  #if ! [[ -d snappy ]]; then
    #git clone https://github.com/google/snappy.git
  #fi
  #cd snappy/
  #./autogen.sh
  #./configure --prefix=${HOME}
  #run make          || fail "Could not build Snappy."
  ## This WILL fail with some bullshit reason about not being to install the
  ## docs due to a file with some wrong name, but we don't care.
  #run make install  #|| fail "Could not install Snappy."
#else
  #echo "Found local Snappy installation. Not installing Snappy."
#fi


################################################################################
# Setup mdb
################################################################################

# I think this may still be needed even if we install everything else with
# conda.

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

printf "\n\t%s\n" "Dependencies set up OK. Building MNC+Caffe itself."
printf "\t%s\n\n" "This will take a while."

cd "${WORKDIR}"
if ! [[ -d 'MNC' ]]; then
  git clone --recursive https://github.com/AndreiBarsan/MNC
fi

cd MNC/lib && make || fail "Could not make Cython modules for the MNC project."

# Next, we build the MTN project's custom Caffe.
cd ../caffe-mnc
GOOD_MAKEFILE_CONFIG="${SCRIPT_DIR}/Makefile.config"
cp "${GOOD_MAKEFILE_CONFIG}" Makefile.config
# YES this is a thing we must do so that the remaining tests actually BUILD.
rm -f src/caffe/test/test_smooth_L1_loss_layer.cpp

# Ensure 'libhdf5_hl.so.10' and its friends can be found.
export LD_LIBRARY_PATH="${HOME}/miniconda/envs/mnc/lib:${LD_LIBRARY_PATH}"

# TODO(andrei): Remove if no longer necessary (due to using the 'known-good'
# makefile.
# Ensure Caffe knows about our locally installed components.
# sed -i '/^INCLUDE_DIRS\s*:=/ s|$| '"${HOME}"'/include|g' Makefile.config
# sed -i '/^LIBRARY_DIRS\s*:=/ s|$| '"${HOME}"'/lib|g' Makefile.config

# Ensure Caffe uses the right CUDA installation.
sed -i 's|^CUDA_DIR\s*:=\s.*|CUDA_DIR := '"${MODULE_CUDA_DIR}"'|' Makefile.config

# TODO(andrei): Remove arch 60, 61 lines if using CUDA 7.5, and if actually
# present in the file.

printf "\n\t%s\n\n" "Starting main Caffe build."

# Mini hack to get OpenCV work even though it expects CUDA 7.5. Caffe itself
# will use CUDA 8, but OpenCV won't complain either.
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/site/opt/cuda/7.5.18/x64/lib64"
run_gpu make all -j8      || fail "Could not build caffe."
run_gpu make pycaffe -j8  || fail "Could not build pycaffe."
run_gpu make test -j8     || fail "Could not build caffe tests."
# Feel free to disable the tests if you're in a hurry, but they can still be
# very usueful in figuring out if there's something that's misconfigured.
run_gpu make runtest -j4  || fail "Caffe tests failed."

printf "\n\t%s\n\nBuild OK."

printf "\n\t%s\n\nFetching trained MNC model..."
if ! [[ -f "./data/mnc_model.caffemodel.h5" ]]; then
  cd ${WORKDIR}/MNC
  ./data/scripts/fetch_mnc_model.sh || fail "Could not download pretrained model."
else
  echo "Model was already downloaded."
fi

printf "\n\t%s\n" "Finished setting up the Multi-Task Network Cascate (MNC) project (with its custom Caffe)!"
