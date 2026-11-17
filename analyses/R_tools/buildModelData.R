## Assemble the modelling table for the severity models.
## Moved verbatim from the dataprep, addNgbNoBurns and addNgbAvgProperties
## chunks of analyses/DAfires_sevModelsGAMLSS_ngbAvg.Rmd (2026-11-16).
## Expects in scope: doCache, the sourced helper functions and modelCfg
## (analyses/R_tools/modelConfig.R).

resolution = 30

summaryABSK_AllData <- reproducible::Cache(
  dataPrepWrapper,
  resolution = resolution, 
  fireDataPath = "data/fires_Dave/fireSev",
  vegDataPath = "data/fires_Dave/prefireVeg",
  topoDataPath = "data/fires_Dave/DEM/Grid30Intersect",
  weatherDataPath = "data/fires_Dave/fireWeather",
  doCache = doCache,
  userTags = "summaryABSK_AllData",
  cacheId = "cc55d7d2a817284e",
  omitArgs = c("useCache", "doCache", "userTags"))

## /!\ the following variables have many NA's and should perhaps be excluded
## wetlands are indicated within `LandCover`, the wetland vars are too much for this analysis.
## "WETLAND_CLASS", "WETLAND_VEG_MOD", "WETLAND_LAND_MOD", "WETLAND_LOCAL_MOD"
## "Duration"
## "cvRain" is mostly NA -- with meanRain == 0.
## SMR_ord/wet -- probably nothing that can be done here and there are few NAs on this one.
## Aspect: 12% of pixels have -117, which is an undocumented value that perhaps it behaves as a flat-surface code; these pixels have near-zero SCOS/SSIN, but circa 40% of them have PctSlope > 0. Perhaps best not to use Aspect

## make different buffer sizes around points
crsProj <- crs(vect("data/fires_Dave/fireSev/albertafires1_postfire.shp"), proj = TRUE)

SEV_PROPpoints <- summaryABSK_AllData[, .(pixID, FIRE_NAME, SEV_PROP, Lat, Long)]
SEV_PROPpoints <- st_as_sf(SEV_PROPpoints, coords = c("Long", "Lat"),
                           agr = "constant", crs = st_crs(crsProj))

ngbNoBurns <- Cache(calculateNgbBurnsWrapper,
                    dists = modelCfg$bufferDists,
                    sevPoints = SEV_PROPpoints,
                    sevColID = "SEV_PROP",
                    fireColID = "FIRE_NAME",
                    resolution = resolution,
                    parallel = TRUE,
                    cores = 3,
                    useCache = doCache,
                    cacheId = "c7536dcb493ad453",
                    userTags = "ngbBurns",
                    omitArgs = c("useCache", "userTags", "cores"))

ngbNoBurns <- dcast.data.table(ngbNoBurns, ... ~ bufferSize, value.var = "ngbPropBurns")

## note that ngbPropBurns_XXm used to be buffer_XXm
cols <- grep("pixID|FIRE_NAME", names(ngbNoBurns), invert = TRUE, value = TRUE)
setnames(ngbNoBurns, old = cols, new = paste0("ngbPropBurns_", cols, "m"))

summaryABSK_AllData <- ngbNoBurns[summaryABSK_AllData, on = .(pixID, FIRE_NAME)]

rm(SEV_PROPpoints); gc(reset = TRUE)

## list of non-collinear variables retained as model candidates. Ignore weather variables here.
vars <- readRDS("analyses/outputs/nonCollinearVars.rds")
vars <- c(vars$topographic, vars$vegetation)

## add a few others that are model candidates and which neighbourhood averages need to be calculated
## e.g. flammable conifers has to be in despite correlations with isForest.
## weather variables are candidates but do not vary spatially.
vars <- unique(c(vars, "STAND_STRUCTURE", "UNDERSTOREY", "LandCover", "isForest", "DIST1", "DIST2", "SMR_ord", "SMR_wet",
          "FlamConif"))

## subset columns of interest, keeping pix/fireID coordinates 
dataPoints <- summaryABSK_AllData[, .SD, .SDcols = c("pixID", "FIRE_NAME", "Lat", "Long", vars)]

