## ------------------------------------------------------
## CANADIAN NATIONAL FOREST DATABASE
## study area subsets
##
## Ceres: Nov 2017
## ------------------------------------------------------

## load libs
library(raster)

## LOAD DATA ----------------------------------------
## Fire data from the Canadian National Fire Database
fires.shp <- shapefile("Data/Maps/NFDB_poly/NFDB_poly_20141212.shp")

## get Canadian provinces
load("Data/Maps/CAN_adm1.Rdata")
## subset to Alberta
alberta <- CAN_adm1[CAN_adm1$NAME_1 == "Alberta",]

## get Alberta foothills study area
ALfoothills <- shapefile("Data/Maps/Alberta_study_area_shp/Alberta_study_area.shp")

## reproject
alberta <- sp::spTransform(alberta, CRSobj = crs(fires.shp))
ALfoothills <- sp::spTransform(ALfoothills, CRSobj = crs(fires.shp))
plot(alberta); plot(ALfoothills, add = TRUE, col ="grey")

## Fires in Study area
fires_foothills.shp <- intersect(fires.shp, ALfoothills)
plot(ALfoothills, col ="grey"); plot(fires_foothills.shp, add = TRUE, col = "yellow")

## subset lightning-caused fires
fires_foothillsL.shp <- fires_foothills.shp[fires_foothills.shp$CAUSE == "L",]
plot(fires_foothillsL.shp, add = TRUE, col = "red")

table(fires_foothills.shp)

