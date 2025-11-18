## ---------------------------------
## DAVID ANDISON FIRE DATA
##
## Dataprep function for statiscal analyses
## ---------------------------------

## resolution is passed to joinSevVegTopoWeatherData
## doCache controls all caching
## bindAllFires controls whether all fire data binding should be repeated

ABSKfires_DataPrep <- function(
  fireDataPath = "data/fires_Dave/fireSev",
  vegDataPath = "data/fires_Dave/prefireVeg",
  topoDataPath = "data/fires_Dave/DEM/Grid30Intersect",
  weatherDataPath = "data/fires_Dave/fireWeather",
  resolution = 20,
  doCache = TRUE,
  bindAllFires = FALSE
) {
  ## checks
  if (
    is.null(fireDataPath) |
      is.null(vegDataPath) |
      is.null(weatherDataPath) |
      is.null(topoDataPath)
  ) {
    stop(
      "Missing one of fireDataPath, vegDataPath, weatherDataPath, topoDataPath"
    )
  }

  ## -------------------------------------------------
  ## LOAD DATA ---------------------------------------

  ## POST-FIRE DATA ----
  firesABSK <- Cache(
    cleanAndBindFireData,
    files = c(
      "albertafires1_postfire",
      "albertafires2_postfire",
      "saskatchewanfires_postfire"
    ),
    fireDataPath = fireDataPath,
    cachePath = "analyses/cache",
    userTags = "allFireData",
    useCache = doCache,
    cacheId = "c4116973045eb9a3"  ## fix
  )

  ## DEFINE FIRE EVENTS ----
  ## Use Alberta 1 post fire data only for now, as severity classes on other datasets and not yet comparable.
  ABSK_fireEvents <- Cache(
    defineFireEvents,
    sfObj = firesABSK,
    fireNAMES = "FIRE_NAME",
    # fireVARS = c("FIRE_ID", "FIRE_YEAR", "SEV_CLASS"),   ## this makes the output object huge
    buff.dist = 200L,
    PLOT = FALSE,
    SAVE = FALSE,
    outputDIR = "analyses/FireEvents",
    fileNAME = "Andison_ABSK_fireEvents",
    overwrite = TRUE,
    cachePath = "analyses/cache",
    userTags = "dataTreat_fireEvents",
    omitArgs = c("PLOT", "SAVE", "outputDIR", "fileNAME", "overwrite"),
    useCache = doCache,
    cacheId = "7e545707ee8b59d1"
  )

  ## remove empty geometries (e.g. if nor inner residuals exist, empty geometries are produced)
  ABSK_fireEvents <- ABSK_fireEvents[!is.na(st_dimension(ABSK_fireEvents)), ]

  ## validategeometries if need be
  ABSK_fireEvents <- Cache(
    validateGeomsSf,
    sfObj = ABSK_fireEvents,
    dim = dim(ABSK_fireEvents),
    cachePath = "analyses/cache",
    userTags = "validABSK_fireEvents",
    omitArgs = c("sfObj"),
    useCache = doCache,
    cacheId = "04dacf18dd7e1a81"
  )

  ## ADD SEVERITY IN DISTURBED PATCHES
  ## using a left join that will add severity polys within the disturbed patch (all should be added)
  ## (doing it in defineFireEvents seems to produce an overly large polygon)
  ABSK_fireEvents.dt <- data.table(st_set_geometry(ABSK_fireEvents, NULL))
  firesABSK.dt <- data.table(st_set_geometry(firesABSK, NULL))
  firesABSK.dt$P_ID <- 1:nrow(firesABSK.dt) ## keep track of row order to add geometries later

  ABSK_distPatchSev.dt <- firesABSK.dt[
    ABSK_fireEvents.dt[PatchType == "disturbedPatch", ],
    on = "FIRE_NAME"
  ]
  ABSK_distPatchSev.dt <- ABSK_distPatchSev.dt[order(P_ID)]
  ABSK_fireEventsSev <- st_set_geometry(
    ABSK_distPatchSev.dt,
    st_geometry(firesABSK)
  )

  ## add residuals
  ABSK_fireEventsSev.dt <- data.table(st_set_geometry(ABSK_fireEventsSev, NULL))
  ABSK_fireEventsResids.dt <- as.data.table(ABSK_fireEvents[
    grepl("Resids", ABSK_fireEvents$PatchType),
  ])

  ## add missing columns to resids and set severity to 0
  setkey(ABSK_fireEventsSev.dt, FIRE_NAME)
  setkey(ABSK_fireEventsResids.dt, FIRE_NAME)
  ABSK_fireEventsResids.dt <- unique(ABSK_fireEventsSev.dt[, .(
    FIRE_NAME,
    FIRE_YEAR,
    Province
  )])[ABSK_fireEventsResids.dt]
  ABSK_fireEventsResids.dt[, `:=`(SEV_CLASS = 0, SEV_CONT = 0)]

  ## match column names (P_IDs will be updated)
  ABSK_fireEventsSev$P_ID <- NULL
  setcolorder(ABSK_fireEventsResids.dt, names(ABSK_fireEventsSev))

  ## make sf object, convert any multipolygon to a polygon and bind
  ABSK_fireEventsResids <- st_as_sf(ABSK_fireEventsResids.dt)
  ABSK_fireEventsSev <- st_cast(ABSK_fireEventsSev, "MULTIPOLYGON") %>%
    st_cast("POLYGON")
  ABSK_fireEventsResids <- st_cast(ABSK_fireEventsResids, "MULTIPOLYGON") %>%
    st_cast("POLYGON")

  ABSK_fireEventsSev <- rbind(ABSK_fireEventsSev, ABSK_fireEventsResids)

  ## PRE-FIRE VEGETATION DATA ----
  files = c(
    "albertafires1_prefire",
    "albertafires2_prefire",
    "saskatchewanfires_prefire"
  )

  for (x in files) {
    suppressWarnings(
      eval(parse(
        text = paste0(
          x,
          " <- st_read(file.path(vegDataPath",
          ", paste0('",
          x,
          "', '.shp')))"
        )
      ))
    )
  }

  ## add a polygon ID column for each dataset
  ## IDs in the data cannot be trusted as they are repeated/missing across polygons with different data.
  albertafires1_prefire$P_ID <- 1:nrow(albertafires1_prefire[,, drop = TRUE])
  albertafires2_prefire$P_ID <- 1:nrow(albertafires2_prefire[,, drop = TRUE])
  saskatchewanfires_prefire$P_ID <- 1:nrow(saskatchewanfires_prefire[,,
    drop = TRUE
  ])

  ## MELT CHANGE NAMES AND REMOVE UNWANTED VARIABLES
  ## Alberta - melting comes after renaming
  albertafires1_prefire <- renameCleanSfFields(
    sfObj = albertafires1_prefire,
    namesTable = read.table(
      "data/VegInventories/alberta1Prefire_AVI_varCorresp.txt",
      header = TRUE
    )
  )
  albertafires2_prefire <- renameCleanSfFields(
    sfObj = albertafires2_prefire,
    namesTable = read.table(
      "data/VegInventories/alberta2Prefire_AVI_varCorresp.txt",
      header = TRUE
    )
  )

  ABinvs <- grep("alberta.*_prefire$", ls(), value = TRUE)

  allVars <- c(
    "ANTH_NON",
    "ANTH_VEG",
    "DATA",
    "DATA_YR",
    "DENSITY",
    "HEIGHT",
    "INITIALS",
    "MOD1",
    "MOD1_EXT",
    "MOD1_YR",
    "MOD2",
    "MOD2_EXT",
    "MOD2_YR",
    "MOIST_REG",
    "NAT_NON",
    "NFL_PER",
    "NFL",
    "ORIGIN",
    "SP1_PER",
    "SP1",
    "SP2_PER",
    "SP2",
    "SP3_PER",
    "SP3",
    "SP4_PER",
    "SP4",
    "SP5_PER",
    "SP5",
    "STRUC",
    "STRUC_VAL",
    "TPR"
  )
  allVars <- c(allVars, paste0("U", allVars))

  albertafires1_prefireMelt <- Cache(
    meltPreFireABInv,
    inv = albertafires1_prefire,
    invName = "albertafires1_prefire",
    allVars = allVars,
    folder = vegDataPath,
    dim = dim(albertafires1_prefire),
    cachePath = "analyses/cache",
    userTags = "meltABprefire_1",
    useCache = doCache,
    omitArgs = c("inv"),
    cacheId = "9c5a574825977426"
  )

  albertafires2_prefireMelt <- Cache(
    meltPreFireABInv,
    inv = albertafires2_prefire,
    invName = "albertafires2_prefire",
    allVars = allVars,
    folder = vegDataPath,
    dim = dim(albertafires2_prefire),
    cachePath = "analyses/cache",
    userTags = "meltABprefire_2",
    useCache = doCache,
    omitArgs = c("inv"),
    cacheId = "38ec7804ab5af5ec"
  )

  ## Saskatchewan - melting has to come before renaming
  ## note: for SK these names are not the same as the names accepted by CASFRI,
  ##    because CASFRI is not using the "official" field names
  saskatchewanfires_prefireMelt <- Cache(
    meltPreFireSKInv,
    inv = saskatchewanfires_prefire,
    invName = "saskatchewanfires_prefire",
    folder = vegDataPath,
    dim = dim(saskatchewanfires_prefire),
    cachePath = "analyses/cache",
    userTags = "meltSKprefire",
    useCache = doCache,
    omitArgs = c("inv"),
    cacheId = "d9d251e366c19495"
  )

  saskatchewanfires_prefireMelt <- renameCleanSfFields(
    sfObj = saskatchewanfires_prefireMelt,
    namesTable = read.table(
      "data/VegInventories/saskatchewanPrefire_SFVI_varCorresp.txt",
      header = TRUE
    )
  )
  ## TROUBLESHOOTING SK INVENTORY DATA MISMATCHES
  ## TYPE, CSG and PFT columns are a mess
  ## CSG an PFT  columns have classes that belong to TYPE and NA's do not match
  ## AQUATIC_CLASS also has info not contained in TYPE
  ## NVSL/LUC have no info and there is no Non Productive column (which CASFRI uses).
  ## TYPE can be used instead of Non Productive for most things, but NVSL should have water info
  tempDT <- as.data.table(as.data.frame(saskatchewanfires_prefireMelt))
  cols <- c("TYPE", "CSG", "PFT")
  tempDT <- tempDT[, (cols) := lapply(.SD, as.character), .SDcols = cols]

  ## add watter class where missing
  tempDT[,
    TYPE := addWaterInfo(AQUATIC_CLASS, TYPE, CSG, PFT),
    by = 1:nrow(tempDT)
  ]
  tempDT[TYPE %in% "WAT", NVSL := "WA"]

  ## note that one polyogn has TYPE/CSG/PFT = NFA (after checking AQUATIC info) and no veg info - will have to be ignored
  tempDT[,
    c("TYPE", "CSG", "PFT") := correctCSGPFTTYPE(
      LAYER,
      TYPE,
      CSG,
      PFT,
      SP1_COVER,
      SMR
    ),
    by = P_ID
  ]

  ## back to sf object
  saskatchewanfires_prefireMelt <- st_as_sf(as.data.frame(tempDT))
  rm(tempDT, cols)
  amc::.gc()

  ## AVI AND SFVI TO CASFRI
  tablesDir <- "data/VegInventories/CASFRIConvTables.xlsx"
  albertafires1_prefireMeltCASFRI <- Cache(
    ABToCASFRI,
    inv = albertafires1_prefireMelt,
    tablesDir = tablesDir,
    folder = vegDataPath,
    dim = dim(albertafires1_prefireMelt),
    cachePath = "analyses/cache",
    userTags = "AB2CASFRI_1",
    useCache = doCache,
    omitArgs = c("inv"),
    cacheId = "123e9d763b358be2"
  )

  albertafires2_prefireMeltCASFRI <- Cache(
    ABToCASFRI,
    inv = albertafires2_prefireMelt,
    tablesDir = tablesDir,
    folder = vegDataPath,
    dim = dim(albertafires2_prefireMelt),
    cachePath = "analyses/cache",
    userTags = "AB2CASFRI_2",
    useCache = doCache,
    omitArgs = c("inv"),
    cacheId = "45abfe5b31780ae2"
  )

  saskatchewanfires_prefireMeltCASFRI <- Cache(
    SKToCASFRI,
    inv = saskatchewanfires_prefireMelt,
    tablesDir = tablesDir,
    folder = vegDataPath,
    dim = dim(saskatchewanfires_prefireMelt),
    cachePath = "analyses/cache",
    userTags = "SK2CASFRI_1",
    useCache = doCache,
    omitArgs = c("inv"),
    cacheId = "5e9530011e422b42"
  )
  ## change LA (lakes) to  water, since Dave'S data is not clear about the type of water bodies in SK
  saskatchewanfires_prefireMeltCASFRI$NATURALLY_NON_VEG[
    saskatchewanfires_prefireMeltCASFRI$NATURALLY_NON_VEG %in% "LA"
  ] <- "WA"

  ## rbind pre-fire data
  setcolorder(
    albertafires2_prefireMeltCASFRI,
    names(albertafires1_prefireMeltCASFRI)
  )
  setcolorder(
    saskatchewanfires_prefireMeltCASFRI,
    names(albertafires1_prefireMeltCASFRI)
  )

  allPrefireCASFRI <- rbind(
    albertafires1_prefireMeltCASFRI,
    albertafires2_prefireMeltCASFRI,
    saskatchewanfires_prefireMeltCASFRI
  )
  ## re-do polygon IDs
  allPrefireCASFRI$P_ID <- 1:nrow(allPrefireCASFRI[,, drop = TRUE])

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

  DEMList <- suppressWarnings(
    lapply(file.path(topoDataPath, files), st_read)
  )
  names(DEMList) <- sub(".shp", "", files)

  ## change column names (see ~/Colin_forestsMDPI/DEM/topo_names.R)
  colNames <- c(
    "gridID",
    "Aspect",
    "CTI",
    "Curv",
    "PctSlope",
    "SCOS",
    "DegSlope",
    "SlopePosition",
    "Elevation",
    "SSIN",
    "SurfAspectRatio",
    "SurfReliefRatio",
    "TRASP"
  )

  DEMList <- lapply(
    DEMList,
    FUN = function(shp, colNames) {
      ## one of the datasets contains fire names
      if (any(grepl("alta77", names(shp)))) {
        colNames <- c("fireName", colNames)
      }

      names(shp) <- c(colNames, "geometry")

      ## remove fireName column, should it exist
      if (any(names(shp) == "fireName")) {
        shp$fireName <- NULL
      }

      shp
    },
    colNames = colNames
  )

  ## bind
  DEM <- do.call(rbind, DEMList) ## need do.call to deal with
  DEM <- st_transform(DEM, st_crs(ABSK_fireEventsSev))

  ## WEATHER DATA ----------
  fireWeatherLs <- Cache(
    prepFireWeather,
    folder = weatherDataPath,
    userTags = "fireWeatherLs",
    cachePath = "analyses/cache",
    useCache = doCache,
    cacheId = "b7e137c08bde718e"
  )

  ## ECOREGIONS TABLE -------
  fireEcoregions <- read.xlsx(
    "data/fires_Dave/all129-overview.xls",
    sheetName = "all"
  ) %>%
    data.table(.)

  ## remove unnecesary columns
  cols <- grep("Unma|zone|NR", names(fireEcoregions), value = TRUE)
  fireEcoregions <- fireEcoregions[, ..cols]

  setnames(fireEcoregions, "Unmae", "FIRE_NAME")

  ## remove repeated fires
  fireEcoregions[, FIRE_NAME := toupper(FIRE_NAME)]
  fireEcoregions[
    FIRE_NAME != "CONTEST #2",
    FIRE_NAME := gsub("[[:digit::]]", "", FIRE_NAME)
  ]

  fireEcoregions <- unique(fireEcoregions)

  ## Change Alfred to Alfred Lake
  fireEcoregions[FIRE_NAME == "ALFRED", FIRE_NAME := "ALFRED LAKE"]

  ## Remove empty fire names and convert to uppercase
  fireEcoregions <- fireEcoregions[!is.na(FIRE_NAME)]
  fireEcoregions[, FIRE_NAME := toupper(FIRE_NAME)]

  ## correct ecoregions:
  ## Livock fire says "Foothills" in NR2, but Boreal Forest in NR1, I will put foothills on NR1
  ## Little Smoky and Gregg River fires have Czone1 as B. Plais, but Montane Cordillera  for Czone2 and Foothills in either NR1 or NR2, I will put M. Cordillera in Czone1
  fireEcoregions[
    NR2 == "Foothills" & !grepl("Rocky|Foothills", NR1),
    NR1 := "Foothills"
  ]
  fireEcoregions[
    grepl("Boreal", Czone1) & grepl("Montane", Czone2),
    Czone1 := Czone2
  ]

  ## drop columns that are no longer necessary (and only confuse things!)
  fireEcoregions[, Czone2 := NULL]
  fireEcoregions[, NR2 := NULL]

  ## -------------------------------------------------
  ## JOIN DATA ---------------------------------------
  ## clean-up before joining
  rm(
    list = c(
      "ABinvs",
      "allVars",
      "files",
      "funs",
      "varInfo",
      "j",
      "tablesDir",
      "x",
      "colNames",
      "ABSK_fireEvents",
      "ABSK_fireEvents.dt",
      grep(
        "firesABSK|DEMList|ABSK_distPatchSev|postfire|prefire|alberta|saskatchewan",
        ls(),
        value = TRUE
      )
    )
  )
  amc::.gc()

  pathToSaveDir <- file.path(
    "analyses/fireDataJoins",
    paste0("res", resolution, "m")
  )
  ABSK_AllData <- Cache(
    joinSevVegTopoWeatherData,
    sevDataSf = ABSK_fireEventsSev,
    vegDataSf = allPrefireCASFRI,
    topoDataSf = DEM,
    weatherDataDt = copy(fireWeatherLs$fireWeather),
    resolution = resolution,
    saveDir = pathToSaveDir,
    doAll = bindAllFires,
    userTags = "ABSK_AllData",
    cachePath = "analyses/cache",
    useCache = doCache,
    cacheId = "33fc46a9f209968a"
  )

  ## clean-up
  rm(
    list = c(
      "fireWeatherLs",
      "allPrefireCASFRI",
      grep("DEM|ABSK_fireEvents", ls(), value = TRUE)
    )
  )
  amc::.gc()

  ## make sure some Veg. data classes are the correct type
  cols <- c(
    "CROWN_CLOSURE_LOWER",
    "CROWN_CLOSURE_UPPER",
    "DIST1_EXTENT_LOWER",
    "DIST1_EXTENT_UPPER",
    "DIST2_EXTENT_LOWER",
    "DIST2_EXTENT_UPPER",
    "LAYER",
    "LAYER_RANK",
    "STAND_STRUCTURE_PER",
    "HEIGHT",
    "HEIGHT",
    "SPEC._PER",
    "ORIGIN"
  )
  cols <- grep(paste(cols, collapse = "|"), names(ABSK_AllData), value = TRUE)

  myAsNumeric <- function(x) as.numeric(as.character(x))
  ABSK_AllData[, (cols) := lapply(.SD, myAsNumeric), .SDcols = cols]

  ## join ecoregions
  setkey(fireEcoregions, FIRE_NAME)
  setkey(ABSK_AllData, FIRE_NAME)
  ABSK_AllData <- fireEcoregions[ABSK_AllData]

  ## Clean up and free memory
  rm(fireEcoregions)
  amc::.gc()

  return(ABSK_AllData)
}


