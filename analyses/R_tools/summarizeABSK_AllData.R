## FUNCTION TO SUMMARIZE DATA
## calculates summary statistics on weather data and reshapes species data to species columns containing
## percent cover values. Ignores understory layer, but creates a column of understory presence/absence
summarizeABSK_AllData <- function(DT) {
  summaryDT <- DT %>%
    group_by(pixID) %>%
    summarise(startJulDay = min(julDay),
              meanTemp = mean(temp),
              minTemp = min(temp),
              maxTemp = max(temp),
              cvTemp = sd(temp)/mean(temp),
              rangeRH = max(rh) - min(rh),
              meanRH = mean(rh),
              minRH = min(rh),
              maxRH = max(rh),
              cvRH = sd(rh)/mean(rh),
              rangeRH = max(rh) - min(rh),
              meanWS = mean(ws),
              minWS = min(ws),
              maxWS = max(ws),
              cvWS = sd(ws)/mean(ws),
              rangeWS = max(ws) - min(ws),
              meanRain = mean(rain),
              minRain = min(rain),
              maxRain = max(rain),
              cvRain = sd(rain)/mean(rain),
              rangeRain = max(rain) - min(rain),
              meanFFMC = mean(ffmc),
              minFFMC = min(ffmc),
              maxFFMC = max(ffmc),
              cvFFMC = sd(ffmc)/mean(ffmc),
              rangeFFMC = max(ffmc) - min(ffmc),
              meanDMC = mean(dmc),
              minDMC = min(dmc),
              maxDMC = max(dmc),
              cvDMC = sd(dmc)/mean(dmc),
              rangeDMC = max(dmc) - min(dmc),
              meanDC = mean(dc),
              minDC = min(dc),
              maxDC = max(dc),
              cvDC = sd(dc)/mean(dc),
              rangeDC = max(dc) - min(dc),
              meanISI = mean(isi),
              minISI = min(isi),
              maxISI = max(isi),
              cvISI = sd(isi)/mean(isi),
              rangeISI = max(isi) - min(isi),
              meanBUI = mean(bui),
              minBUI = min(bui),
              maxBUI = max(bui),
              cvBUI = sd(bui)/mean(bui),
              rangeBUI = max(bui) - min(bui),
              meanFWI = mean(fwi),
              minFWI = min(fwi),
              maxFWI = max(fwi),
              cvFWI = sd(fwi)/mean(fwi),
              rangeFWI = max(fwi) - min(fwi)) %>%
    data.table(.)
  
  ## merge with remaining data
  setkey(summaryDT, pixID)
  setkey(DT, pixID)
  cols <- grep("julDay|temp|rh|ws|rain|ffmc|dmc|dc|isi|bui|fwi", names(DT),
               invert = TRUE, value = TRUE)
  summaryDT <- summaryDT[unique(DT[, ..cols])]
  
  ## make column with presence/absence of understory and remove the understorey layer
  ## as it can't really be trusted (Andison pers. comm. January 29th 2019)
  ## even considering its presence might be risky as some times aerial photos do not detect the presence of the understorey, even if it is present.
  cols <- grep("SPEC._PER", names(summaryDT), value = TRUE)
  summaryDT[LAYER == 2, UNDERSTOREY := rowSums(.SD, na.rm = TRUE) > 0, .SDcols = cols]
  summaryDT[, UNDERSTOREY2 := any(UNDERSTOREY), by = "pixID"]
  summaryDT[, UNDERSTOREY := UNDERSTOREY2]
  summaryDT[, UNDERSTOREY2 := NULL]
  summaryDT[is.na(UNDERSTOREY), UNDERSTOREY := FALSE]
  summaryDT <- summaryDT[LAYER == 1]
  
  ## change NA cover to 0 and melt species and cover
  ## don't exclude pixels without vegetation
  colA = grep("SPEC.$", names(summaryDT), value = TRUE)
  colB = grep("SPEC._PER", names(summaryDT), value = TRUE)
  
  for (j in which(names(summaryDT) %in% colB))
    set(summaryDT, which(is.na(summaryDT[[j]])), j, 0)
  
  summaryDT <- melt(summaryDT, measure = list(colA, colB), 
                    value.name = c("SPEC", "SPEC_PER"), variable.name = "SPEC_dominance")
  rm(colA, colB); amc::.gc()
  
  ## and now re-cast to have a column per species
  summaryDT <- dcast(summaryDT, ... ~ SPEC, value.var = "SPEC_PER", fill = 0)
  
  ## remove "NA" columns
  cols <- grep("^NA$", names(summaryDT))
  summaryDT[, (cols) := NULL]
  
  ## check for duplicates
  summaryDT <- unique(summaryDT)  
  
  summaryDT
}
