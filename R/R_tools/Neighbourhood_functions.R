
## CALCULATE NEIGHBOURHOOD SEVERITY -----------------------
## Calculates the average severity of neighbours according
## to a given distance or set of distances

## dist is a vector of distances in meters - note that sevPoints much be in a meter-based projection
## sevPoints is an sf object of points and severity
## sevColID is the columns name of the severity column

calculateNgbSevWrapper <- function(dists, sevPoints, sevColID, parallel = TRUE) {
  if (length(dists) > 1) {
    if (parallel) {
      message("Starting parallelization...")
      require(future.apply)
      plan(multisession(gc = TRUE))
      ngbSEVList <- future_lapply(dists, FUN = .calculateNgbSev,
                                  sevPoints = sevPoints, sevColID = sevColID)

    } else {
      ngbSEVList <- lapply(dists, FUN = .calculateNgbSev,
                           sevPoints = sevPoints, sevColID = sevColID)
    }
    ngbSEVDT <- Reduce(function(x, y) merge(x, y, by = "pixID", all = TRUE),
                       ngbSEVList)
  } else
    ngbSEVDT <- .calculateNgbSev(dists, sevPoints, sevColID)

  return(ngbSEVDT)
}

.calculateNgbSev <- function(dist, sevPoints, sevColID) {
  if (sum(names(sevPoints) %in% sevColID) > 1)
    stop("Several column names match 'sevColID")
  if (!sum(names(sevPoints) %in% sevColID))
    stop("No column names match 'sevColID")

  ## change col name for generality
  names(sevPoints) <- sub(sevColID, "sev", names(sevPoints))

  ## draw buffers
  message(paste0("Drawing ", dist, "m buffers and detecting neighbours"))
  bufferSf <- st_buffer(sevPoints, dist = dist) ## keep all columns so that the join identifies .x and .y columns

  ## join to find with pixels are within another's buffer
  ## st_touches avoids "self" joins, so pixels are not joined with their own buffer
  pointsWithinBuffer <- st_join(bufferSf, sevPoints, join = st_touches)
  names(pointsWithinBuffer) <- sub("\\.x", "buffer", names(pointsWithinBuffer))
  names(pointsWithinBuffer) <- sub("\\.y", "points", names(pointsWithinBuffer))

  pointsWithinBufferDT <- data.table(st_drop_geometry(pointsWithinBuffer))
  pointsWithinBufferDT[, sevbuffer := NULL] ## keep track of neighbour sev only

  setnames(pointsWithinBufferDT, old = c("pixIDbuffer", "pixIDpoints", "sevpoints"),
           new = c("pixID", "pixIDneigh", "sevngb"))

  message(paste0("Calculating average severity across neighbours"))
  ngbhoodSEV <- pointsWithinBufferDT[, list(sevngbhood = mean(sevngb, na.rm = TRUE)),
                                     by = pixID]
  setnames(ngbhoodSEV, old = "sevngbhood",
           new = paste0("meanngb", sevColID, "_", dist, "m"))
  message(paste0("Done!"))
  return(ngbhoodSEV)
}


## CALCULATE NEIGHBOURHOOD NO. BURNT PIXELS -----------------------
## Calculates the proportion of burnt neighbours according
## to a given distance or set of distances. Points with 0 severity are assumed to not be burnt.

## dist is a vector of distances in meters - note that sevPoints much be in a meter-based projection
## sevPoints is an sf object of points and severity
## sevColID is the columns name of the severity column
## cores is the number of cores to use for parallelisation

