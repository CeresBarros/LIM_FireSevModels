## ---------------------------------
## DAVID ANDISON FIRE DATA
##
## Dataprep for Exploratory analysis
## ---------------------------------

## using - as of January 14th, 2019
# loading reproducible     0.2.5.9009
# devtools::install_github("PredictiveEcology/reproducible@development")

## requires
# library(factoextra)
# library(reshape2)
# library(vegan)
# library(SpaDES)
# library(sf)
# library(ggplot2)
# library(data.table)
# library(dplyr)
# library(xlsx)
# library(foreign)
# library(fasterize)
# library(velox)
source("R/R_tools/Useful_functions.R")
source("R/R_tools/CASFRIrelated_functions.R")
source("R/R_tools/prepFireWeather.R")
source("R/R_tools/joinSevVegTopoWeatherData.R")

## define paths
# setPaths(cachePath = file.path("R/SpaDES/cache"),
#          modulePath = file.path("R/SpaDES/m"),
#          inputPath = file.path("R/SpaDES/inputs"),
#          outputPath = file.path("R/SpaDES/outputs"))

## -------------------------------------------------
## LOAD DATA ---------------------------------------

## POST-FIRE DATA ----
files = c("albertafires1_postfire", "albertafires2_postfire", "saskatchewanfires_postfire")
# folder = "~/../OneDrive/Documents/LandscapesInMotion/data/fires_Dave/Projected_renamed"
folder = "data/fires_Dave/fireSev"

for(x in files) {
  eval(parse(text = paste0(
    x, " <- st_read(file.path(folder", ", paste0('", x,"', '.shp')))"
  )))
}

## water polygons in AB2 (have FIRE_CODE == 9)
albertafires2_postfire <- albertafires2_postfire[albertafires2_postfire$FIRE_CODE != "9",]

## CHANGE NAMES AND REMOVE UNWANTED VARIABLES
albertafires1_postfire <- renameCleanSfFields(sfObj = albertafires1_postfire, 
                                              namesTable = read.table(file.path(folder, "alberta1Postfire_varCorresp.txt"), header = TRUE))
albertafires2_postfire <- renameCleanSfFields(sfObj = albertafires2_postfire, 
                                              namesTable = read.table(file.path(folder, "alberta2Postfire_varCorresp.txt"), header = TRUE))
saskatchewanfires_postfire <- renameCleanSfFields(sfObj = saskatchewanfires_postfire, 
                                                  namesTable = read.table(file.path(folder, "saskatchewanPostfire_varCorresp.txt"), header = TRUE))

## reorder columns
if (all(setequal(names(albertafires1_postfire), names(albertafires2_postfire)), 
        setequal(names(albertafires1_postfire), names(saskatchewanfires_postfire)))) {
  albertafires2_postfire <- albertafires2_postfire[, names(albertafires1_postfire)]
  saskatchewanfires_postfire <- saskatchewanfires_postfire[, names(albertafires1_postfire)]
} else stop("column names differ")

## uniformize column classes between sf objs
varInfo <- data.frame(name = names(st_set_geometry(albertafires1_postfire, NULL)), 
                      class = sapply(st_set_geometry(albertafires1_postfire, NULL), class),
                      stringsAsFactors = FALSE)
funs <- paste0("as.", varInfo$class)

## didn't manage to do all vars at the same time..
for(j in 1:nrow(varInfo)) {
  albertafires2_postfire[, varInfo$name[j]] <- sapply(albertafires2_postfire[, varInfo$name[j], drop = TRUE],
                                                      funs[[j]])
  saskatchewanfires_postfire[, varInfo$name[j]] <- sapply(saskatchewanfires_postfire[, varInfo$name[j], drop = TRUE],
                                                          funs[[j]])
}


