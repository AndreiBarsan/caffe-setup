# caffe-setup

Customized Caffe local user installation script for ETH Zurich's IVC cluster.
Meant to work with a modules system and assumes CUDA and other things are available.

Not intended for generic use, but hopefully it may help serve as a starting point
for other people.

## Hypothetical use case

This is intentonally vague, but provided in the hopes that it would help one
understand the purpose of these scripts.

  1. Gain access to GPU machine/cluster. If it's your local machine, or one
     where you have sudo access (e.g., AWS/Azure instance), then your life
     will probably be much easier, and this repo probably isn't for you ;).
  1. Establish how you can access that GPU. This script set assumes the cluster
     is accessed via [slurm](https://slurm.schedmd.com/), but it can be
     modified for systems with no job scheduling, lsf-based systems, etc.
  1. Additionally, the scripts assume the system supports [environment
     modules](http://modules.sourceforge.net/) for loading different versions
     of CUDA, cuDNN, boost, etc.
  1. If the above conditions are met (or once you tweaked the scripts
     accordingly), the first thing you will need to do is install Caffe (duh!).
     This is done by running './setup-mnc.sh' on the remote host. This script
     will load the appropriate modules and set up miniconda for the Python
     stuff. It will then build Caffe, pycaffe, and run its tests. It will also
     download the MNC's pretrained weights provided by its authors.
  1. You can then use 'run-mnc-demo.sh' to run the demo provided by the
     authors. You should either run that script from the `MNC` project root, or
     provide the `--input` and `--output` flags explicitly.
  1. (Bonus) You can use `run-mnc-demo-batch.sh` to run the demo as a batch job
     via `sbatch`, instead of interactively via `srun`.
  1. (Bonus) The `run-euryale.sh` and `fetch-euryale.sh` scripts are
     special-use-case ones which are meant to run the segmentation on full
     sequences of the KITTI dataset. The first one rsyncs the data to the
     server and kicks off a batch job to process them, while the second one can
     be used to rsync the results back when they're done.