calculateNgbBurnsWrapper <- function(dists, sevPoints, sevColID, fireColID,
                                     resolution = resolution, parallel = TRUE, cores = NULL) {
  ## make a list of combinations of fire ID and buffer distance
  fireBufferCombos <- expand.grid(unique(sevPoints[[fireColID]]), dists)
  names(fireBufferCombos) <- c("fireID", "dists")

  if (nrow(fireBufferCombos) > 1) {
    if (parallel) {
      message("Starting parallelization...")
      require(future.apply)
      if (is.null(cores)) {
        cores <- availableCores()
      }
      plan(multisession(gc = TRUE), workers = cores)
      ngbSEVList <- future_mapply(FUN = .calculateNgbBurns, dist = fireBufferCombos$dists,
                                  fireID = fireBufferCombos$fireID,
                                  MoreArgs = list(sevPoints = sevPoints, sevColID = sevColID,
                                                  fireColID = fireColID, resolution = resolution),
                                  SIMPLIFY = FALSE)

    } else {
      ngbSEVList <- Cache(Map,
                          dist = fireBufferCombos$dists,
                          fireID = fireBufferCombos$fireID,
                          MoreArgs = list(sevPoints = sevPoints, sevColID = sevColID,
                                          fireColID = fireColID, resolution = resolution),
                          .calculateNgbBurns)
    }
    ngbSEVDT <- rbindlist(ngbSEVList)
  } else
    ngbSEVDT <- .calculateNgbBurns(fireBufferCombos$dists, fireBufferCombos$fireID,
                                   sevPoints, sevColID, fireColID, resolution)

  return(ngbSEVDT)
}

.calculateNgbBurns <- function(dist, fireID, sevPoints, sevColID, fireColID, resolution) {
  if (sum(names(sevPoints) %in% sevColID) > 1)
    stop("Several column names match 'sevColID")
  if (!sum(names(sevPoints) %in% sevColID))
    stop("No column names match 'sevColID")

  ## change col name for generality
  names(sevPoints) <- sub(sevColID, "sev", names(sevPoints))

  ## do one fire at a time
  ## make raster of severity and raster of pixel IDs
  i <- which(sevPoints[[fireColID]] == fireID)
  fireRas <- raster(as_Spatial(sevPoints[i,]), resolution = resolution, crs = crs(sevPoints))
  fireRas[] <- NA
  fireRas <- rasterize(as_Spatial(sevPoints[i,]), fireRas, field = "sev")
  fireRasIDs <- rasterize(as_Spatial(sevPoints[i,]), fireRas, field = "pixID")

  ## draw buffers
  message(paste0("Drawing ", dist, "m buffers and counting burnt neighbours for ", fireID, " fire"))
  w <- focalWeight(fireRas, d = dist*3, type = "circle")
  w[w > 0] <- 1
  w[w == 0] <- NA
  w[ceiling(nrow(w)/2), ceiling(ncol(w)/2)] <- 0  ## exclude focal cell

  ## calculate prop burnt neighbours per pixel
  message(paste0("Calculating number of burnt neighbours"))
  ngbhoodBurns <- focal(fireRas, w = w, pad = TRUE,
                        fun = function(x) {sum(x > 0, na.rm = TRUE)/sum(!is.na(x))})
  ngbhoodBurns <- mask(ngbhoodBurns, fireRas)  ## need to remove 0s beyond fire perimeter

  ## make DT
  ngbhoodBurnsDT <- data.table(pixID = getValues(fireRasIDs),
                               ngbPropBurns = getValues(ngbhoodBurns),
                               fire = fireID,
                               bufferSize = dist)
  ngbhoodBurnsDT <- na.omit(ngbhoodBurnsDT)
  setnames(ngbhoodBurnsDT, old = "fire", new = fireColID)

  ## checks
  if (length(unique(ngbhoodBurnsDT$pixID)) != length(i)) {
    noMissing <- sum(!sevPoints$pixID[i] %in% ngbhoodBurnsDT$pixID)
    warning(paste(noMissing, "points in fire perimeter were not converted to raster pixels.",
                  "\nThis is probably due to more than one point falling in the same cell"))
  }
  message(paste0("Done!"))
  return(ngbhoodBurnsDT)
}


#' CALCULATE NEIGHBOURHOOD VARIABLE AVERAGES
#' Calculates average values of predictor variables within "ring-like" buffers
#' around each data point.
#'
#' @param dists vector of distances in meters, used as the maximum width of each ring-buffer.
#'   the minimum width is taken as the previous distance (after ordering), or 0 in the case of the first distance.
#'   Note that dataPoints much be in a meter-based projection.
#' @param dataPoints sf object. Points shapefile with variables to average.
#' @param fireColID character. Name of the fire ID column

