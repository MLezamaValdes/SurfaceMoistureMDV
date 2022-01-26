# Landsat cloud clean 

cloud_shadow <- c(328, 392, 840, 904, 1350)
cld <- c(352, 368, 416, 432, 480, 864, 880, 928, 944, 992)
mc_cloud <- c(386, 388, 392, 400, 416, 432, 898, 900, 904, 928, 944)
hc_cloud <- c(480, 992)
hc_cirrus <- c(834, 836, 840, 848, 864, 880, 898, 900, 904, 912, 928, 944, 992)
lc_cirrus <- c(322, 324, 328, 336, 352, 368, 386, 388, 392, 400, 416, 432, 480)
lc_cloud <- c(322, 324, 328, 336, 352, 368, 834, 836, 840, 848, 864, 880)

cloud <- c(cloud_shadow,cld,mc_cloud,hc_cloud,hc_cirrus)


# valid range removes a lot of useful pixels 
L_cloud_scale <- function(qualras, bands, sn){
  c <- qualras 
  cs <- is.element(values(c),cloud)
  c[] <- cs

  # remove cloud pixels 
  bands[c==1] <- NA
  
  # crop to aoi
  bands <- crop(bands, aoi)
  bands <- mask(bands, aoi)
  
  # # valid range
  bands[bands < 0 ] <- NA
  bands[bands > 10000] <- NA
  
  # scale factor
  bands <- bands*0.0001
  
  names(bands) <- sn[2:7]
  
  return(list(bands,c))
}
