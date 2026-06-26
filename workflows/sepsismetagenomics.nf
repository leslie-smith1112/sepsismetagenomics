/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SRA_DOWNLOAD } from '../modules/local/sra_download/main'
include { STAR } from '../modules/local/star/main'
include { KRAKEN } from '../modules/local/kraken/main'
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_sepsismetagenomics_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SEPSISMETAGENOMICS {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()
    
    
    def ch_branched = ch_samplesheet.branch {
        local: it[0].source == 'local' // it here is [meta, [fastq_1, fastq_2]], so we are looking at the meta part of the tuple and checking the source key
        sra: it[0].source == 'sra'
    }

    SRA_DOWNLOAD(ch_branched.sra.map {meta, _reads -> meta}) // input is just the meta becasue we will get the reads from the output of this process, output is [meta, [fastq_1, fastq_2]]
    def ch_sra_reads = SRA_DOWNLOAD.out.reads.map { meta, reads -> 
        def single_end = reads instanceof Path || reads.size() == 1
        [meta + [single_end: single_end], reads ]
    } // output is [meta, [fastq_1, fastq_2]] where the reads are downloaded from sra
    def ch_reads = ch_branched.local.mix(ch_sra_reads) // ch_reads is now a channel of tuples like [meta, [fastq_1, fastq_2]] where the reads are either from the local input or downloaded from sra
    //
    // MODULE: Run FastQC
    //

    FASTQC(ch_reads)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.map{ _meta, file -> file })

    def ch_star_index   = params.star_index   ? file(params.star_index)   : []
    def ch_genome_fasta = params.genome_fasta ? file(params.genome_fasta) : []  

    STAR(ch_reads, ch_star_index, ch_genome_fasta) // second input here would be the star index

    ch_multiqc_files = ch_multiqc_files.mix(STAR.out.log_final.map{_meta,file -> file})

    // we will pass all kraken input as single channel so we only have to read in the database once per node.
    def ch_kraken_input = STAR.out.unmapped_reads.map
                                                 .collect()
                                                 .map { items ->
                                                    def sorted = items.sort {a, b -> a[0].id <=> b[0].id } // sort by sample id
                                                    [sorted.collect {it[0]}, sorted.collect {it[1]}.flatten() ]
                                                }

    def ch_kraken_db = params.kraken_db ? file(params.kraken_db) : []
    KRAKEN(ch_kraken_input, ch_kraken_db) 

    // split samples back out for multiqc
    ch_multiqc_files = ch_multiqc_files.mix(
        KRAKEN.out.reports.flatMap {metas, reports ->
            [metas.sort {it.id}, reports.sort {it.name }].transpose()
            }.map{ _meta, report -> report}
    )


    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'sepsismetagenomics_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'sepsismetagenomics'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )
    emit:multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
