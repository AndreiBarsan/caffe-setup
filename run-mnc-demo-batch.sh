#!/usr/bin/env bash

mkdir -p ~/experiments/"$(date +'%Y-%m-%d')" && cd $_ && sbatch mnc-demo-batch.sh
