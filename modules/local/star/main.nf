process STAR {
    tag "STAR:${meta.id}"
    label "align"

    input:
    //tuple val(dataset), val(sample), val(read_type), path(reads)
    tuple val(meta), path(reads, stageAs: '?/*')


    output: 
    path "${meta.id}.txt"
    path "${meta.id}_Aligned.sortedByCoord.out.bam"
    path "${meta.id}_Aligned.sortedByCoord.out.bam.bai"
    path "${meta.id}_Aligned.sortedByCoord.out_chrs.txt"
    path "${meta.id}_Log.final.out"
    path "${meta.id}_Log.out"
    path "${meta.id}_Log.progress.out"
    path "${meta.id}_Log.Unmapped.out.mate1"
    path "${meta.id}_SJ.out.tab"

// conditional execution fate, only runs when 
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '' // additional CLI arguments set in conf/modules.config
    def prefix = task.ext.prefix ?: "${meta.id}" // output file name prefix - will be sample ID
    // Make list of old name and new name pairs to use for renaming in the bash while loop
    def is_paired = reads instanceof Path || reads.size() == 1 ? false : true
    def old_new_pairs = reads instanceof Path || reads.size() == 1 ? [[reads, "${prefix}.${reads.extension}"]] : reads.withIndex().collect { entry, index -> [entry, "${prefix}_${index + 1}.${entry.extension}"] }
    def rename_to = old_new_pairs*.join(' ').join(' ')
    def renamed_files = old_new_pairs.collect { _old_name, new_name -> new_name }.join(' ')

    // The total amount of allocated RAM by FastQC is equal to the number of threads defined (--threads) time the amount of RAM defined (--memory)
    // https://github.com/s-andrews/FastQC/blob/1faeea0412093224d7f6a07f777fad60a5650795/fastqc#L211-L222
    // Dividing the task.memory by task.cpus allows to stick to requested amount of RAM in the label
    def memory_in_mb = task.memory
        ? (task.memory.toUnit('MB') / task.cpus).intValue()
        : null
    // FastQC memory value allowed range (100 - 10000)
    // def fastqc_memory = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)
    // def fastqc_memory_arg = fastqc_memory ? "--memory ${fastqc_memory}" : ''

    if(meta.single_end){
        """
        echo "SINGLE- would run single-ended star" > ${meta.id}.txt
        
        """
    }else{
        """
        echo "PAIRED - would run pair-ended star" > ${meta.id}.txt
        """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.txt
    touch ${prefix}_Aligned.sortedByCoord.out.bam
    touch ${prefix}_Aligned.sortedByCoord.out.bam.bai
    touch ${prefix}_Aligned.sortedByCoord.out_chrs.txt
    touch ${prefix}_Log.final.out
    touch ${prefix}_Log.out
    touch ${prefix}_Log.progress.out
    touch ${prefix}_Log.Unmapped.out.mate1
    touch ${prefix}_SJ.out.tab

    """

}