## convert alberta1 classes (% survival) to match alberta2 and saskatchewan (mortality classes)
## and create a continuous severity variable in % mortality
albertafires1_postfire$SEV_CLASS <- as.character(albertafires1_postfire$SEV_CLASS)
albertafires1_postfire$SEV_CLASS[albertafires1_postfire$SEV_CLASS == "100%"] <- "0"
albertafires1_postfire$SEV_CLASS[albertafires1_postfire$SEV_CLASS == "75-99%"] <- "1"
albertafires1_postfire$SEV_CLASS[albertafires1_postfire$SEV_CLASS == "50-74%"] <- "2"
albertafires1_postfire$SEV_CLASS[albertafires1_postfire$SEV_CLASS == "25-49%"] <- "3"
albertafires1_postfire$SEV_CLASS[albertafires1_postfire$SEV_CLASS == "6-24%"] <- "4"
albertafires1_postfire$SEV_CLASS[albertafires1_postfire$SEV_CLASS == "0-5%"] <- "5"
albertafires1_postfire$SEV_CLASS <- as.numeric(albertafires1_postfire$SEV_CLASS)
albertafires1_postfire$SEV_CONT[albertafires1_postfire$SEV_CLASS == 0] <- 0
albertafires1_postfire$SEV_CONT[albertafires1_postfire$SEV_CLASS == 1] <- median(c(1,25))
albertafires1_postfire$SEV_CONT[albertafires1_postfire$SEV_CLASS == 2] <- median(c(26,50))
albertafires1_postfire$SEV_CONT[albertafires1_postfire$SEV_CLASS == 3] <- median(c(51,75))
albertafires1_postfire$SEV_CONT[albertafires1_postfire$SEV_CLASS == 4] <- median(c(76,94))
albertafires1_postfire$SEV_CONT[albertafires1_postfire$SEV_CLASS == 5] <- median(c(95,100))


albertafires2_postfire$SEV_CLASS <- as.numeric(as.character(albertafires2_postfire$SEV_CLASS))
albertafires2_postfire$SEV_CONT[albertafires2_postfire$SEV_CLASS == 0] <- 0
albertafires2_postfire$SEV_CONT[albertafires2_postfire$SEV_CLASS == 1] <- median(c(1,25))
albertafires2_postfire$SEV_CONT[albertafires2_postfire$SEV_CLASS == 2] <- median(c(26,50))
albertafires2_postfire$SEV_CONT[albertafires2_postfire$SEV_CLASS == 3] <- median(c(51,75))
albertafires2_postfire$SEV_CONT[albertafires2_postfire$SEV_CLASS == 4] <- median(c(76,94))
albertafires2_postfire$SEV_CONT[albertafires2_postfire$SEV_CLASS == 5] <- median(c(95,100))

saskatchewanfires_postfire$SEV_CLASS <- as.numeric(as.character(saskatchewanfires_postfire$SEV_CLASS))
saskatchewanfires_postfire$SEV_CONT[saskatchewanfires_postfire$SEV_CLASS == 0] <- 0
saskatchewanfires_postfire$SEV_CONT[saskatchewanfires_postfire$SEV_CLASS == 1] <- median(c(1,25))
saskatchewanfires_postfire$SEV_CONT[saskatchewanfires_postfire$SEV_CLASS == 2] <- median(c(26,50))
saskatchewanfires_postfire$SEV_CONT[saskatchewanfires_postfire$SEV_CLASS == 3] <- median(c(51,75))
saskatchewanfires_postfire$SEV_CONT[saskatchewanfires_postfire$SEV_CLASS == 4] <- median(c(76,94))
saskatchewanfires_postfire$SEV_CONT[saskatchewanfires_postfire$SEV_CLASS == 5] <- median(c(95,100))

albertafires1_postfire$Province <- "AB"
albertafires2_postfire$Province <- "AB"
saskatchewanfires_postfire$Province <- "SK"

## correction of fire years and convert to numeric
## see data/fires_Dave/all129-overview.xls

albertafires2_postfire$FIRE_YEAR <- as.character(albertafires2_postfire$FIRE_YEAR)
saskatchewanfires_postfire$FIRE_YEAR <- as.character(saskatchewanfires_postfire$FIRE_YEAR)

## LETTER Y fire
albertafires2_postfire$FIRE_YEAR <- sub("<1953", "1953", albertafires2_postfire$FIRE_YEAR)

## MEIKLE fire
albertafires2_postfire$FIRE_YEAR <- sub("195X", "1952", albertafires2_postfire$FIRE_YEAR)

## HALVERSON fire
albertafires2_postfire$FIRE_YEAR <- sub("194X", "1945", albertafires2_postfire$FIRE_YEAR)

## Alfred fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Alfred"] <- "1981"

## Brett fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Brett"] <- "1977"

## Carlton fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Carlton"] <- "1980"

## Dillon Lake fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Dillon Lake"] <- "1977"

## Elk fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Elk"] <- "1983"

