#!/usr/bin/env nextflow


nextflow.enable.dsl=2



version                 = "1.0"
// this prevents a warning of undefined parameter
params.help             = false

// this prints the input parameters

fastqFilesPath  = params.fastqFiles
refFilesPath    = params.refPrefixFiles

Channel
    .fromFilePairs( fastqFilesPath )
    .set { fastqFileTuple }


include { FILTERFASTQ } from "${baseDir}/modules/filterFastq"

include { RUNFASTQC } from "${baseDir}/modules/runFastqc"

include { RUNALIGNMENT } from "${baseDir}/modules/runAlignment"


workflow {
	filteredFastqFiles = FILTERFASTQ( fastqFileTuple )
	RUNFASTQC(filteredFastqFiles)
	Channel
    		.fromFilePairs( refFilesPath, size: -1 )
    		.set{ refFilesTuple }
	combinedFiltFastqRefFilesT= filteredFastqFiles.combine(refFilesTuple)
	RUNALIGNMENT( combinedFiltFastqRefFilesT )
	
}




workflow.onComplete { 
    println ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
    }
