/* 
 * pipeline input parameters 
 */
params.reads = "$baseDir/data/ggal/gut_{1,2}.fq"
params.transcript = "$baseDir/data/ggal/transcriptome.fa"
params.multiqc = "$baseDir/multiqc"
params.outdir = "results"

log.info """\
         R N A S E Q - N F   P I P E L I N E    
         ===================================
         transcriptome: ${params.transcript}
         reads        : ${params.reads}
         outdir       : ${params.outdir}
         """
         .stripIndent()

 
/* 
 * define the `index` process that create a binary index 
 * given the transcriptome file
 */
process index {
    
    input:
    path transcriptome from params.transcript
     
    output:
    path 'index' into index_ch

    script:       
    """
    salmon index --threads $task.cpus -t $transcriptome -i index
    """
}


Channel 
    .fromFilePairs( params.reads, checkIfExists:true )
    .set { read_pairs_ch } 

/*
 * Run Salmon to perform the quantification of expression using
 * the index and the matched read files
 */
process quantification {
    publishDir "quantification", mode: 'symlink'
    input:
    path index from index_ch
    tuple val(pair_id), path(reads) from read_pairs_ch
 
    output:
    path(pair_id) into quant_ch
 
    script:
    """
    salmon quant --threads $task.cpus --libType=U -i $index -1 ${reads[0]} -2 ${reads[1]} -o $pair_id
    """
}

