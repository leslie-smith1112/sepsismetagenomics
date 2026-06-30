process STAR {
    tag "${meta.id}"
    label "align"


    input:
    //tuple val(dataset), val(sample), val(read_type), path(reads)
    tuple val(meta), path(reads, stageAs: '?/*')
    path star_index
    path genome_fasta

    output:
    tuple val(meta), path("${meta.id}Aligned.sortedByCoord.out.bam"),          emit: bam
    tuple val(meta), path("${meta.id}Aligned.sortedByCoord.out.bam.bai"),      emit: bai
    tuple val(meta), path("${meta.id}Aligned.sortedByCoord.out_chrs.txt"),     emit: chr
    tuple val(meta), path("${meta.id}Log.final.out"),                           emit: log_final
    tuple val(meta), path("${meta.id}Log.out"),                                 emit: log_gen
    tuple val(meta), path("${meta.id}Log.progress.out"),                       emit: progress_out
    tuple val(meta), path("${meta.id}Unmapped.out.mate*"),                     emit: unmapped_reads // output depends on paired or single end
    tuple val(meta), path("${meta.id}SJ.out.tab"),                             emit: SJ


// conditional execution fate, only runs when 
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '' // additional CLI arguments set in conf/modules.config
    // example of what the abobve might look like:
//     task.ext = [
//     args: '--threads 8',
//     prefix: 'sampleA'
// ] for example the --thresads i could be set in the config file, then get passed in by nextflow like: fastqc $args input.fastq.gz
    def prefix = task.ext.prefix ?: "${meta.id}" // output file name prefix - will be sample ID

    //condition ? value_if_true : value_if_false
    // if reads is a single file or lise containing one file create list with mapping such as [[reads, "${prefix}.${reads.extension}"]]]
    // else pair each item iwth its corresponding index  (  [R1.fastq.gz, 0], [R2.fastq.gz, 1])
    // “For each file (entry) and its position (index) in reads, create a pair containing
    def old_new_pairs = reads instanceof Path || reads.size() == 1 ? [[reads, "${prefix}.${reads.extension}"]] : reads.withIndex().collect { entry, index -> [entry, "${prefix}_${index + 1}.${entry.extension}"] }
    // the above step generates this:
//     [
//    [R1.fastq.gz, sample1_1.gz],
//    [R2.fastq.gz, sample1_2.gz]
//    ]
    def rename_to = old_new_pairs*.join(' ').join(' ')
    //the above joins all of the renames into a list like this: "R1.fastq.gz sample1_1.gz R2.fastq.gz sample1_2.gz"
    def renamed_files = old_new_pairs.collect { _old_name, new_name -> new_name }.join(' ') // keeps only the new names and joins them into a atring

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
        // if single end, then we want to pass the reads as single ended
        //pb run needs this to be a pattern like --in-se-fq sample1_1.fastq.gz for each lane
        def reads_list = reads instanceof Path ? [reads] : reads // if instance of path, make into a list so we can call collect
        def reads_arg = reads_list.collect { read -> "--in-se-fq ${read}" }.join(' ')
        """
        pbrun rna_fq2bam \\
        ${reads_arg} \\
        --genome-lib-dir ${star_index} \\
        --output-dir . \\
        --ref ${genome_fasta} \\
        --out-bam ${prefix}Aligned.sortedByCoord.out.bam \\
        --read-files-command zcat \\
        --out-reads-unmapped Fastx --num-gpus 1 \\
        --out-prefix ${prefix}        
        """
    }else{
        // if paired end, then we want to pass the reads as paired ended
        // read must be ordered L1_R1, L1_R2, L2_R1, L2_R2 etc for pb run to correctly pair them
        //collect the R1 reads by taking the reads with even index (assuming R1 is always first in the pair)
        // first the _x files is ignored because we only need the index, then based off index selction we only need the file
        def r1s = reads.withIndex().findAll { _x, i -> i % 2 == 0 }.collect { f, _x -> f }
        // collect the R2 reads by taking the reads with odd index (assuming R1 is always first in the pair)
        def r2s = reads.withIndex().findAll { _x, i -> i % 2 == 1 }.collect { f, _x -> f }
        //zip array pairs together (column wise) and then create string of --in-fq R1.fastq.gz R2.fastq.gz for each pair
        def reads_args = [r1s, r2s].transpose().collect { r1, r2 -> "--in-fq ${r1} ${r2}" }.join(' ')

        """
        pbrun rna_fq2bam \\
        ${reads_args} \\
        --genome-lib-dir ${star_index} \\
        --output-dir . \\
        --ref ${genome_fasta} \\
        --out-bam ${prefix}Aligned.sortedByCoord.out.bam \\
        --read-files-command zcat \\
        --out-reads-unmapped Fastx --num-gpus 1 \\
        --out-prefix ${prefix}  
        """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}Aligned.sortedByCoord.out.bam
    touch ${prefix}Aligned.sortedByCoord.out.bam.bai
    touch ${prefix}Aligned.sortedByCoord.out_chrs.txt
    touch ${prefix}Log.final.out
    touch ${prefix}Log.out
    touch ${prefix}Log.progress.out
    ${meta.single_end ? '' : "touch ${prefix}_Unmapped.out.mate2"}
    touch ${prefix}Unmapped.out.mate1
    touch ${prefix}SJ.out.tab
    


    """

}