#' @param parallel logical. Controls parallelisation
#' @param cores number of cores to use for parallelisation
#' @param ... additional arguments passed to 'calculateNgbAvgs'
#'
#' @details
#'  Computations are done in parallel (or sequentially) per buffer and per fire
#'  perimeter.
#'
#' @importFrom purrr pmap
calculateNgbAvgsWrapper <- function(dists, dataPoints, fireColID,
                                    pointIDColID = "pixID", parallel = TRUE, cores = NULL, ...) {
  ## checks
  if(!inherits(dataPoints, "sf")) {
    stop("'dataPoints' must be an sf POINTS object")
  }

  if(st_geometry_type(dataPoints, by_geometry = FALSE) != "POINT") {
    stop("'dataPoints' must be an sf POINTS object")
  }

  ## make table of min/max distance for each buffer ring
  bufferRange <- data.table(bufferID = dists, min = c(0, dists[1:(length(dists)-1)]), max = dists)

  ## make a list of combinations of fire ID and buffers
  fireBufferCombos <- as.data.table(expand.grid(unique(dataPoints[[fireColID]]), dists))
  names(fireBufferCombos) <- c("fireID", "bufferID")

  fireBufferCombos <- bufferRange[fireBufferCombos, on = "bufferID"]
  cacheExtra <- CacheDigest(dataPoints)
  browser()
  # Error in check_duplicate_names(x) :
  #   x has duplicated column names [Decid_30m.x, HEIGHT_LOWER_30m.x, CTI_30m.x, Lari_30m.x, SMR_wet_30m.x, UNDERSTOREY_30m.x, FlamConif_30m.x, PctSlope_30m.x, SurfAspectRatio_30m.x, isForest_30m.x, ...]. Please remove or rename the duplicates and try again.
  ## replace dists with buffer range table
  if (nrow(fireBufferCombos) > 1) {
    if (parallel) {
      message("Starting parallelization...")
      require(mirai)
      require(carrier)
      if (is.null(cores)) {
        message("Using all available cores for parallelisation")
        cores <- availableCores()
      }
      mirai::daemons(cores)

      ngbAvgsList <- list(fireID = fireBufferCombos$fireID,
                          bufferMin = fireBufferCombos$min,
                          bufferMax = fireBufferCombos$max) |>
        pmap(in_parallel(\(fireID, bufferMin, bufferMax) {
          require("Require")
          require("reproducible")
          require("sf")
          require("data.table")
          require("purrr")
          source("R/R_tools/Neighbourhood_functions.R")
          opts <- options(reproducible.cachePath = cacheRepo)
          on.exit(options(opts), add = TRUE)
          calculateNgbAvgs(fireID = fireID, bufferMin = bufferMin,
                           bufferMax = bufferMax, dataPoints = dataPoints,
                           fireColID = fireColID, pointIDColID = pointIDColID,
                           resolution = resolution)
        },
        cacheRepo = getOption("reproducible.cachePath"),
        dataPoints = dataPoints,
        fireColID = fireColID, pointIDColID = pointIDColID,
        resolution = resolution))

      mirai::daemons(0)
    } else {
      ngbAvgsList <- list(fireID = fireBufferCombos$fireID,
                          bufferMin = fireBufferCombos$min,
                          bufferMax = fireBufferCombos$max) |>
        pmap(calculateNgbAvgs, dataPoints = dataPoints,
             fireColID = fireColID, pointIDColID = pointIDColID,
             resolution = resolution)
    }
    browser()

    ngbAvgsDT <- Reduce(.myMerge, ngbAvgsList)
  } else {
    ngbAvgsDT <- calculateNgbAvgs(fireID = fireBufferCombos$fireID,
                                  bufferMin = fireBufferCombos$min,
                                  bufferMax = fireBufferCombos$max,
                                  dataPoints = dataPoints,
                                  fireColID = fireColID, pointIDColID = pointIDColID,
                                  resolution = resolution) |>
      Cache(userTags = "calculateNgbAvgs",
            .cacheExtra = cacheExtra,
            omitArgs = c("useCache", "userTags", "dataPoints"))
  }
  return(ngbAvgsDT)
}

