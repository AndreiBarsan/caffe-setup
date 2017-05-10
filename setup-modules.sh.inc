
# Protip: The Euryale Titan X cards are the Pascal version. CUDA 7.5 does NOT
# support them!
CUDA_VERSION="8.0.27"
# CUDA_VERSION="7.5.18"

MODULE_CUDA_DIR="/site/opt/cuda/${CUDA_VERSION}/x64"
module load cuda/"${CUDA_VERSION}"  || fail 'Could not load CUDA module.'
# As of May 2017, Caffe (or at least the version used with MTN) does NOT
# support cuDNN 5 or higher, and cuDNN 4 leads to errors, so it's disabled.
# TODO(andrei): Remove this if merge added support for cuDNN.
module load cudnn/v5.1              || fail 'Could not load cuDNN module.'
module load opencv/2.4.11           || fail 'Could not load OpenCV module.'
# Fun fact: Boost 1.60 had a bug preventing it from being used to compile Caffe.
module load boost/1.62.0            || fail 'Could not load boost module (v1.62.0).'
module load mpich                   || fail 'Could not load mpi module.'

