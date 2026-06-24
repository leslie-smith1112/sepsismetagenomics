
process KRAKEN {

    tag "KRAKEN:${meta.id}"
    label "metagenomics"

    input:
    tuple val(meta), path(unmapped_reads)
    path kraken_db

    output:
    tuple val(meta), path("${meta.id}.k2report"), emit: report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '' // additional CLI arguments set in conf/modules.config
    def prefix = task.ext.prefix ?: "${meta.id}" // output file name prefix - will be sample ID

    """
    if (meta.single_end) {
        kraken2 --db ${kraken_db} --report ${prefix}.k2report ${args} ${unmapped_reads}
    } else {
        kraken2 --db ${kraken_db} --report ${prefix}.k2report ${args} ${unmapped_reads[0]} ${unmapped_reads[1]}
    }
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.k2report

    """

}