## Harry Lake fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Harry Lake"] <- "1980"

## McArther fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "McArther"] <- "1984"

## Rail fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Rail"] <- "1984"

## Rainbow fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Rainbow"] <- "1986"

## Sixty fire
saskatchewanfires_postfire$FIRE_YEAR[saskatchewanfires_postfire$FIRE_NAME == "Sixty"] <- "1981"

albertafires1_postfire$FIRE_YEAR <- as.numeric(as.character(albertafires1_postfire$FIRE_YEAR))
albertafires2_postfire$FIRE_YEAR <- as.numeric(as.character(albertafires2_postfire$FIRE_YEAR))
saskatchewanfires_postfire$FIRE_YEAR <- as.numeric(as.character(saskatchewanfires_postfire$FIRE_YEAR))

## DEFINE FIRE EVENTS ----
firesABSK <- rbind(albertafires1_postfire, albertafires2_postfire, saskatchewanfires_postfire)

## Use Alberta 1 post fire data only for now, as severity classes on other datasets and not yet comparable.
ABSK_fireEvents <- reproducible::Cache(defineFireEvents, 
                                       sfObj = firesABSK, fireNAMES = "FIRE_NAME",
                                       # fireVARS = c("FIRE_ID", "FIRE_YEAR", "SEV_CLASS"),   ## this makes the output object huge
                                       buff.dist = 200L, 
                                       PLOT = FALSE, SAVE = FALSE, outputDIR = "analyses/FireEvents", 
                                       fileNAME = "Andison_ABSK_fireEvents", overwrite = TRUE,
                                       cacheRepo = "analyses/cache", userTags = "dataTreat_fireEvents",
                                       omitArgs = c("PLOT", "SAVE", "outputDIR", "fileNAME", "overwrite"),
                                       useCache = doCache)


## ADD SEVERITY IN DISTURBED PATCHES
## using a left join that will add severity polys within the disturbed patch (all should be added)
## (doing it in defineFireEvents seems to produce an overly large polygon)
ABSK_fireEvents.dt <- data.table(st_set_geometry(ABSK_fireEvents, NULL))
firesABSK.dt <- data.table(st_set_geometry(firesABSK, NULL))
firesABSK.dt$P_ID <- 1:nrow(firesABSK.dt)  ## keep track of row order to add geometries later

ABSK_distPatchSev.dt <- firesABSK.dt[ABSK_fireEvents.dt[PatchType == "disturbedPatch",], on = "FIRE_NAME"]
ABSK_distPatchSev.dt <- ABSK_distPatchSev.dt[order(P_ID)]

ABSK_fireEventsSev <- st_set_geometry(ABSK_distPatchSev.dt, st_geometry(firesABSK))

## PRE-FIRE VEGETATION DATA ----
files = c("albertafires1_prefire", "albertafires2_prefire", "saskatchewanfires_prefire")
folder = "data/fires_Dave/prefireVeg"

for(x in files) {
  eval(parse(text = paste0(
    x, " <- st_read(file.path(folder", ", paste0('", x,"', '.shp')))"
  )))
}

## add a polygon ID column for each dataset
## IDs in the data cannot be trusted as they are repeated/missing across polygons with different data.
albertafires1_prefire$P_ID <- 1:nrow(albertafires1_prefire[,, drop = TRUE])
albertafires2_prefire$P_ID <- 1:nrow(albertafires2_prefire[,, drop = TRUE])
saskatchewanfires_prefire$P_ID <- 1:nrow(saskatchewanfires_prefire[,, drop = TRUE])

## MELT CHANGE NAMES AND REMOVE UNWANTED VARIABLES
## Alberta - melting comes after renaming
albertafires1_prefire <- renameCleanSfFields(sfObj = albertafires1_prefire, 
                                             namesTable = read.table("data/VegInventories/alberta1Prefire_AVI_varCorresp.txt", header = TRUE))
albertafires2_prefire <- renameCleanSfFields(sfObj = albertafires2_prefire, 
                                             namesTable = read.table("data/VegInventories/alberta2Prefire_AVI_varCorresp.txt", header = TRUE))

ABinvs <- grep("alberta.*_prefire$", ls(), value = TRUE)

