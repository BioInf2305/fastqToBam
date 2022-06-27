/*
*  samtools modules and workflows
*  if run with the option "with-singularity" then the tool will be run in container, otherwise it will create conda environment. 
*/


process runBwaIndex {
    container params.CONTAINER
    conda "$baseDir/conda/bwa.yaml"
    tag { "runBwa_${sample}" }
    label "oneCpu"
    							
    input:
	tuple val(refPrefix), path(refFiles)

    output:									
   	tuple val(refPrefix), path("*.{amb,ann,bwt,pac,sa}")

    script:									
	
	"""
	bwa index -p ${refPrefix} ${refFiles}

    	"""
}


process runBwaMemAlignment {
    container params.CONTAINER
    conda "$baseDir/conda/bwa.yaml"
    tag { "runBwa_${sample}" }
    label "sixteenCpus"
    							
    input:
    	tuple val(sample), path(rawFastqFiles), val(refPrefix), path(refFiles)

    output:									
   	tuple val(sample), path("*.sam")

    script:									
	
	def ( fastqFileF, fastqFileR ) = rawFastqFiles
 	
	"""
	
	bwa mem -R '@RG\\tID:${sample}\\tSM:${sample}\\tPL:ILLUMINA' -t ${task.cpus} ${refPrefix} ${fastqFileF} ${fastqFileR} > ${sample}.sam

    	"""
}


process runSamtoolsSorting{
    container params.CONTAINER
    conda "$baseDir/conda/samtools.yaml"
    //publishDir(params.finalFilteredBamFiles, pattern:"*.sorted.bam",mode:"copy")
    tag { "runSamtools_${sample}" }
    label "sixteenCpus"
    							
    input:
    	tuple val(sample), path(rawSamFile)

    output:									
   	tuple val(sample), path("*.sorted.{bam,bam.bai}")

    script:
										
	def tmpFolder = params.tmpFolder
 	
	"""
	if [ ! -d ${tmpFolder}/${sample} ]; then mkdir ${tmpFolder}/${sample};fi 

	samtools view -@ ${task.cpus} -O BAM -o ${sample}.bam ${rawSamFile}

	samtools sort -@ ${task.cpus} -T ${tmpFolder}/${sample} -m ${task.memory.toGiga()}G -O BAM -o ${sample}.sorted.bam ${sample}.bam

	samtools index ${sample}.sorted.bam
	
	
	if [ -d ${tmpFolder}/${sample} ];then rm -r ${tmpFolder}/${sample};fi

    	"""
}


process removeDuplicates{
    container params.CONTAINER
    conda "$baseDir/conda/picard.yaml"
    publishDir(params.finalFilteredBamFiles, pattern:"*.sorted.rmDup.bam",mode:"copy")
    tag { "removeDuplicate_${sample}" }
    label "oneCpu"
    							
    input:

    	tuple val(sample), path(sortedMergedBamFile)

    output:									
   	tuple val(sample), path("*.sorted.rmDup.bam")

    script:
										
	def tmpFolder = params.tmpFolder
	def validationStrigency = params.validationStringency
	def (bamFile, bamFileIndex) = sortedMergedBamFile

	"""
	if [ ! -d ${tmpFolder}/${sample} ];then mkdir ${tmpFolder}/${sample};fi

	picard "-Xmx${task.memory.toGiga()}G " MarkDuplicates TMP_DIR=${tmpFolder}/${sample} I=${bamFile} O=${sample}.sorted.rmDup.bam AS=true REMOVE_DUPLICATES=true METRICS_FILE=${sample}.rmDupMetrics.txt VALIDATION_STRINGENCY=${validationStrigency}
	
	if [ -d ${tmpFolder}/${sample} ];then rm -r ${tmpFolder}/${sample};fi
    	"""
}



process runBamIndexing{
    container params.CONTAINER
    conda "$baseDir/conda/samtools.yaml"
    publishDir(params.finalFilteredBamFiles, pattern:"*.sorted.rmDup.bam.bai",mode:"copy")
    tag { "runBamIndexing_${sample}" }
    label "oneCpu"
    							
    input:
    	tuple val(sample), path(sortedRmDupBam)

    output:									
   	path("*.sorted.rmDup.bam.bai")

    script:
										
 	
	"""
	
	samtools index ${sortedRmDupBam}	

    	"""
}


workflow RUNALIGNMENT {
 
    take: 
    	filtFastqRefT
    
    main:
	rawSamFilesT = runBwaMemAlignment( filtFastqRefT )
	sortedBamFileT = runSamtoolsSorting( rawSamFilesT )
	sortedRmDupBamFileT = removeDuplicates(sortedBamFileT)
	runBamIndexing(sortedRmDupBamFileT)
	 
	
}
