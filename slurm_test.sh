#!/bin/bash
#SBATCH --job-name=sepsis_wf_test
#SBATCH --account=kgraim
#SBATCH --partition=hpg-default
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8gb
#SBATCH --time=24:00:00
#SBATCH --output=logs/wf_test_%j.log
#SBATCH --error=logs/wf_test_%j.err
#SBATCH --mail-user=leslie.smith1@ufl.edu

mkdir -p logs

module load nextflow

nextflow run main.nf \
    -profile test \
    --outdir results/test_run \
    -resume

