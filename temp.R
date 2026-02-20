## get projection
crsProj <- crs(vect("data/fires_Dave/fireSev/albertafires1_postfire.shp"), proj = TRUE)

## list of variables retained in model without spatial covariates (model8.4FULL in DAfires_sevModelsGAMLSS.Rmd)
vars <- c("Decid", "HEIGHT_LOWER", "CTI", "Lari", "SMR_wet",
          "UNDERSTOREY", "FlamConif", "PctSlope", "SurfAspectRatio",
          "isForest")

## convert logical to binary. averages will be the proportion of 1s
dataPoints <- summaryABSK_AllData[, .SD, .SDcols = c("pixID", "FIRE_NAME", "Lat", "Long", vars)]
cols <- which(unlist(as.vector(dataPoints[, lapply(.SD, is.logical)])))
dataPoints <- dataPoints[, (cols) := lapply(.SD, as.integer), .SDcols = cols]
dataPoints <- st_as_sf(dataPoints, coords = c("Long", "Lat"),
                      agr = "constant", crs = st_crs(crsProj))

bufferDists <- 30
for (i in 2:7) {
  bufferDists[i] <- bufferDists[i - 1] * 2
}

## note that for binary varibles mean = proportion of 1s
ngbNoBurns <- reproducible::Cache(calculateNgbAvgsWrapper,
                                  dists = bufferDists,
                                  dataPoints = dataPoints,
                                  pointIDColID = "pixID",
                                  fireColID = "FIRE_NAME",
                                  resolution = resolution,
                                  parallel = FALSE,
                                  cores = 3,
                                  # useCache = doCache,
                                  useCache = FALSE,
                                  cacheId = "",
                                  userTags = "ngbAvg",
                                  omitArgs = c("useCache", "userTags", "cores", "parallel"))
ngbNoBurns <- dcast.data.table(ngbNoBurns, ... ~ bufferSize, value.var = "ngbPropBurns")

cols <- grep("pixID|FIRE_NAME", names(ngbNoBurns), invert = TRUE, value = TRUE)
setnames(ngbNoBurns, old = cols, new = paste0("buffer_", cols, "m"))

summaryABSK_AllData <- ngbNoBurns[summaryABSK_AllData, on = .(pixID, FIRE_NAME)]

rm(dataPoints); gc(reset = TRUE)