cleanAndBindFireData <- function(files, fireDataPath) {
  for (x in files) {
    suppressWarnings(
      eval(parse(
        text = paste0(
          x,
          " <- st_read(file.path(fireDataPath",
          ", paste0('",
          x,
          "', '.shp')))"
        )
      ))
    )
  }

  ## water polygons in AB2 (have FIRE_CODE == 9)
  albertafires2_postfire <- albertafires2_postfire[
    albertafires2_postfire$FIRE_CODE != "9",
  ]

  ## CHANGE NAMES AND REMOVE UNWANTED VARIABLES
  albertafires1_postfire <- renameCleanSfFields(
    sfObj = albertafires1_postfire,
    namesTable = read.table(
      file.path(fireDataPath, "alberta1Postfire_varCorresp.txt"),
      header = TRUE
    )
  )
  albertafires2_postfire <- renameCleanSfFields(
    sfObj = albertafires2_postfire,
    namesTable = read.table(
      file.path(fireDataPath, "alberta2Postfire_varCorresp.txt"),
      header = TRUE
    )
  )
  saskatchewanfires_postfire <- renameCleanSfFields(
    sfObj = saskatchewanfires_postfire,
    namesTable = read.table(
      file.path(fireDataPath, "saskatchewanPostfire_varCorresp.txt"),
      header = TRUE
    )
  )

  ## reorder columns
  if (
    all(
      setequal(names(albertafires1_postfire), names(albertafires2_postfire)),
      setequal(names(albertafires1_postfire), names(saskatchewanfires_postfire))
    )
  ) {
    albertafires2_postfire <- albertafires2_postfire[, names(
      albertafires1_postfire
    )]
    saskatchewanfires_postfire <- saskatchewanfires_postfire[, names(
      albertafires1_postfire
    )]
  } else {
    stop("column names differ")
  }

  ## uniformize column classes between sf objs
  varInfo <- data.frame(
    name = names(st_set_geometry(albertafires1_postfire, NULL)),
    class = sapply(st_set_geometry(albertafires1_postfire, NULL), class),
    stringsAsFactors = FALSE
  )
  funs <- paste0("as.", varInfo$class)

  ## didn't manage to do all vars at the same time..
  for (j in 1:nrow(varInfo)) {
    albertafires2_postfire[, varInfo$name[j]] <- sapply(
      albertafires2_postfire[, varInfo$name[j], drop = TRUE],
      funs[[j]]
    )
    saskatchewanfires_postfire[, varInfo$name[j]] <- sapply(
      saskatchewanfires_postfire[, varInfo$name[j], drop = TRUE],
      funs[[j]]
    )
  }

  ## convert alberta1 classes (% survival) to match alberta2 and saskatchewan (mortality classes)
  ## and create a continuous severity variable in % mortality
  albertafires1_postfire$SEV_CLASS <- as.character(
    albertafires1_postfire$SEV_CLASS
  )
  albertafires1_postfire$SEV_CLASS[
    albertafires1_postfire$SEV_CLASS == "100%"
  ] <- "0"
  albertafires1_postfire$SEV_CLASS[
    albertafires1_postfire$SEV_CLASS == "75-99%"
  ] <- "1"
  albertafires1_postfire$SEV_CLASS[
    albertafires1_postfire$SEV_CLASS == "50-74%"
  ] <- "2"
  albertafires1_postfire$SEV_CLASS[
    albertafires1_postfire$SEV_CLASS == "25-49%"
  ] <- "3"
  albertafires1_postfire$SEV_CLASS[
    albertafires1_postfire$SEV_CLASS == "6-24%"
  ] <- "4"
  albertafires1_postfire$SEV_CLASS[
    albertafires1_postfire$SEV_CLASS == "0-5%"
  ] <- "5"
  albertafires1_postfire$SEV_CLASS <- as.numeric(
    albertafires1_postfire$SEV_CLASS
  )
  albertafires1_postfire$SEV_CONT[albertafires1_postfire$SEV_CLASS == 0] <- 0
  albertafires1_postfire$SEV_CONT[
    albertafires1_postfire$SEV_CLASS == 1
  ] <- median(c(1, 25))
  albertafires1_postfire$SEV_CONT[
    albertafires1_postfire$SEV_CLASS == 2
  ] <- median(c(26, 50))
  albertafires1_postfire$SEV_CONT[
    albertafires1_postfire$SEV_CLASS == 3
  ] <- median(c(51, 75))
  albertafires1_postfire$SEV_CONT[
    albertafires1_postfire$SEV_CLASS == 4
  ] <- median(c(76, 94))
  albertafires1_postfire$SEV_CONT[
    albertafires1_postfire$SEV_CLASS == 5
  ] <- median(c(95, 100))

  albertafires2_postfire$SEV_CLASS <- as.numeric(as.character(
    albertafires2_postfire$SEV_CLASS
  ))
  albertafires2_postfire$SEV_CONT[albertafires2_postfire$SEV_CLASS == 0] <- 0
  albertafires2_postfire$SEV_CONT[
    albertafires2_postfire$SEV_CLASS == 1
  ] <- median(c(1, 25))
  albertafires2_postfire$SEV_CONT[
    albertafires2_postfire$SEV_CLASS == 2
  ] <- median(c(26, 50))
  albertafires2_postfire$SEV_CONT[
    albertafires2_postfire$SEV_CLASS == 3
  ] <- median(c(51, 75))
  albertafires2_postfire$SEV_CONT[
    albertafires2_postfire$SEV_CLASS == 4
  ] <- median(c(76, 94))
  albertafires2_postfire$SEV_CONT[
    albertafires2_postfire$SEV_CLASS == 5
  ] <- median(c(95, 100))

  saskatchewanfires_postfire$SEV_CLASS <- as.numeric(as.character(
    saskatchewanfires_postfire$SEV_CLASS
  ))
  saskatchewanfires_postfire$SEV_CONT[
    saskatchewanfires_postfire$SEV_CLASS == 0
  ] <- 0
  saskatchewanfires_postfire$SEV_CONT[
    saskatchewanfires_postfire$SEV_CLASS == 1
  ] <- median(c(1, 25))
  saskatchewanfires_postfire$SEV_CONT[
    saskatchewanfires_postfire$SEV_CLASS == 2
  ] <- median(c(26, 50))
  saskatchewanfires_postfire$SEV_CONT[
    saskatchewanfires_postfire$SEV_CLASS == 3
  ] <- median(c(51, 75))
  saskatchewanfires_postfire$SEV_CONT[
    saskatchewanfires_postfire$SEV_CLASS == 4
  ] <- median(c(76, 94))
  saskatchewanfires_postfire$SEV_CONT[
    saskatchewanfires_postfire$SEV_CLASS == 5
  ] <- median(c(95, 100))

  albertafires1_postfire$Province <- "AB"
  albertafires2_postfire$Province <- "AB"
  saskatchewanfires_postfire$Province <- "SK"

  ## correction of fire years and convert to numeric
  ## see data/fires_Dave/all129-overview.xls

  albertafires2_postfire$FIRE_YEAR <- as.character(
    albertafires2_postfire$FIRE_YEAR
  )
  saskatchewanfires_postfire$FIRE_YEAR <- as.character(
    saskatchewanfires_postfire$FIRE_YEAR
  )

  ## LETTER Y fire
  albertafires2_postfire$FIRE_YEAR <- sub(
    "<1953",
    "1953",
    albertafires2_postfire$FIRE_YEAR
  )

  ## MEIKLE fire
  albertafires2_postfire$FIRE_YEAR <- sub(
    "195X",
    "1952",
    albertafires2_postfire$FIRE_YEAR
  )

  ## HALVERSON fire
  albertafires2_postfire$FIRE_YEAR <- sub(
    "194X",
    "1945",
    albertafires2_postfire$FIRE_YEAR
  )

  ## Alfred fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Alfred"
  ] <- "1981"

  ## Brett fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Brett"
  ] <- "1977"

  ## Carlton fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Carlton"
  ] <- "1980"

  ## Dillon Lake fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Dillon Lake"
  ] <- "1977"

  ## Elk fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Elk"
  ] <- "1983"

  ## Harry Lake fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Harry Lake"
  ] <- "1980"

  ## McArther fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "McArther"
  ] <- "1984"

  ## Rail fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Rail"
  ] <- "1984"

  ## Rainbow fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Rainbow"
  ] <- "1986"

  ## Sixty fire
  saskatchewanfires_postfire$FIRE_YEAR[
    saskatchewanfires_postfire$FIRE_NAME == "Sixty"
  ] <- "1981"

  albertafires1_postfire$FIRE_YEAR <- as.numeric(as.character(
    albertafires1_postfire$FIRE_YEAR
  ))
  albertafires2_postfire$FIRE_YEAR <- as.numeric(as.character(
    albertafires2_postfire$FIRE_YEAR
  ))
  saskatchewanfires_postfire$FIRE_YEAR <- as.numeric(as.character(
    saskatchewanfires_postfire$FIRE_YEAR
  ))

  ## bind and return
  firesABSK <- rbind(
    albertafires1_postfire,
    albertafires2_postfire,
    saskatchewanfires_postfire
  )

  return(firesABSK)
}


