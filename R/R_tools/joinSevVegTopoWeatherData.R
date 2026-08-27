## ----------------------------------------
## JOIN FIRE SEVERITY, VEGETATION, TOPO AND WEATHER DATA
##
## Ceres Dec 11th 2018
## ----------------------------------------

## this script should be sourced

#' Join fire severity with vegetation, topography and weather data
#'
#' Wrapper that rasterizes fire severity polygons to a common pixel
#' grid, then joins pre-prepared vegetation, topography and weather
#' data to each fire's pixels. Joins are done one fire at a time and
#' cached as per-fire `.RData` files under `saveDir`; the wrapper then
#' row-binds everything into one `data.table`.
#'
#' @param sevDataSf `sf` object of fire severity polygons. Must contain
#'   a `FIRE_NAME` column used to loop over fires.
#' @param vegDataSf `sf` object of vegetation polygons covering (at
#'   least) the fire perimeters.
#' @param topoDataSf `sf` object of topographic covariates. Fires
#'   falling entirely outside its extent get NA topography.
#' @param weatherDataDt `data.table` of weather covariates keyed by
#'   fire. Must contain a `fireName` column (renamed internally to
#'   `FIRE_NAME`) that matches (upper-cased) values in
#'   `sevDataSf$FIRE_NAME`.
#' @param resolution numeric. Resolution of the internal template
#'   raster used for pixel IDs, in meters. Defaults to 100.
#' @param doAll logical. If `FALSE` (default) skip fires whose per-fire
#'   table already exists in `saveDir`; if `TRUE` redo everything.
#' @param saveDir character. Directory where per-fire
#'   `dataTable_<FIRE>.RData` files are written and later re-read.
#'
#' @return A `data.table` binding all per-fire joined tables (one row
#'   per burnt pixel, with severity + veg + topo + weather columns).
#' @author Ceres Barros
#' @seealso [joinPerFire()]
joinSevVegTopoWeatherData <- function(sevDataSf, vegDataSf, topoDataSf, weatherDataDt,
                                      resolution = 100, doAll = FALSE, saveDir) {
  ## make a template raster that will be used to extract pixIDs
  ## note that IDs run 1:ncell(templateRas)
  ## not enough memory to rasterize the full extent to 10x10res
  rasterToMatch <- raster(sevDataSf, resolution = resolution,
                          crs = crs(sevDataSf))
  if(!raster::compareCRS(crs(sevDataSf), crs(rasterToMatch))) {
    crs(rasterToMatch) <- crs(sevDataSf)
    rasterToMatch <- raster::projectRaster(rasterToMatch, crs = crs(sevDataSf))
  }
  rasterToMatch <- fasterize(sf = sevDataSf, raster = rasterToMatch)
  rasterToMatch <- setValues(rasterToMatch, values = 1:ncell(rasterToMatch))

  # writeRaster(rasterToMatch, file.path(saveDir, "rasterToMatch.tif"))

  ## do computations per fire
  fireNames <- as.character(unique(sevDataSf$FIRE_NAME))
  setnames(weatherDataDt, "fireName", "FIRE_NAME")

  ## save data.tables in a temporary folder
  dir.create(saveDir, showWarnings = FALSE)

  if(!doAll) {
    firesDone <- sub(".RData", "", sub("dataTable_", "",
                                       list.files(saveDir, pattern = "dataTable")))
    firesDone <- gsub("_", " ", firesDone)
    fireNames <- fireNames[!gsub("_", " ", fireNames) %in% firesDone]
  }

  if(length(fireNames))
    message(paste0(length(fireNames), " fires to do.")) else
      message("All fires have been joined.")
  ## do joins and save output tables by fire
  for(x in fireNames) {
    joinPerFire(smallSevDataSf = sevDataSf[sevDataSf$FIRE_NAME == x,],
                vegDataSf = vegDataSf, topoDataSf = topoDataSf,
                weatherDataDt = weatherDataDt,
                rasterToMatch = rasterToMatch, saveDir = saveDir)
  }

  message("Binding tables...")

  allDataDT <- rbindlist(lapply(list.files(saveDir, pattern = "dataTable", full.names = TRUE),
                                FUN = function(x) {
                                  load(x)
                                  return(dataDT)
                                }))
  message("... done!")
  return(allDataDT)
}

