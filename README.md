# nf-core/sepsismetagenomics

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open_In_GitHub_Codespaces-black?labelColor=grey&logo=github)](https://github.com/codespaces/new/nf-core/sepsismetagenomics)
[![GitHub Actions CI Status](https://github.com/nf-core/sepsismetagenomics/actions/workflows/nf-test.yml/badge.svg)](https://github.com/nf-core/sepsismetagenomics/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/sepsismetagenomics/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/sepsismetagenomics/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.0.2-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.0.2)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/sepsismetagenomics)

## Introduction

**nf-core/sepsismetagenomics** is a bioinformatics pipeline to identify pathogens in RNA-Seq samples from humans. It takes a samplesheet with FASTQ files or SRA accession number, downloads sample from SRA when needed, performs quality control, removes reads that align to the human genome using STAR, assigns taxonomic labels to the unmapped sequences, and performs MultiQC on each step. In general this pipeline follows analysis workflow recommended by [Lu, J. et al.](https://doi.org/10.1038/s41596-022-00738-y).

#### Pipeline Input file
The pipeline takes in a csv file from `assets/samplesheet.csv` containing rows with four columns corresponding to: `sample_name,path_to_fastq_1,path_to_fastq_2,source`. <br>
`sample_name` = the name of the samples to be processed <br>
`path_to_fastq_1` = path to location of read 1 OR empty if source = `sra`<br>
`path_to_fastq_2` = path to location of read 2 if paired-end OR empty if single-ended <br>
`source` = local OR sra

Example input:
```
sample,fastq_1,fastq_2,source
SS_01, data/SS_01.fastq.gz,,local
SS_02, data/SS_02_R1.fastq.gz,data/SS_02_R2.fastq.gz,local
SRR0946912,,,sra
```

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/community/brand/workflow-schematics#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline --><br>.1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))<br>2. Download reads from SRA when `source == sra`([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))<br>3.Align reads to human genome using T2T reference([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))<br>4.Assign taxonomic labels to unmapped reads([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))<br>5.Present QC for raw reads ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

```bash
nextflow run main.nf \
    -profile hipergator \
    --outdir results/ \
    -resume
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/running/run-pipelines#using-parameter-files).

## Credits

nf-core/sepsismetagenomics was originally written by Leslie Smith.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

References for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
This pipeline uses 

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