#' Data preparation wrapper function -- for caching data prep steps
#'
#' @param resolution numeric. in meters. Defaults to 30m.
#' @param doCache logical. Activates/deactivates caching. Passed to reproducible::Cache
#' @param fireDataPath character. Folder path to fire severity data.
#' @param vegDataPath character. Folder path to pre-fire vegetation data.
#' @param topoDataPath character. Folder path to topography data.
#' @param weatherDataPath character. Folder path to fire weather data.
#'
#' @returns
#' @export
#'
#' @importFrom amc .gc
#' @importFrom reproducible Cache
#' @importFrom crayon cyan

dataPrepWrapper <- function(resolution = 30,
                            fireDataPath = "data/fires_Dave/fireSev",
                            vegDataPath = "data/fires_Dave/prefireVeg",
                            topoDataPath = "data/fires_Dave/DEM/Grid30Intersect",
                            weatherDataPath = "data/fires_Dave/fireWeather",
                            doCache = TRUE) {

  message(cyan("Joining severity, vegetation, topo. and weather datasets..."))
  ABSK_AllData <- Cache(ABSKfires_DataPrep,
                        fireDataPath = fireDataPath,
                        vegDataPath = vegDataPath,
                        topoDataPath = topoDataPath,
                        weatherDataPath = weatherDataPath,
                        resolution = resolution,
                        cacheId = "7317549c72849eb2",
                        doCache = doCache,
                        bindAllFires = FALSE,
                        # useCache = FALSE,
                        userTags = "ABSKfires_DataPrep",
                        omitArgs = c("bindAllFires", "doCache", "userTags"))

  ## exclude event perimeter patch type
  # memory.limit(size = 64000)
  ABSK_AllData <- subset(x = ABSK_AllData, PatchType != "eventPerim")
  amc::.gc()

  ## remove columns with no data
  NAcols <- sapply(ABSK_AllData, FUN = function(x) all(is.na(x)))
  ABSK_AllData <- ABSK_AllData[, .SD, .SDcols = names(which(!NAcols))]
  zeroCols <- sapply(ABSK_AllData, FUN = function(x) all(x == 0, na.rm = TRUE))
  ABSK_AllData <- ABSK_AllData[, .SD, .SDcols = names(which(!zeroCols))]

  ## calculate stand age at fire year by subtracting fire year - makes negative values
  ABSK_AllData[!is.na(ORIGIN_UPPER), STAND_AGE := FIRE_YEAR - ORIGIN_UPPER]

  ## convert SMR to ordinal variable (moister as values increase)
  ABSK_AllData[SMR == "D", SMR_ord := 1]
  ABSK_AllData[SMR == "F", SMR_ord := 2]
  ABSK_AllData[SMR == "M", SMR_ord := 3]
  ABSK_AllData[SMR == "W", SMR_ord := 4]
  ABSK_AllData[SMR == "A", SMR_ord := 5]

  ABSK_AllData[, SMR_ord := as.ordered(SMR_ord)]

  ## summarise weather data - faster if not cached
  message(cyan("Summarising weather data..."))
  summaryABSK_AllData <- Cache(summarizeABSK_AllData,
                               DT = ABSK_AllData,
                               dim = dim(ABSK_AllData),
                               days = 1:3,
                               omitArgs = c("DT"),
                               cacheId = "8819c7d9a85ca340",
                               useCache = doCache) ## cacheId = "7f5e7f0ae8fe1943"

  ## collapse species into more generic categories
  message(cyan("Aggregating species..."))
  summaryABSK_AllData[, FlamConif := sum(`Pice glau`, `Pice mari`, `Pice enge`,
                                         `Pinu cont`, `Pinu bank`, na.rm = TRUE),
                      by = pixID]
  summaryABSK_AllData[, Abie := sum(`Abie bals`, `Abie lasi`, na.rm = TRUE),
                      by = pixID]
  summaryABSK_AllData[, Decid := sum(`Popu trem`, `Popu balb`, `Betu papy`, na.rm = TRUE),
                      by = pixID]

  ## collapse non-forested variables
  message(cyan("Aggregating non-forested classes..."))
  if (dim(summaryABSK_AllData[!is.na(NATURALLY_NON_VEG) & !is.na(NON_FORESTED_VEG)])[1] |
      dim(summaryABSK_AllData[!is.na(NATURALLY_NON_VEG) & !is.na(NON_FORESTED_ANTHRO)])[1] |
      dim(summaryABSK_AllData[!is.na(NON_FORESTED_VEG) & !is.na(NON_FORESTED_ANTHRO)])[1])
    warning("> 1 non-forest class type present")

  collapseCols <- function(x) {
    x <- unlist(x)
    names(x) <- NULL
    if (all(is.na(x)))
      "NA"
    else
      x[!is.na(x)]
  }

  cols <- c("NATURALLY_NON_VEG", "NON_FORESTED_VEG", "NON_FORESTED_ANTHRO")
  summaryABSK_AllData[, (cols) := lapply(.SD, as.character), .SDcols = cols]
  summaryABSK_AllData[, NonForestValue := collapseCols(c(.SD)), .SDcols = cols, by = pixID]

  summaryABSK_AllData[, isForest := 0]
  summaryABSK_AllData[NonForestValue == "NA", isForest := 1]
  summaryABSK_AllData[!is.na(WETLAND_CLASS) & !WETLAND_VEG_MOD %in% c("F", "T"), isForest := 0]   ## some wetlands are not forests

  ## change Lari lari to simpler name
  setnames(summaryABSK_AllData, "Lari lari", "Lari")

  ## rescale severity from 0-1
  message(cyan("Rescaling severity to [0,1], and converting 97.5% severity to 100%..."))

  summaryABSK_AllData[, SEV_PROP := SEV_CONT/100]
  ## convert the highest fire severity to 1
  summaryABSK_AllData[SEV_PROP == 0.9750, SEV_PROP := 1.0]

  ## change some columns to numeric
  cols <- grep("mean|max|min|cv|range|pixID|P_ID|Duration|ORIGIN|HEIGHT|isForest|SEV_PROP|Aspect|^CTI$|PctSlope|SurfReliefRatio|SurfAspectRatio|Elevation", names(summaryABSK_AllData), value = TRUE)
  str(summaryABSK_AllData[, ..cols])
  summaryABSK_AllData <- summaryABSK_AllData[, (cols) := lapply(.SD, as.numeric), .SDcols = cols]

  ## calculate SMR_wet
  message(cyan("Creating binary 'wet' SMR variable..."))
  summaryABSK_AllData[, SMR_wet := as.integer(grepl("4|5", SMR_ord))]

  ## fix Area column (not used but still)
  message(cyan("Data fixes and column class adjustments..."))
  summaryABSK_AllData[, Area := as.integer(sub(",", "", Area))]

  ## disturbance years and percentages should be integer
  cols <- grep("YEAR|_PER$", names(summaryABSK_AllData), value = TRUE)
  summaryABSK_AllData[, (cols) := lapply(.SD, as.integer), .SDcols = cols]


  ## make some columns factors
  cols <- unique(c("FIRE_NAME", "Czone1", "NR1"), names(which(sapply(summaryABSK_AllData, is.character))))
  summaryABSK_AllData <- summaryABSK_AllData[, (cols) := lapply(.SD, as.factor), .SDcols = cols]

  ## make some columns others boolean
  cols <- c("UNDERSTOREY", "isForest", "SMR_wet")
  summaryABSK_AllData <- summaryABSK_AllData[, (cols) := lapply(.SD, as.logical), .SDcols = cols]

  return(summaryABSK_AllData)
}
