
process KRAKEN {

    tag "KRAKEN:${meta.id}"
    label "metagenomics"

    input:
    tuple val(metas), path(all_reads)
    path kraken_db

    output:
    tuple val(metas), path("*.k2report"), emit: reports

    when:
    task.ext.when == null || task.ext.when

    script:
    def local_dir = ${SLURM_TMPDIR} // this will be changed jun 29

// build copy and kraken commands per sample
    def file_idx = 0
    def kraken_cmds = metas.collect { meta ->
        def paired_arg = meta.single_end ? "" : "--paired"
        def reads_arg  = meta.single_end
            ? "${local_dir}/${all_reads[file_idx++].name}"
            : "${local_dir}/${all_reads[file_idx++].name} ${local_dir}/${all_reads[file_idx++].name}"
        "kraken2 --db ${kraken_db} --threads ${task.cpus} --report ${meta.id}.k2report ${paired_arg} ${reads_arg}"
    }.join('\n')

    def copy_reads = all_reads.collect { "cp ${it} ${local_dir}/" }.join('\n')
    def args = task.ext.args ?: '' // additional CLI arguments set in conf/modules.config
    def prefix = task.ext.prefix ?: "${meta.id}" // output file name prefix - will be sample ID
    
    """
    mkdir -p ${local_dir}
    ${copy_reads}
    ${kraken_cmds}
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.k2report

    """

}

