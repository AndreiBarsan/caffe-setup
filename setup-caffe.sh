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
module load cuda           || fail 'Could not load CUDA module.'
module load cudnn/v5.1     || fail 'Could not load CUDNN module (v5.1).'
module load opencv/2.4.12  || fail 'Could not load OpenCV module (v2.4.12).'
module load boost/1.60.0   || fail 'Could not load boost module (v1.60.0).'

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
#run make -j8 	    || fail "Could not build ATLAS."
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
# Setup leveldb
################################################################################

if ! [[ -f "${HOME}/lib/libleveldb.so" ]]; then
  cd ${WORKDIR}
  if ! [[ -d leveldb ]]; then
    git clone https://github.com/google/leveldb.git                  
  fi
  cd leveldb/                                                      
  make
  cp --preserve=links out-static/libleveldb.* ${HOME}/lib
  cp --preserve=links out-shared/libleveldb.* ${HOME}/lib
  cp -r include/leveldb ${HOME}/include
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
  # Yep, the quirky quoting is necessary.
  # TODO(andrei): Use $HOME.
  sed -i 's|prefix\s*=\s*/usr/local|prefix = '"${HOME}"'|g' Makefile || fail "Sed fail"
  # vi Makefile # change prefix to /home/you/usr
  make            || fail "Could not build mdb."
  make install    || fail "Could not install mdb."
fi


################################################################################
# Setup Caffe
################################################################################

echo "\n\t Dependencies set up OK. Installing Caffe itself."

# TODO(andrei): Do we need custom Makefile tricks to support cudNN?

cd "${WORKDIR}"
  git clone https://github.com/BVLC/caffe.git
  cd caffe
  cp Makefile.config.example Makefile.config
  # TODO(andrei): Uncomment if the local ATLAS installation is necessary.
  # sed -i 's|BLAS_LIB := .*|BLAS_LIB := '""'|g' Makefile || fail "Could not update Makefile configuration."
  #sed '/^INCLUDE_DIRS:/ s/$/ /usr/local/include|' file




echo "Done."
