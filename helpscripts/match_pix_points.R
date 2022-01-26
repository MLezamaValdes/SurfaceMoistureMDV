
# sattype can be "LST" or "sr" 

match_pix_points <- function(sat_scene, sattype="sr",
                             point_locs, maxna, date,
                             sat_min_tolerance, 
                             iB_min_tolerance,
                             SoilS_min_tolerance){
  
  match_df_AWSS <- NULL
  match_df_iBut <- NULL
  
  orgnames_scc <- names(sat_scene)
  ons <- str_split(orgnames_scc, "_")
  
  if(sattype=="sr"){
    names(sat_scene) <- unlist(lapply(ons, "[[", 9))
  } else if (sattype=="LST"){
    names(sat_scene) <- "LST"
  }

  # get pixel values from all points and add site name and capturing time,
  # keep only available data 
  scc_pl <- raster::extract(sat_scene, point_locs_anta, df=TRUE, cellnumbers=FALSE)
  scc_pl$Site <- point_locs_anta$Site_Name
  scc_pl <- scc_pl[rowSums(is.na(scc_pl))<maxna,] # depending on amount of bands
  locinfo <- paste0("AWSS: ", sum(scc_pl$Site %in% AWSS_IDs, na.rm=TRUE), "; ", 
                    "iButtons: ", sum(scc_pl$Site %in% iBut_IDs, na.rm=TRUE))
  
  print(locinfo)
  
  if(nrow(scc_pl) > 0){ # if there are any pixels over loggers
    
    scc_pl$Lsc_date <- date # add date of Landsat scene 
    
    # make time intervals around the capturing time of Landsat and the logging 
    # time of the iButtons 
    start <- scc_pl$Lsc_date - minutes(sat_min_tolerance)
    end <- scc_pl$Lsc_date + minutes(sat_min_tolerance)
    scc_pl$scc_tiv <- interval(start, end)
    
    
    naws <- sum(scc_pl$Site %in% AWSS_IDs)
    nib <- sum(scc_pl$Site %in% iBut_IDs)
    both <- naws > 0 & nib > 0
    
    
    if(naws > 0){ # if there are pixels over AWS 
      start <- SoilS_data$GMT_time - minutes(SoilS_min_tolerance )
      end <- SoilS_data$GMT_time + minutes(SoilS_min_tolerance )
      SoilS_data$SoilS_tiv <- interval(start, end)
      
      # subsetting AWSS data by the sites that were available in the raster
      site <- SoilS_data[SoilS_data$Site_Name %in% scc_pl$Site,]
      # intersecting the time intervals of Landsat and AWSS 
      scctiv <- rep(scc_pl$scc_tiv[1], length(site$SoilS_tiv))
      secintersect <- as.period(intersect(site$SoilS_tiv, scctiv), "sec")
      timematch <- which(!is.na(secintersect))
      
      matching <- site[timematch,]
      matching$Lsc_tiv <- scc_pl$scc_tiv[1]
      matching$secintersect <- secintersect[!is.na(secintersect)]
      
      # match pixel data with the matching iButton data 
      match_df_AWSS <- merge.data.frame(scc_pl, matching, by.x="Site", 
                                        by.y="Site_Name")
      
      match_df_AWSS$Lscene <- substring(orgnames_scc[1], 1,43)
      
      
    }
    
    if (nib > 0){ # if there are pixels over iButtons
      start <- iB_all$iBut_GMT_time - minutes(iB_min_tolerance)
      end <- iB_all$iBut_GMT_time + minutes(iB_min_tolerance)
      iB_all$iBut_tiv <- interval(start, end)
      
      # subsetting iButton data by the sites that were available in the raster
      site <- iB_all[iB_all$Site_Name %in% scc_pl$Site,]
      
      # intersecting the time intervals of Landsat and iButtons 
      scctiv <- rep(scc_pl$scc_tiv[1], length(site$iBut_tiv))
      secintersect <- as.period(intersect(site$iBut_tiv, scctiv), "sec")
      timematch <- which(!is.na(secintersect))
      
      matching <- site[timematch,]
      matching$Lsc_tiv <- scc_pl$scc_tiv[1]
      matching$secintersect <- secintersect[!is.na(secintersect)]
      
      # match pixel data with the matching iButton data 
      match_df_iBut <- merge.data.frame(scc_pl, matching, by.x="Site", 
                                        by.y="Site_Name")
      
      match_df_iBut$Lscene <- substring(orgnames_scc[1], 1,43)
      
    } 
  }
  
  nAW <- nrow(match_df_AWSS)
  niB <- nrow(match_df_iBut)
  
  if(is.null(match_df_iBut)){
    match_df_iBut <- NA
    niB <- NA
  }
  if(is.null(match_df_AWSS)){
    match_df_AWSS <- NA 
    nAW <- NA
  }
  return(list(match_df_AWSS,
              match_df_iBut,
              locinfo,
              nAW,
              niB))
  
}
