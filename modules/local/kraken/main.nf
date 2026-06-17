
process KRAKEN {

    tag "KRAKEN:${meta.id}"
    label "metagenomics"

    input:
    tuple val(meta), path(unmapped_one)
    path kraken_db

    output:
    tuple val(meta), path("${meta.id}.k2report"), emit: report

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '' // additional CLI arguments set in conf/modules.config
    def prefix = task.ext.prefix ?: "${meta.id}" // output file name prefix - will be sample ID

    """
    echo "Running Kraken2 on ${unmapped_one} with database ${kraken_db}" >> ${prefix}.k2report
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.k2report

    """

}

