import java.nio.file.Paths
import java.nio.file.Files
import java.util.stream.Collectors

def pathMap = [:]

def expectedOutputs(inBam) {
    // Determine whether the expected outputs for a given input file exist
    // This is used to filter out files which already have an output
    // Very specific to how our group intends to use the pipeline, and
    // atypical way for Nextflow pipelines to work
    def ftPredict = Paths.get(
        inBam.getParent().toString(),
        "fibertools_predict.${inBam.getName()}"
    )
    def calls = Paths.get(
        inBam.getParent().toString(),
        "fibertools_predict.${inBam.getName()}.calls.tsv.gz"
    )
    return (
        (params.extract_calls && Files.exists(calls)) && 
        Files.exists(ftPredict)
    )
}

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
    publishDir "${params.outdir}", mode: 'copy', overwrite: true, saveAs: {
        // Determine where to save this based on the input directory
        def originalBase = it.toString().replace("fibertools_predict.", "")
        def inFullPath = pathMap.get(originalBase.toString())
        def outPath = Paths.get(
            inFullPath.getParent().toString(),
            it.toString()
        )
        return outPath
    }
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
    publishDir "${params.outdir}", mode: 'copy', overwrite: true, saveAs: {
        // Determine where to save this based on the input directory
        def originalBase = it.toString()
            .replace("fibertools_predict.", "")
            .replace(".calls.tsv.gz", "")
        def inFullPath = pathMap.get(originalBase.toString())
        def outPath = Paths.get(
            inFullPath.getParent().toString(),
            it.toString()
        )
        return outPath
    }
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
    def pathChannel = Channel.fromPath(params.bams)
    // Maintain a mapping of filename -> full path for all files in the 
    // channel so we can use this in a custom publishDir strategy
    pathChannel.subscribe onNext: {
        pathMap.put(it.getName(), it)
    }

    // Place files into one of three branches
    // filtered - removed due to strings in filename which indicate not to use
    // done - files which appear to already have output
    // process - all other files
    def inputBranches = pathChannel |
        branch {
            done: !params.clobber && expectedOutputs(it)
            filtered: (it =~/(fail)|(subread)|(scrap)|(unassigned)|(fibertools)/) 
            process: true
        }
    
    // Log which files will not be processed with reason
    inputBranches.filtered |
        collect |
        view { 
            def nlList = it.stream()
                .map((x) -> x.toString())
                .collect(Collectors.joining("\n")) 
            println "Not processed due to filtering:\n${nlList}"
        }
    inputBranches.done |
        collect |
        view { 
            def nlList = it.stream()
                .map((x) -> x.toString())
                .collect(Collectors.joining("\n")) 
            println "Not processed due to output existing:\n${nlList}"
        }
        
    def predictedChannel = inputBranches.process |
        CHECK_KINETICS |
        filter { it[1] == "TRUE" } |
        map { it[0] } |
        PREDICT_FIBERTOOLS

    if(params.extract_calls) {
        predictedChannel |
        EXTRACT_CALLS
    }
}