#!/bin/bash
#SBATCH --job-name=sepsis_kraken
#SBATCH --account=kgraim
#SBATCH --partition=hpg-default
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2gb
#SBATCH --time=24:00:00
#SBATCH --output=logs/kraken_%j.log
#SBATCH --error=logs/kraken_%j.err
#SBATCH --mail-user=leslie.smith1@ufl.edu

mkdir -p logs

module load nextflow

nextflow run main.nf \
    -profile hipergator \
    --outdir results/ \
    -resume

