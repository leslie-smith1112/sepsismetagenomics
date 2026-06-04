process STAR_ALIGNER {
    tag "STAR:${dataset}:${sample}:${read_type}"
    label "align"



    input:
    tuple val(dataset), val(sample), val(read_type), path(reads)

}