allVars <- c("ANTH_NON", "ANTH_VEG", "DATA", "DATA_YR", 
             "DENSITY", "HEIGHT", "INITIALS", "MOD1", 
             "MOD1_EXT", "MOD1_YR", "MOD2", "MOD2_EXT", 
             "MOD2_YR", "MOIST_REG", "NAT_NON", "NFL_PER",
             "NFL", "ORIGIN", "SP1_PER", "SP1", "SP2_PER",
             "SP2", "SP3_PER", "SP3", "SP4_PER", "SP4", 
             "SP5_PER", "SP5", "STRUC", "STRUC_VAL", "TPR")
allVars <- c(allVars, paste0("U", allVars))

albertafires1_prefireMelt <- reproducible::Cache(meltPreFireABInv,
                                                 inv = "albertafires1_prefire",
                                                 allVars = allVars,
                                                 folder = folder,
                                                 cacheRepo = "analyses/cache",
                                                 userTags = "meltABprefire_1",
                                                 useCache = doCache)

albertafires2_prefireMelt <- reproducible::Cache(meltPreFireABInv,
                                                 inv = "albertafires2_prefire",
                                                 allVars = allVars,
                                                 folder = folder,
                                                 cacheRepo = "analyses/cache",
                                                 userTags = "meltABprefire_2",
                                                 useCache = doCache)

## Saskatchewan - melting has to come before renaming
## note: for SK these names are not the same as the names accepted by CASFRI, 
##    because CASFRI is not using the "official" field names
saskatchewanfires_prefireMelt <- reproducible::Cache(meltPreFireSKInv,
                                                     inv = "saskatchewanfires_prefire",
                                                     folder = folder,
                                                     cacheRepo = "analyses/cache",
                                                     userTags = "meltSKprefire",
                                                     useCache = doCache)

saskatchewanfires_prefireMelt <- renameCleanSfFields(sfObj = saskatchewanfires_prefireMelt, 
                                                     namesTable = read.table("data/VegInventories/saskatchewanPrefire_SFVI_varCorresp.txt", header = TRUE))

## AVI AND SFVI TO CASFRI
tablesDir <- "data/VegInventories/CASFRIConvTables.xlsx"
albertafires1_prefireMeltCASFRI <- reproducible::Cache(ABToCASFRI, 
                                                       inv = "albertafires1_prefireMelt",
                                                       tablesDir = tablesDir,
                                                       folder = folder,
                                                       cacheRepo = "analyses/cache",
                                                       userTags = "AB2CASFRI_1",
                                                       useCache = doCache)

albertafires2_prefireMeltCASFRI <- reproducible::Cache(ABToCASFRI, 
                                                       inv = "albertafires2_prefireMelt",
                                                       tablesDir = tablesDir,
                                                       folder = folder,
                                                       cacheRepo = "analyses/cache",
                                                       userTags = "AB2CASFRI_2",
                                                       useCache = doCache)

saskatchewanfires_prefireMeltCASFRI <- reproducible::Cache(SKToCASFRI, 
                                                           inv = "saskatchewanfires_prefireMelt",
                                                           tablesDir = tablesDir,
                                                           folder = folder,
                                                           cacheRepo = "analyses/cache",
                                                           userTags = "SK2CASFRI_1",
                                                           useCache = doCache)



## rbind pre-fire data
setcolorder(albertafires2_prefireMeltCASFRI, names(albertafires1_prefireMeltCASFRI))
setcolorder(saskatchewanfires_prefireMeltCASFRI, names(albertafires1_prefireMeltCASFRI))

allPrefireCASFRI <- rbind(albertafires1_prefireMeltCASFRI, albertafires2_prefireMeltCASFRI,
                          saskatchewanfires_prefireMeltCASFRI)
allPrefireCASFRI$P_ID <- NULL

## WATER DATA ----
# files = c("water-abta", "water-sask")
# folder = "data/fires_Dave/Projected_renamed"
# 
# for(x in files) {
#   eval(parse(text = paste0(
#     sub("-", "_", x), " <- st_read(file.path(folder", ", paste0('", x,"', '.shp')))"
#   )))
# }


## TOPO DATA ----
## data used in Ferster et al 2016, see ~/Colin_forestsMDPI/DEM/topo_names.R
## using .shp instead of dbf, so that an intersection can be made with pre and post fire data
files = c("alta24.shp", "alta77_revise.shp", "sask29.shp")
folder = "data/fires_Dave/DEM/Grid30Intersect"   

DEMList <- lapply(file.path(folder, files), st_read)
names(DEMList) <- sub(".shp", "", files)

