/* This module filter the fastq files either using sickle or trimmomatic, all the major parameters of these tools are implemented in this pipeline.
*  User need to specify the tool to be used to filter the fastq files.
*  The filtered fastq files will be sent to the module "RUNFASTQC" and "RUNALIGNMNET".
*/


process filterSickle {
    container params.CONTAINER
    conda "$baseDir/conda/sickle.yaml"
    //publishDir(params.fqOutputDir, pattern:"*trimmed".gz",mode:"cp")
    tag { "sickleFilter_${sample}" }
    label "oneCpu"
    							
    input:
    	tuple val(sample), path(rawFastqFiles)

    output:									
   	tuple val(sample), path("*trimmed*")

    script:									
	
	def ( fastqFileF, fastqFileR ) = rawFastqFiles
	def qualType = params.qualType
	def qualThreshold = params.qualThreshold
	def lenThreshold = params.lenThreshold
	def noFivePrime = params.noFivePrime
	def truncateN = params.truncateN
	def gzipOut = params.gzipOut
	def command = ""
	command = command + " " + "-t "+ qualType +" -q "+ qualThreshold + " -l "+ lenThreshold
	
	
	if ( noFivePrime == "Yes" ) {
	
	command = command + " "+ "-x "
	
	}
	
	if ( gzipOut == "Yes" ){
	
	command = command + " -g "
	
	}

 	"""
	
	sickle pe -f ${ fastqFileF } -r ${ fastqFileR } -s ${ sample }.singleton.fq.gz -o ${ sample }.trimmed1.fq.gz -p ${ sample }.trimmed2.fq.gz ${command}


    	"""
}

process filterTrimmomatic {
    container params.CONTAINER
    conda "$baseDir/conda/trimmomatic.yaml"
    //publishDir(params.fqOutputDir, pattern:"*trimmed".gz",mode:"cp")
    tag { "trimmomaticFilter_${sample}" }
    label "oneCpu"
    							
    input:
    	tuple val(sample), path(rawFastqFiles)

    output:									
   	tuple val(sample), path("*{FP,RP}.fq.gz")

    script:									
	
	def ( fastqFileF, fastqFileR ) = rawFastqFiles
	def ILLUMINACLIP              = params.ILLUMINACLIP
	def seedMismatches         = params.seedMismatches
	def palindromeClipThreshold           = params.palindromeClipThreshold
	def simpleClipThreshold            = params.simpleClipThreshold
	def minAdapterLength             = params.minAdapterLength
	def keepBothReads              = params.keepBothReads
	def slidingWindowSize          = params.slidingWindowSize
	def slidingWindowQual          = params.slidingWindowQual
	def maxInfo                    = params.maxInfo
	def maxInfoTargetLength           = params.maxInfoTargetLength
	def maxInfoStrictness          = params.maxInfoStrictness
	def leadingQual                = params.leadingQual
	def trailingQual               = params.trailingQual
	def cropLength                 = params.cropLength
	def headCropLength             = params.headCropLength
	def minLen                     = params.minLen
	def toPhred33                  = params.toPhred33
	def toPhred64                  = params.toPhred64

	println(minLen)

	command = ""
	
	
	if ( ILLUMINACLIP != "No" ) {
	
	command = command + " "+ "ILLUMINACLIP:"+ILLUMINACLIP+":"+seedMismatches+":"+palindromeClipThreshold+":"+simpleClipThreshold+
	":"+minAdapterLength+":"+keepBothReads
	
	}

	command = command + " LEADING:"+leadingQual+ " TRAILING:"+trailingQual
	
	if ( slidingWindowSize > 0 ){
	
	command = command + " SLIDINGWINDOW:"+slidingWindowSize+":"+slidingWindowQual
	
	}

	if ( maxInfo == "Yes" ){

	command = command + " MAXINFO:"+maxInfoTargetLength+":"+maxInfoStrictness

	}

	if ( cropLength > 0 ){

	command = command + " CROP:"+cropLength

	}

	
	if ( headCropLength > 0 ){

	command = command + " HEADCROP:"+headCropLength

	}

	command = command + " MINLEN:"+minLen

	if ( toPhred33 == "Yes" ){

	command = command + " TOPHRED33"

	}

	if ( toPhred64 == "Yes" ){

	command = command + " TOPHRED64"

	}

 	"""
	
	trimmomatic PE ${ fastqFileF } ${ fastqFileR } ${ sample }.FP.fq.gz ${ sample }.FUP.fq.gz ${ sample }.RP.fq.gz ${ sample }.RUP.fq.gz ${command}


    	"""
}

workflow FILTERFASTQ {
 
    take: 
    	fastqFiles
    
    main:
	if ( params.useFiltTool == "sickle" ){
		filteredFastqFiles = filterSickle(fastqFiles)
		}
	else{
		filteredFastqFiles = filterTrimmomatic(fastqFiles)
		}
    emit:
	filteredFastqFiles = filteredFastqFiles
}



