process CHECK_KINETICS {
    // Establish whether kinetics tags are present in a BAM
    input:
        path unmodBam
    output:
        tuple path("*.bam", arity: 1, includeInputs: true), env(HAS_KINETICS)
    script:
        """
        HAS_KINETICS=\$([[ ! -z \$(samtools view $unmodBam | head -1 | grep -E '((fi)|(ri)|(fp)|(rp)):') ]] && echo TRUE || echo FALSE)
        """
    stub:
        """
        HAS_KINETICS=\$([ ! -z \$(grep 'HAS_KINETICS' $unmodBam) ] && echo TRUE || echo FALSE)
        """
}

process PREDICT_FIBERTOOLS {
    // Run fibertools to predict base modification
    // Naming the process so it's clearer if we add other tools for prediction
    // at a later point
    input:
        path unmodBam, arity: 1
    output:
        path "fibertools_predict.*.bam", arity: 1
    publishDir "${params.outdir}", mode: 'copy', overwrite: true
    script:
        """
        ft predict-m6a \
        --ml $params.ftMinMLScore \
        --threads $task.cpus \
        $unmodBam fibertools_predict.$unmodBam
        """
    stub:
        """
        touch fibertools_predict.$unmodBam
        """
}

process EXTRACT_CALLS {
    // Extract variant calls to a tabular format using modkit
    input:
        path modBam, arity: 1
    output:
        path "*.calls.tsv.gz"
    publishDir "${params.outdir}", mode: 'copy', overwrite: true
    script:
        """
        modkit extract calls \
        -t ${task.cpus} \
        $modBam \
        - \
        | gzip > ${modBam}.calls.tsv.gz
        """
}

workflow {
    Channel.fromPath(params.bams) |
        view |
        // Remove files we are not interested in based on terms in name
        filter { !(it =~/(fail)|(subread)|(scrap)|(unassigned)/) } |
        view |
        CHECK_KINETICS |
        view |
        filter { it[1] == "TRUE" } |
        view |
        map { it[0] } |
        view |
        PREDICT_FIBERTOOLS |
        view |
        EXTRACT_CALLS |
        view
}