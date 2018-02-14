## ------------------------------------------------------
## DATA PREPARATION
##
## REPROJECTING DAVE'S FIRE DATA
##
## Ceres: Dec 2017
## ------------------------------------------------------

rm(list=ls())

## requires
library(raster)

## using (Dec 2017)
# sessionInfo()

# R version 3.4.2 (2017-09-28)
# other attached packages:
#   [1] raster_2.6-7 sp_1.2-5    
# 
# loaded via a namespace (and not attached):
#   [1] compiler_3.4.2  rgdal_1.2-15    parallel_3.4.2  tools_3.4.2     yaml_2.1.14     Rcpp_0.12.13    grid_3.4.2      knitr_1.17      lattice_0.20-35

## LOAD data ----------------------------------------
## Alberta province and foothills
alberta <- shapefile("data/maps/Alberta/Alberta")
foothills <- shapefile("data/maps/Alberta_study_area_shp/Alberta_study_area")

## Alberta fires
alta_proj <- "+proj=utm +zone=11 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"  # Dave told me this is the correct crs for alberta fires

altaFires1_pre <- shapefile("data/fires_Dave/Original_files/alberta24-pre")
altaFires1_post <- shapefile("data/fires_Dave/Original_files/original-fires-debbie")
altaFires2_pre <- shapefile("data/fires_Dave/Original_files/prefire-vegonly")
altaFires2_post <- shapefile("data/fires_Dave/Original_files/todebbie1")

## add projection attribute
crs(altaFires1_pre) = crs(altaFires1_post) = crs(altaFires2_pre) = crs(altaFires2_post) = alta_proj

## reproject to WGS84 and save
reprojs <- lapply(grep("altaFires", ls(), value = TRUE), FUN = function(x) {
  eval(expr = parse(text = paste0(x, " <- sp::spTransform(", x, ", CRSobj = crs(alberta))")))
  eval(expr = parse(text = paste0("return(", x, ")")))
})

names(reprojs) = grep("altaFires", ls(), value = TRUE)

## save rasters with projection info and better names
dir.create("data/fires_Dave/Projected_renamed")
shapefile(reprojs$altaFires1_pre, filename = "data/fires_Dave/Projected_renamed/albertafires1_prefire", overwrite = TRUE)
shapefile(reprojs$altaFires1_post, filename = "data/fires_Dave/Projected_renamed/albertafires1_postfire", overwrite = TRUE)
shapefile(reprojs$altaFires2_pre, filename = "data/fires_Dave/Projected_renamed/albertafires2_prefire", overwrite = TRUE)
shapefile(reprojs$altaFires2_post, filename = "data/fires_Dave/Projected_renamed/albertafires2_postfire", overwrite = TRUE)

## Saskatchewan fires
sask_proj <- "+proj=utm +zone=13 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"  # Dave told me this is the correct crs for saskatchewan fires

saskFires_pre <- shapefile("data/fires_Dave/Original_files/prefiresum2")
saskFires_post <- shapefile("data/fires_Dave/Original_files/all2-fixed")

## add projection attribute
crs(saskFires_pre) = crs(saskFires_post) = sask_proj

## reproject to WGS84 and save
reprojs <- lapply(grep("saskFires", ls(), value = TRUE), FUN = function(x) {
  eval(expr = parse(text = paste0(x, " <- sp::spTransform(", x, ", CRSobj = crs(alberta))")))
  eval(expr = parse(text = paste0("return(", x, ")")))
})

names(reprojs) = grep("saskFires", ls(), value = TRUE)

shapefile(reprojs$saskFires_pre, filename = "data/fires_Dave/Projected_renamed/saskatchewanfires_prefire", overwrite = TRUE)
shapefile(reprojs$saskFires_post, filename = "data/fires_Dave/Projected_renamed/saskatchewanfires_postfire", overwrite = TRUE)


