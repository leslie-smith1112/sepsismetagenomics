process SRA_DOWNLOAD {

    tag "SRA_DOWNLOAD:${meta.id}"
    label "download"

    input:
    val(meta)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p tmp
    prefetch ${prefix} --output-directory .
    fasterq-dump ${prefix} \\
        --threads ${task.cpus} \\
        --split-files \\
        --temp tmp \\
        --outdir . \\
        ${args}
    pigz -p ${task.cpus} -1 *.fastq
    """

    stub:
    """
    echo "completed the test for file 1" > ${meta.id}_1.fastq 
    gzip ${meta.id}_1.fastq
    ${meta.single_end ? '' : "echo 'completed the test for file 2' > ${meta.id}_2.fastq; gzip ${meta.id}_2.fastq"}
    """

}