## convert logical to binary. averages will be the proportion of 1s
## SMR_ord will be converted to integer.
cols <- names(which(unlist(as.vector(dataPoints[, lapply(.SD, is.logical)]))))
cols <- setdiff(cols, c("pixID", "FIRE_NAME", "Lat", "Long"))
dataPoints[, (cols) := lapply(.SD, as.integer), .SDcols = cols]

dataPoints[, SMR_ord := as.integer(as.character(SMR_ord))]

## expand categorical to binary variables per factor level. averages will be the proportion of 1s
## exclude SMR_ord -- converted to integer above.
cols <- names(which(unlist(as.vector(dataPoints[, lapply(.SD, function(col) inherits(col, c("character", "factor")))]))))
cols <- setdiff(cols, c("pixID", "FIRE_NAME", "Lat", "Long", "SMR_ord"))

## "collapse" all categorical variables into a single column -- one row per pixel x categorical variable
long <- melt.data.table(dataPoints[, .SD, .SDcols = c(cols, c("pixID"))],
             id.vars = "pixID", measure.vars = cols,
             variable.name = "var", value.name = "class", variable.factor = FALSE)
long <- long[!is.na(class)]
long[, value := 1L]

## one 0/1 column per var_class
dummies <- dcast.data.table(long, pixID ~ var + class, value.var = "value", fill = 0L, sep = "_")

## dcast fills absent combinations with 0, so pixels that were NA for a
## variable would look like "0 for every class" -- restore NA instead
for (v in cols) {
  dcols <- grep(paste0("^", v, "_"), names(dummies), value = TRUE)
  naPix <- dataPoints[is.na(get(v)), pixID]
  dummies[pixID %in% naPix, (dcols) := NA_integer_]
}

origPix <- dataPoints$pixID
dataPoints <- dummies[dataPoints[, !..cols], on = "pixID"]

if (length(setdiff(origPix, dataPoints$pixID))) {
  stop("Bad join; pixels lost")
} else rm(origPix)

dataPoints <- st_as_sf(dataPoints, coords = c("Long", "Lat"),
                       agr = "constant", crs = st_crs(crsProj))

## note that for binary variables mean = proportion of 1s
ngbAvgs <- Cache(calculateNgbAvgsWrapper,
                 dists = modelCfg$bufferDists,
                 dataPoints = dataPoints,
                 pointIDColID = "pixID",
                 fireColID = "FIRE_NAME",
                 resolution = resolution,
                 # parallel = TRUE,
                 cores = 5,
                 useCache = doCache,
                #  cacheId = "c7536dcb493ad453",  ## needs to be overwritten re-cached
                 userTags = "ngbAvg",
                 omitArgs = c("useCache", "userTags", "cores", "parallel"))

## make sure col classes are ok.
ngbAvgs[, pixID := as.integer(pixID)]
summaryABSK_AllData[, pixID := as.integer(pixID)]

ngbAvgs[, FIRE_NAME := as.factor(FIRE_NAME)]
summaryABSK_AllData[, FIRE_NAME := as.factor(FIRE_NAME)]

summaryABSK_AllData <- ngbAvgs[summaryABSK_AllData, on = .(pixID, FIRE_NAME)]

rm(dataPoints, ngbAvgs, ngbNoBurns); for (i in 1:3) gc(reset = TRUE)

## holdout flag and fire-grouped fold IDs (calibration fires only)
summaryABSK_AllData[, holdout := FIRE_NAME %in% modelCfg$holdoutFires]

if (!is.na(modelCfg$nFolds)) {
  calibFires <- sort(unique(as.character(summaryABSK_AllData[holdout == FALSE, FIRE_NAME])))
  set.seed(modelCfg$seed)
  foldTab <- data.table(FIRE_NAME = calibFires,
                        foldID = sample(rep_len(seq_len(modelCfg$nFolds), length(calibFires))))
  summaryABSK_AllData[, FIRE_NAME := as.character(FIRE_NAME)]
  summaryABSK_AllData[foldTab, on = "FIRE_NAME", foldID := i.foldID]
  summaryABSK_AllData[, FIRE_NAME := as.factor(FIRE_NAME)]
  rm(calibFires, foldTab)
}
