/* 
 * pipeline input parameters 
 */
params.reads = "$baseDir/data/gut_{1,2}.fq"
params.transcriptome = "$baseDir/data/transcriptome.fa"
params.multiqc = "$baseDir/multiqc"
params.outdir = "results"

println """\
         R N A S E Q - N F   P I P E L I N E    
         ===================================
         transcriptome: ${params.transcriptome}
         reads        : ${params.reads}
         outdir       : ${params.outdir}
         """
         .stripIndent()

/* 
 * create a transcriptome file object given then transcriptome string parameter
 */
transcriptome_file = file(params.transcriptome)
 
/* 
 * define the `index` process that create a binary index 
 * given the transcriptome file
 */
process index {
    
    input:
    file transcriptome from transcriptome_file
     
    output:
    file 'index' into index_ch

    script:       
    """
    salmon index --threads $task.cpus -t $transcriptome -i index
    """
}


Channel 
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}"  }
    .set { read_pairs_ch } 
    

process fastqc {
    tag "FASTQC on $sample_id"
    publishDir "${params.outdir}/${task.process}", pattern: "fastqc_${sample_id}_logs/*.{zip,html}", mode: 'copy'

    input:
    set sample_id, file(reads) from read_pairs_ch

    output:
    file("fastqc_${sample_id}_logs") into fastqc_ch
    path("fastqc_${sample_id}_logs/*.{zip,html}")

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """  
}  
 