## change column names (see ~/Colin_forestsMDPI/DEM/topo_names.R)
colNames <- c("gridID", "Aspect",
              "CTI", "Curv", "PctSlope",
              "SCOS", "DegSlope", "SlopePosition",
              "Elevation", "SSIN", "SurfAspectRatio",
              "SurfReliefRatio", "TRASP")

DEMList <- lapply(DEMList, FUN = function(shp, colNames) {
  ## one of the datasets contains fire names
  if (any(grepl("alta77", names(shp))))
    colNames <- c("fireName", colNames)
  
  names(shp) <- c(colNames, "geometry")
  
  ## remove fireName column, should it exist
  if (any(names(shp) == "fireName"))
    shp$fireName <- NULL
  
  shp
}, colNames = colNames)

## bind
DEM <- do.call(rbind, DEMList)  ## need do.call to deal with
DEM <- st_transform(DEM, st_crs(ABSK_fireEventsSev))

## WEATHER DATA ----------
fireWeatherLs <- reproducible::Cache(prepFireWeather,
                                     folder = "data/fires_Dave/fireWeather",
                                     userTags = "fireWeatherLs",
                                     cacheRepo = "analyses/cache",
                                     useCache = doCache)

## ECOREGIONS TABLE -------
fireEcoregions <- read.xlsx("data/fires_Dave/all129-overview.xls", sheetName = "all") %>%
  data.table(.)

## remove unnecesary columns
cols <- grep("Unma|zone|NR", names(fireEcoregions), value = TRUE)
fireEcoregions <- fireEcoregions[, ..cols]

setnames(fireEcoregions, "Unmae", "FIRE_NAME")

## remove repeated fires
fireEcoregions[, FIRE_NAME := toupper(FIRE_NAME)]
fireEcoregions[FIRE_NAME != "CONTEST #2", FIRE_NAME := gsub("[[:digit::]]", "", FIRE_NAME)]

fireEcoregions <- unique(fireEcoregions)

## Change Alfred to Alfred Lake
fireEcoregions[FIRE_NAME == "ALFRED", FIRE_NAME := "ALFRED LAKE"]

## -------------------------------------------------
## JOIN DATA ---------------------------------------
## clean-up before joining
rm(list = c("ABinvs", "allVars", "files", "folder", "funs", 
            "varInfo", "j", "tablesDir", "x", "colNames", "ABSK_fireEvents", 
            "ABSK_fireEvents.dt",
            grep("firesABSK|DEMList|ABSK_distPatchSev|postfire|prefire|alberta|saskatchewan", 
                 ls(), value = TRUE)))
amc::.gc()

ABSK_AllData <- Cache(joinSevVegTopoWeatherData,
                                    sevDataSf = ABSK_fireEventsSev, 
                                    vegDataSf = allPrefireCASFRI, 
                                    topoDataSf = DEM, 
                                    weatherDataDt = copy(fireWeatherLs$fireWeather),
                                    saveDir = "analyses/fireDataJoins",
                                    doAll = bindAllFires,
                                    userTags = "ABSK_AllData",
                                    cacheRepo = "analyses/cache",
                                    useCache = doCache)

## clean-up
rm(list = c("fireWeatherLs", "allPrefireCASFRI", grep("DEM|ABSK_fireEvents", 
                 ls(), value = TRUE)))
amc::.gc()

## make sure some Veg. data classes are correct
cols <- c("CROWN_CLOSURE_LOWER", "CROWN_CLOSURE_UPPER",
          "DIST1_EXTENT_LOWER", "DIST1_EXTENT_UPPER",
          "DIST2_EXTENT_LOWER", "DIST2_EXTENT_UPPER",
          "LAYER", "LAYER_RANK", "STAND_STRUCTURE_PER",
          "HEIGHT", "HEIGHT",
          "SPEC._PER", "ORIGIN")
cols <- grep(paste(cols, collapse = "|"), names(ABSK_AllData),
             value = TRUE)

myAsNumeric <- function(x) as.numeric(as.character(x))
ABSK_AllData[, (cols) := lapply(.SD, myAsNumeric), .SDcols = cols]


## join ecoregions
fireEcoregions[, FIRE_NAME := toupper(FIRE_NAME)]

setdiff(unique(ABSK_AllData$FIRE_NAME), fireEcoregions$FIRE_NAME)
