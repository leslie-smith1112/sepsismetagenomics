
process KRAKEN {

    tag "KRAKEN:${meta.id}"
    label "metagenomics"

    input:
    tuple val(meta) path unmapped_one
    path kraken_db
    output:
}

