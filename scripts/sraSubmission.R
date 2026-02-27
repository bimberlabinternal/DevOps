


queryReadData <- function(readsetIds, folderPath = "/Labs/Bimber/") {
  readdata <- labkey.selectRows(
    baseUrl="https://prime-seq.ohsu.edu", 
    folderPath=folderPath, 
    schemaName="sequenceanalysis", 
    queryName="readdata", 
    viewName="", 
    colSelect="rowid,readset,fileid1/name,fileid1/datafileurl,fileid2/name,fileid2/datafileurl,container,sra_accession",
    colNameOpt="rname",
    colFilter=makeFilter(
      c('readset', 'IN', paste0(unique(readsetIds), collapse = ';')),
      c('sra_accession', 'ISBLANK', '')
    ),
  )
  
  readdata$fileid1_datafileurl <- gsub(x = readdata$fileid1_datafileurl, pattern = 'file://', replacement = '')
  readdata$fileid2_datafileurl <- gsub(x = readdata$fileid2_datafileurl, pattern = 'file://', replacement = '')
  
  readdata$targetname1 <- paste0(readdata$readset, '_', readdata$rowid, '_R1_001.fastq.gz')
  readdata$targetname2 <- paste0(readdata$readset, '_', readdata$rowid, '_R2_001.fastq.gz')  
  
  return(readdata)
}

prepareReadFiles <- function(metadata, filePrefix, 
                             library_strategy = 'RNA-Seq',
                             library_source = 'TRANSCRIPTOMIC',
                             library_selection = 'cDNA_oligo_dT',
                             instrument_model = 'Illumina NovaSeq X Plus'
) {
  stagingDirName <- paste0('staging.', filePrefix)
  
  files <- queryReadData(metadata$datasetId, folderPath = folderPath)
  files <- files %>% arrange(readset, targetname1) 
  files <- files %>% group_by(readset) %>% mutate(TotalPairs = n(), PairNum = row_number())

  allFiles <- data.frame(readset = unique(files$readset))
  hasPaired <- FALSE
  j <- 0
  for (i in 1:max(files$TotalPairs)) {
    j <- j + 1
    field1 <- paste0('filename', j)
    if (field1 == 'filename1') {
      field1 = 'filename'
    }
    
    ret <- data.frame(readset = unique(files$readset))
    ret[[field1]] = ''
    
    sourceFields <- c('readset', 'targetname1')
    targetFields <- c('readset', field1)
    if (!all(is.null(files$targetname2))) {
      j <- j + 1
      field2 <- paste0('filename', j)
    
      ret[[field2]] = ''
      
      sourceFields <- c(sourceFields, 'targetname2')
      targetFields <- c(targetFields, field2)
      hasPaired <- TRUE
    }
    
    toMerge <- files[files$PairNum == i, sourceFields]
    names(toMerge) <- targetFields
    
    
    allFiles <- merge(allFiles, toMerge, by = 'readset', all.x = T)
  }
  
  library_layout = ifelse(hasPaired, yes = 'paired', no = 'single')
    
  toWrite <- data.frame(
    sample_name = metadata$sample_name,
    library_ID = metadata$readsetId,
    title = metadata$sample_name,
    library_strategy = library_strategy,
    library_source = library_source,
    library_selection = library_selection,
    library_layout = library_layout,
    platform = metadata$platform,
    instrument_model = instrument_model,
    design_description = metadata$librarytype,
    filetype = 'fastq'
  )
    
  toWrite <- merge(toWrite, allFiles, by.x = 'library_ID', by.y = 'readset', all.x = T)
    
  f <- file(paste0(filePrefix, '.srametadata.txt'), 'wb')
  write.table(toWrite, file = f, sep = '\t', row.names = F, quote = F, na = '')  
  close(f)
  
  toWrite2 <- data.frame(file = sort(unique(c(files$targetname1, files$targetname2))))
  f <- file(paste0(filePrefix, '.toUpload.txt'), 'wb')
  write.table(toWrite2, file = f, sep = '\t', row.names = F, quote = F, col.names = F)  
  close(f)
    
  commands <- c('#!/bin/bash', 'set -e', 'set -x', paste0('if [ ! -e ', stagingDirName, ' ];then'), paste0('mkdir ', stagingDirName), 'fi')
    
  fileSet <- files[files$readset %in% metadata$readsetId,]
  sel <- !is.na(fileSet$fileid1_name)
  commands <- c(commands, paste0('ln -s ', fileSet$fileid1_datafileurl[sel], ' ', stagingDirName, '/', fileSet$targetname1[sel]))
  sel <- !is.na(fileSet$fileid2_name)
  commands <- c(commands, paste0('ln -s ', fileSet$fileid2_datafileurl[sel], ' ', stagingDirName, '/', fileSet$targetname2[sel]))
  
  f <- file(paste0(filePrefix, '.symlinks.sh'), 'wb')
  write.table(commands, file = f, sep = '\t', quote = F, row.names = F, col.names = F)
  close(f)
}

prepareSubmissionForReadsets <- function(metadata, filePrefix, folderPath = '/Labs/Bimber/') {
  expectedCols <- c('sample_name','sample_title','bioproject_accession','organism','strain','isolate','breed','cultivar','ecotype','age','dev_stage','sex','tissue','biomaterial_provider','birth_date','birth_location','breeding_method','cell_line','cell_subtype','cell_type','collected_by','collection_date','culture_collection','death_date','disease','disease_stage','genotype','geo_loc_name','growth_protocol','isolation_source','lat_lon','sample_type','description', 'datasetId')
  
  toWrite <- NULL
  for (col in expectedCols) {
    if (col %in% names(metadata)){
      print(paste0('found: ', col))
      vect <- metadata[col]
    } else {
      vect <- rep('', nrow(metadata))
    }
    
    if (is.null(toWrite)) {
      toWrite <- data.frame(x = vect)
      names(toWrite) <- col
    } else {
      toWrite[col] <- vect
    }
  }
  
  if ('m' %in% toWrite$sex) {
    toWrite$sex[toWrite$sex == 'm'] <- 'male'  
  }
  
  if ('f' %in% toWrite$sex) {
    toWrite$sex[toWrite$sex == 'f'] <- 'female'
  }
  
  if ('u' %in% toWrite$sex) {
    toWrite$sex[toWrite$sex == 'u'] <- 'not provided'
  }
  
  toWrite$sex[is.na(toWrite$sex)] <- 'not provided'
  
  toWrite$collection_date <- as.Date(toWrite$collection_date)
  
  names(toWrite)[names(toWrite) == 'sample_name'] <- '*sample_name'
  names(toWrite)[names(toWrite) == 'organism'] <- '*organism'
  names(toWrite)[names(toWrite) == 'sex'] <- '*sex'
  names(toWrite)[names(toWrite) == 'tissue'] <- '*tissue'
  names(toWrite)[names(toWrite) == 'collection_date'] <- '*collection_date'
  names(toWrite)[names(toWrite) == 'geo_loc_name'] <- '*geo_loc_name'
  
  toWrite <- toWrite %>% arrange(datasetId)
  
  f <- file(paste0(filePrefix, '.sampleinfo.txt'), 'wb')
  write.table(toWrite, file = f, sep = '\t', row.names = F, quote = F, na = '')  
  close(f)
}