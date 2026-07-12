
process KRAKEN {

    tag "${metas*.id.join(',')}"

    label "metagenomics"

    input:
    tuple val(metas), path(all_reads)
    path kraken_db

    output:
    tuple val(metas), path("*.k2report"), emit: reports

    when:
    task.ext.when == null || task.ext.when

    script:

    // copy the kraken db onto this node's tmpfs (/dev/shm) once, then point every
    // kraken2 call below at that local copy with --memory-mapping, so the db is
    // loaded into RAM a single time and mmap-shared across all samples in the loop
    // instead of each kraken2 invocation privately reloading it from network storage
    def shm_db = "/dev/shm/kraken_db_${workflow.sessionId}"
    def args = task.ext.args ?: '' // additional CLI arguments set in conf/modules.config

// build kraken commands per sample
    def file_idx = [0] // use a list to hold the index so it can be modified inside the closure
    def kraken_cmds = metas.collect { meta ->
        def paired_arg = meta.single_end ? "" : "--paired"
        // we were having some issues with the idx - so we will now just keep track of the index in a variable and increment it as we go through the list of metas
        def idx1 = file_idx[0]
        file_idx[0] = idx1 + 1
        def r1 = all_reads[idx1]
        def r2 = null
        if (!meta.single_end) {
            def idx2 = file_idx[0]
            file_idx[0] = idx2 + 1
            r2 = all_reads[idx2]
        }
        def reads_arg = meta.single_end ? "${r1}" : "${r1} ${r2}"
        "kraken2 --db ${shm_db} --memory-mapping --threads ${task.cpus} ${args} --report ${meta.id}.k2report ${paired_arg} ${reads_arg}"
    }.join('\n')

    //def prefix = task.ext.prefix ?: "${meta.id}" // output file name prefix - will be sample ID

    """
    mkdir -p ${shm_db}
    trap 'rm -rf ${shm_db}' EXIT
    cp -r ${kraken_db}/. ${shm_db}/
    ${kraken_cmds}
    """

    stub:
    //def prefix = task.ext.prefix ?: "${meta.id}"
    def touch_cmds = metas.collect { "touch ${it.id}.k2report" }.join('\n')
    """
    ${touch_cmds}

    """

}

