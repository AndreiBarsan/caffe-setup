#!/usr/bin/env bash
# Experimental script to install Caffe in a users's HOME directory.
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
  #srun -N 1 "$@"
  # TODO(andrei): Test everything with slurm once there's a free machine.
  eval "$@"
}


################################################################################
# Basic Setup
################################################################################

echo "Setting up Caffe for the local user (experimental support)..."

# Load appropriate modules.
# If executing remotely, make sure you source the appropriate system-level configs
# in order to expose the 'module' command.

CUDA_VERSION="7.5.18"

# 'x64' == hack for CUDA 7.5's path being inconsistent.
MODULE_CUDA_DIR="/site/opt/cuda/${CUDA_VERSION}/x64"
module load cuda/"${CUDA_VERSION}"  || fail 'Could not load CUDA module.'
module load cudnn/v5.1              || fail 'Could not load CUDNN module (v5.1).'
module load opencv/2.4.12           || fail 'Could not load OpenCV module (v2.4.12).'
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
cd ~/work


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


################################################################################
# Setup Protobuf
################################################################################

if ! [[ -f "${HOME}/bin/protoc" ]]; then
  cd ${WORKDIR}
  if ! [[ -d protobuf ]]; then
    git clone https://github.com/google/protobuf.git
  fi

  cd protobuf/
  run ./autogen.sh                        || fail "protobuf autogen failed"
  run ./configure --prefix="${HOME}"      || fail "protobuf configure failed"
  run make -j4                            || fail "protobuf make failed"
  run make install                        || fail "protobuf install failed"
else
  echo "Found ~/bin/protoc. Not installing protobuf."
fi


################################################################################
# Setup gflags
################################################################################

if ! [[ -f "${HOME}/lib/libgflags.a" ]]; then
  cd ${WORKDIR}
  if ! [[ -d gflags ]]; then
    git clone https://github.com/gflags/gflags.git
  fi

  cd gflags
  mkdir build
  cd build
  run cmake -DCMAKE_INSTALL_PREFIX:PATH=${HOME} -DCMAKE_CXX_FLAGS:STRING=-fPIC .. || fail "Could not configure gflags"
  run make         || fail "Could not build gflags"
  run make install || fail "Could not install glags"
else
  echo "Found local gflags installation. Not installing gflags."
fi


################################################################################
# Setup LevelDB
################################################################################

if ! [[ -f "${HOME}/lib/libleveldb.so" ]]; then
  cd ${WORKDIR}
  if ! [[ -d leveldb ]]; then
    git clone https://github.com/google/leveldb.git
  fi
  cd leveldb/
  make
  cp --preserve=links out-static/libleveldb.* "${HOME}/lib"
  cp --preserve=links out-shared/libleveldb.* "${HOME}/lib"
  cp -r include/leveldb "${HOME}/include"
else
  echo "Found local leveldb installation. Not installing leveldb."
fi


################################################################################
# Setup Snappy
################################################################################

if ! [[ -f "${HOME}/lib/libsnappy.so" ]]; then
  cd ${WORKDIR}
  if ! [[ -d snappy ]]; then
    git clone https://github.com/google/snappy.git
  fi
  cd snappy/
  ./autogen.sh
  ./configure --prefix=${HOME}
  run make          || fail "Could not build Snappy."
  # This WILL fail with some bullshit reason about not being to install the
  # docs due to a file with some wrong name, but we don't care.
  run make install  #|| fail "Could not install Snappy."
else
  echo "Found local Snappy installation. Not installing Snappy."
fi


################################################################################
# Setup mdb
################################################################################

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

printf "\n\t%s\n" "Dependencies set up OK. Building Caffe itself."
printf "\n\t%s\n" "This will take a while."

# TODO(andrei): Do we need custom Makefile tricks to support cuDNN?
# Nevermind, it seems that cuDNN 6, which is required for modern Caffe, is not
# available on Euryale.

# TODO(andrei): Check if Caffe is installed and complain.
cd "${WORKDIR}"

if ! [[ -d 'caffe' ]]; then
  git clone https://github.com/BVLC/caffe.git
  cd caffe
fi

  cd caffe
  cp Makefile.config.example Makefile.config
# TODO(andrei): Uncomment if the local ATLAS installation is necessary.
  # sed -i 's|#?\s*BLAS_LIB\s*:=\s*/.*|BLAS_LIB := '"${HOME}/local/atlas/path/here"'|g' Makefile.config || fail "Could not update Makefile configuration."

  # Ensure Caffe knows about our locally installed components.
  sed -i '/^INCLUDE_DIRS\s*:=/ s|$| '"${HOME}"'/include|g' Makefile.config
  sed -i '/^LIBRARY_DIRS\s*:=/ s|$| '"${HOME}"'/lib|g' Makefile.config

  # Ensure Caffe uses the right CUDA installation.
  # TODO(andrei): Mini-benchmark info with and without cudnn.
  sed -i 's|^CUDA_DIR\s*:=\s.*|CUDA_DIR := '"${MODULE_CUDA_DIR}"'|' Makefile.config

  # TODO(andrei): Remove arch 60, 61 lines if using CUDA 7.5.

  run make all        || fail "Could not build caffe."
  # TODO(andrei): Do we need to run these on a GPU?
  run make test       || fail "Could not build caffe tests."
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${MODULE_CUDA_DIR}/x64/lib64"
  run make runtest    || fail "Caffe tests failed!"

printf "\n\t%s\n" "Finished installing Caffe!"
