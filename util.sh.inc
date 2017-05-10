# Utilities for the setup and experiment scripts.

function fail {
  LAST_ERR="$?"
  # TODO(andrei): More generic message.
  echo >&2 "Failed to set up Caffe: $1"
  exit $LAST_ERR
}

# Uses a proper machine and not the login node to run stuff.
# If SLURM is not present, simply replace the 'srun -N 1' part with 'eval'.
function run {
  srun -N 1 "$@"
}

function run_gpu {
  srun -N 1 --gres=gpu:1 "$@"
}

