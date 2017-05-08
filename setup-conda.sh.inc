
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

set +u
source activate mnc
set -u

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