#' CALCULATE NEIGHBOURHOOD VARIABLE AVERAGES - Internal
#' Calculates average values of predictor variables within "ring-like" buffers
#'
#' @inheritParams calculateNgbAvgsWrapper
#' @param fireID name of fire perimeter.
#' @param varColID character. Name of the variable columns that will be averaged.
#' @param bufferMin numeric. Minimum buffer distance (i.e. starting distance of buffer) in m.
#' @param bufferMax numeric. maximum buffer distance (i.e. ending distance of buffer) in m. Also used as buffer ID.
#' @param resolution original resolution
#'
#' @importFrom purrr map map_lgl
#' @importFrom reproducible Cache CacheDigest
#' @importFrom sf st_buffer st_drop_geometry st_intersects
#' @import data.table
calculateNgbAvgs <- function(fireID, bufferMin, bufferMax, dataPoints,
                             varColID = NULL, pointIDColID, fireColID, resolution) {
  bufferID <- bufferMax

  if (is.null(varColID)) {
    message("'varColID' not provided. Using all columns that are not 'pointIDColID' and 'fireColID'")
    tempData <- st_drop_geometry(dataPoints)
    varColID <- setdiff(names(tempData), c(pointIDColID, fireColID))
  }

  ## do one fire at a time
  ## make buffer around each point i of the fire
  i <- which(dataPoints[[fireColID]] == fireID)

  message(paste0("Drawing ", bufferID, "m buffers and averaging covariates within for ", fireID, " fire"))
  buffers <- st_buffer(dataPoints[i, pointIDColID], dist = bufferMax)

  ## if minimum distance is not 0 we need to subtract the smaller buffer to get a ring
  if (bufferMin > 0) {
    smallBuffers <- st_buffer(dataPoints[i, pointIDColID], dist = bufferMin)

    ## checks
    if (nrow(buffers) != nrow(smallBuffers)) stop("Different number of small and large buffers per point")
    if (any(buffers[[pointIDColID]] != smallBuffers[[pointIDColID]])) {
      ## re-order
      smallBuffers <- smallBuffers[smallBuffers[[pointIDColID]] %in% buffers[[pointIDColID]]]
    }

    cacheExtra <- c(CacheDigest(buffers, quick = TRUE),
                    CacheDigest(smallBuffers, quick = TRUE),
                    bufferID, as.character(fireID))
    buffers <- .makeRings(buffers, smallBuffers, pointIDColID) |>
      Cache(omitArgs = c("buffers", "smallBuffers"),
            .cacheExtra = cacheExtra)
  }

  ## Find neighbour points within the buffer
  cacheExtra <- c(CacheDigest(buffers, quick = TRUE),
                  CacheDigest(dataPoints[i, pointIDColID], quick = TRUE))

  pointsInBuffer <- st_intersects(x = buffers, y = dataPoints[i, pointIDColID]) |>
    Cache(userTags = c(as.character(fireID), bufferID),  ## fireID can be a factor and c() would coerce to numeric
          omitArgs = c("x", "y"),
          .cacheExtra = cacheExtra)

  ## remove the focal point from the list of intersected points
  pointsInBuffer <- lapply(1:length(pointsInBuffer), function(i) {
    setdiff(pointsInBuffer[[i]], i)
  })

  ## replace IDs with pixID
  buffersIDs <- matrix(buffers$pixID, ncol = 1, dimnames = list(rownames = 1:length(buffers$pixID)))
  names(pointsInBuffer) <- buffersIDs[1:length(pointsInBuffer),]
  pointsInBuffer <- lapply(pointsInBuffer, function(pts) {
    buffersIDs[pts]
  })

  ## average variables across neighbours per focal point
  ## overhead to parallelize is too high to compensate
  cacheExtra <- c(CacheDigest(pointsInBuffer, quick = TRUE),
                  CacheDigest(dataPoints, quick = TRUE))

  ngbhoodAvgsDT <- .calcAvgs(pointsInBuffer, dataPoints, pointIDColID, varColID) |>
    Cache(userTags = c(as.character(fireID), bufferID),  ## fireID can be a factor and c() would coerce to numeric
          omitArgs = c("pointsInBuffer", "dataPoints"),
          .cacheExtra = cacheExtra)

  ## add fire and buffer IDs (as suffix)
  ngbhoodAvgsDT[, fire := fireID]
  setnames(ngbhoodAvgsDT, old = "fire", new = fireColID)

  newNames <- paste0(varColID, "_", bufferID, "m")
  setnames(ngbhoodAvgsDT, varColID, newNames)

  ## checks
  if (any(!complete.cases(ngbhoodAvgsDT))) {
    naPix <- ngbhoodAvgsDT[!complete.cases(ngbhoodAvgsDT), pixID]

    out <- pointsInBuffer[naPix] |>
      map(length)

    if (all(out == 0)) {
      message(paste(sum(out == 0), "pixIDs have no neighbours at buffer size", bufferID, "m"))
      message("They will be excluded from the output table.")
      ngbhoodAvgsDT <- na.omit(ngbhoodAvgsDT)
    } else {
      naPix <- names(which(out > 0))

      tempDT <- st_drop_geometry(dataPoints) |>
        as.data.table()

      ## make sure that NAs in avg table match the NAs in neighbours
      test1 <- naPix |>
        map_lgl(\(pix) {
          ngbs <- pointsInBuffer[[pix]]
          tempDT[pixID %in% ngbs]

          naCols <- which(is.na(ngbhoodAvgsDT[pixID == pix])) ## here make sure the columns are the same
          naCols <- sub(paste0("_", bufferID, "m"), "", names(ngbhoodAvgsDT)[naCols])

          all(is.na(tempDT[pixID %in% ngbs, ..naCols]))
        })

      if(any(!test1)) {
        stop("Something went wrong. Avg neighbour values are NA, but some neighbours had values.")
      }

      rm(tempDT); gc(reset = TRUE)
    }
  }

  ## this seems to be duplicating the if (all(out == 0)) above.
  if (length(unique(ngbhoodAvgsDT$pixID)) != length(i)) {
    noMissing <- sum(!dataPoints$pixID[i] %in% ngbhoodAvgsDT$pixID)
    warning(paste("For", noMissing, "points in fire perimeter did not have neighbours using a", bufferID, "m buffer."))
  }
  message(paste0("Done!"))

  return(ngbhoodAvgsDT)
}


