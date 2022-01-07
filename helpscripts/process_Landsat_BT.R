
sc <- paste0(fd[1], "/")
processLandsatBT <- function(sc){ # per BT scene that is unzipped already

  if(length(sc)!=0){
    
    # get Metadata
    f <- list.files(sc, full.names=T)
  
    mtlFile <- list.files(sc, pattern="MTL.txt", full.names = T)
    
    metaData <- readMeta(mtlFile)
    date <- metaData$ACQUISITION_DATE
    
    bqaFile <- list.files(sc, pattern="pixel_qa.tif", full.names = T)
    
    band10File <- list.files(sc, pattern="band10.tif", full.names = T)
      
    ################## process thermal bands #################################################################

    # cloud mask
    x <- raster(bqaFile)
    c <- x
    cs <- is.element(values(c),cloud)
    c[] <- cs
    
    b10 <- raster(band10File)
    nam <- names(b10)
    
    b10[c==1] <- NA # clean out clouds
      
    
    ################## CUT TO AOI ##################################################################################
    b10_aoi <- crop(b10, extent(aoianta))
    b10_aoi <- mask(b10_aoi, aoianta)
    print("masked to research area")
    
    btc <- (b10_aoi*0.1)-273.15
    
    # get rock outcrop raster with Emissivity values
    eta <- raster(list.files(here("../aux_data/"), pattern="Rock_outcrop_ras_MDV_res.tif", full.names = T))
    
    
    
    LST <- btc/(1+(0.0010895*btc/0.01438)*log(eta))
    
    print("LST calculated")
    
    # bring to same extent and write LST 

    LST <- resample(LST, template)
    
    # remove "_band_10" from name to use for writing
    namsp <- strsplit(nam,split='_', fixed=TRUE)
    namsp <- namsp[[1]][1:(length(namsp[[1]])-2)]
    nam <- paste(namsp, collapse = '_')
    
    writeRaster(LST, paste0(sc, "/", nam, "_LST.tif"),
                format="GTiff", overwrite=T)
    
    print("LST written")
      
    } else {txt <- "no available data for time range"
    print(txt)
    return("nothing")} 
}