#' Join severity, vegetation, topography and weather data for one fire
#'
#' Internal worker called by [joinSevVegTopoWeatherData()]. Extracts
#' pixel IDs from `rasterToMatch` for one fire perimeter, then
#' intersects severity, topography, vegetation and weather to produce a
#' wide `data.table` saved as `dataTable_<FIRE>.RData` under `saveDir`.
#'
#' @param smallSevDataSf `sf` object with severity polygons for one
#'   fire only.
#' @param vegDataSf,topoDataSf,weatherDataDt as in
#'   [joinSevVegTopoWeatherData()].
#' @param rasterToMatch `Raster*` layer with unique pixel IDs (values
#'   `1:ncell(.)`); used to align severity, veg and topo joins.
#' @param saveDir character. Output directory for the `.RData` file.
#'
#' @return Called for its side effect (writes
#'   `dataTable_<FIRE>.RData`). Returns `NULL` invisibly.
#' @keywords internal
joinPerFire <- function(smallSevDataSf, vegDataSf, topoDataSf, weatherDataDt,
                        rasterToMatch, saveDir) {
  amc::.gc()
  message(paste0("Joining data for: ", as.character(unique(smallSevDataSf$FIRE_NAME))))
  ## do data "joins" by intersecting SF objects with a raster and making a data.table with pixIDs
  ## severity polygons to then extract veg, topo, weather data

  ## To make a templateraster with RTM pix IDs need to:
  ## 1) extract pix IDs in RTM from an extent, 2) crop RTM to extent,
  ## 3) rasterize, 4) subset pix IDs where polygons exist 1s
  ## the is because direct rasterization to RTM doesn't work on small fires
  ## and cropping doesn't keep RTM cell values as it should, creating duplicates
  pixID <- extract(rasterToMatch, extent(as_Spatial(smallSevDataSf)))

  templateRas <- crop(rasterToMatch, as_Spatial(smallSevDataSf))
  templateRas <- fasterize(sf = smallSevDataSf,
                           raster = templateRas)
  pixID <- pixID[!is.na(getValues(templateRas))]

  coords <- xyFromCell(templateRas, cell = which(!is.na(getValues(templateRas))))
  dataDT <- data.table(pixID = pixID,
                       Long = coords[, 1], Lat = coords[, 2])
  setkey(dataDT, pixID)

  ## convert templateRas to points, provide CRS
  templatePoints <- st_as_sf(dataDT, coords = c("Long", "Lat"))

  if(!compareCRS(crs(templatePoints), crs(templateRas))) {
    st_crs(templatePoints) <- as.character(crs(templateRas))
    templatePoints <- st_transform(templatePoints, crs =  as.character(crs(templateRas)))
  }

  ## GET SEVERITY DATA
  message("... joining fire severity data")
  ## simplify data to polygons - should be faster
  smallSevDataSf <- st_cast(smallSevDataSf, "POLYGON")

  ## make sure CRS is the same
  if(!compareCRS(crs(templatePoints), crs(smallSevDataSf)))
    smallSevDataSf <- st_transform(smallSevDataSf, crs = st_crs(templatePoints))

  ## extract polygon info per point
  sevDataPoints <- st_join(x = templatePoints,
                           y = smallSevDataSf)  ## >10xs faster than st_intersection

  ## make datatable and join to master table
  sevDataPoints <- data.table(st_set_geometry(sevDataPoints, NULL))
  setkey(sevDataPoints, pixID)
  dataDT <- sevDataPoints[dataDT, nomatch = 0]

  ## JOIN TOPOGRAPHY DATA
  message("... joining topographic data")
  if(!compareCRS(crs(topoDataSf), crs(smallSevDataSf)))
    topoDataSf <- st_transform(topoDataSf, crs = st_crs(smallSevDataSf))

  ## use prioritizr::fast_extract to extract raster IDs per point
  templateRasV <- templateRas
  templateRasV[!is.na(getValues(templateRasV))] <- pixID

  ## if extents do not intersect (some fires are beyond the topo SF extent)
  ## then make NA IDs
  topoDataPixID <- if (prioritizr:::is_spatial_extents_overlap(templateRasV, topoDataSf)) {
    fast_extract(templateRasV, topoDataSf)[,1]   ## faster than raster::extract()
  } else {
    rep(NA, dim(topoDataSf)[1])
  }

  topoDataPoints <- data.table(st_set_geometry(topoDataSf, NULL))
  topoDataPoints$pixID <- topoDataPixID
  setkey(topoDataPoints, pixID)

  dataDT <- topoDataPoints[dataDT, nomatch = 0]

  ## clean-up to free memory:
  rm(topoDataPoints, topoDataPixID,
     templateRasV, templateRas,
     sevDataPoints, pixID, coords)
  amc::.gc()

  ## JOIN VEGETATION DATA
  message("... joining pre-fire vegetation data")

  if(!compareCRS(crs(templatePoints), crs(vegDataSf)))
    vegDataSf <- st_transform(vegDataSf, crs = st_crs(templatePoints))

  vegDataSf <- st_cast(vegDataSf, "POLYGON")

  vegDataPoints <- st_join(x = templatePoints,
                           y = vegDataSf)

  vegDataPoints <- data.table(st_set_geometry(vegDataPoints, NULL))
  setkey(vegDataPoints, pixID)
  setkey(dataDT, pixID)
  dataDT <- vegDataPoints[dataDT, nomatch = 0]

  ## JOIN WEATHER DATA
  message("... joining weather data")
  dataDT[FIRE_NAME == "Alfred", FIRE_NAME := "Alfred Lake"]
  dataDT[, FIRE_NAME := toupper(FIRE_NAME)]

  setkey(weatherDataDt, FIRE_NAME)
  setkey(dataDT, FIRE_NAME)
  dataDT <- weatherDataDt[dataDT, allow.cartesian = TRUE, nomatch = 0]

  message("... saving temp file")
  tempFile <- paste0("dataTable_",
                     sub(" ", "_", as.character(unique(smallSevDataSf$FIRE_NAME))),
                     ".RData")
  save("dataDT", file = file.path(saveDir, tempFile))
  message("... done!")
}