#' Make buffer rings
#'
#' Internal function
#'
#' @param buffers
#' @param smallBuffers
#' @param pointIDColID

.makeRings <- function(buffers, smallBuffers, pointIDColID) {
  rings <- 1:nrow(buffers) |>
    map(\(poly) {
      ring <- st_difference(buffers[poly,], smallBuffers[poly,])

      ring <- ring[, pointIDColID]  ## drop extra id column
      return(ring)
    })

  rings <- do.call(rbind, rings)
}

.myMerge <- function(x, y) {
  pointIDColID <- dynGet("pointIDColID")
  fireColID <- dynGet("fireColID")
  merge(x, y, by = c(pointIDColID, fireColID), all = TRUE)
}

#' Wrapper function to calculate averaged neighbour properties
#'
#' @param pointsInBuffer
#' @param st_drop_geometry
#' @param dataPoints
#' @param pointIDColID
#' @param varColID
#'
#' @returns data.table of average neighbour attributes by focal point
#' @importFrom purrr map
#' @import data.table
#' @importFrom sf st_drop_geometry
.calcAvgs <- function(pointsInBuffer, dataPoints, pointIDColID, varColID) {
  ngbhoodAvgsDT <- pointsInBuffer |>
    map(\(ngbs) {
      DT <- st_drop_geometry(dataPoints)
      DT <- DT[DT[[pointIDColID]] %in% ngbs,]
      DTavg <- DT[, lapply(.SD, mean, na.rm = TRUE), .SDcols = varColID]
      return(DTavg)
    }) |>
    rbindlist(use.names = TRUE, idcol = pointIDColID)

  return(ngbhoodAvgsDT)
}
