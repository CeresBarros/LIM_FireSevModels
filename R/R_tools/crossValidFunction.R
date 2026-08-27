## ----------------------------------------
## RUN K-FOLD CROSS VALIDATION -- Functions moved to ToolsCB
##
## Ceres Feb 26th 2020
## ----------------------------------------

## this script should be sourced

#' k-fold cross-validation for GAMLSS severity models
#'
#' Partitions `fullDT` into `k` folds (stratified by `FIRE_NAME`) and
#' refits `statsModel` on each training fold, evaluating on the
#' held-out fold. Wraps [calcCrossValidMetrics()] and optionally
#' parallelises across folds via `future.apply`.
#'
#' @param fullDT `data.table` with the full dataset (may contain more
#'   columns than the model uses).
#' @param statsModel a fitted `gamlss` model to be re-fit on each
#'   training fold via [stats::update()].
#' @param origData the data originally used to fit `statsModel`.
#'   Determines which columns of `fullDT` are retained when subsetting
#'   train/test folds.
#' @param level passed through to [gamlss::predict.gamlss()] (e.g. for
#'   random effects). Default `NULL`.
#' @param k integer number of folds. Default 4.
#' @param idCol character. Column of `fullDT` uniquely identifying each
#'   pixel / observation.
#' @param cacheObj1,cacheObj2 optional objects used for
#'   `reproducible::Cache` digesting so the large data arguments don't
#'   have to be digested directly.
#' @param parallel logical. If `TRUE`, folds are fit in parallel with
#'   `future.apply::future_lapply` under `plan(multicore)` (Linux/macOS)
#'   or `plan(multisession)` (Windows). Default `FALSE`.
#' @param ... further arguments passed to `future::plan()` (e.g.
#'   `workers`).
#'
#' @return A list of length `k` with per-fold outputs from
#'   [calcCrossValidMetrics()].
#' @author Ceres Barros
#' @seealso [calcCrossValidMetrics()]
crossValidFunction <- function(fullDT, statsModel, origData, level = NULL,
                               k = 4, idCol, cacheObj1, cacheObj2,
                               parallel = FALSE, ...) {
  if (!is.null(idCol))
    origDataVars <- c(names(origData), idCol)

  ## remove NAs from the data without subsetting columns
  toKeep <- na.omit(fullDT[, ..origDataVars])[, ..idCol]
  setkeyv(fullDT, idCol)
  setkeyv(toKeep, idCol)
  fullDT <- fullDT[toKeep]

  ## make chunks of 1/4 of the data
  cols2 <- c("FIRE_NAME", idCol)
  sampDT <- fullDT[,..cols2]
  set.seed(123)
  sampDT[, sampID := sample(1:k, size = length(get(idCol)), replace = TRUE),
         by = FIRE_NAME]
  ## join samp IDs with data
  fullDT <- sampDT[fullDT, on = cols2]
  rm(cols2)

  origDataVars <- c(origDataVars, "sampID")

  message(paste("Starting cross-validation using", k, "folds"))
  if (parallel) {
    if (Sys.info()[["sysname"]] == "Windows") {
      plan(multisession, gc = TRUE, ...)
    } else plan(multicore, ...)
    crossValidResults <- future_lapply(unique(fullDT$sampID), FUN = calcCrossValidMetrics,
                                       fullDT = fullDT, origData = origData, idCol = idCol,
                                       statsModel = statsModel, level = level,
                                       origDataVars = origDataVars)
    ## Explicitly close workers
    future:::ClusterRegistry("stop")
  } else {
    crossValidResults <- lapply(unique(fullDT$sampID), FUN = calcCrossValidMetrics,
                                fullDT = fullDT, origData = origData, idCol = idCol,
                                statsModel = statsModel, level = level,
                                origDataVars = origDataVars)
  }
  return(crossValidResults)
}


#' Compute cross-validation metrics for one GAMLSS fold
#'
#' Given a fold index, refits `statsModel` on the training partition,
#' predicts the response on the held-out partition, discretises
#' predictions into severity classes and returns validation metrics
#' (RMSE, R^2, multi-class summary and confusion matrix) plus GAMLSS
#' diagnostics (`Rsq`, `getTGD`, model coefficients).
#'
#' Structured so the large data arguments can be excluded from
#' `reproducible::Cache` digesting.
#'
#' @param samp integer. Fold ID picked as the test set.
#' @param fullDT `data.table` of the full dataset (may include extra
#'   columns beyond those used to fit `statsModel`).
#' @param origData the data used to fit `statsModel`.
#' @param level passed to [gamlss::predict.gamlss()].
#' @param idCol character. Column of `fullDT` uniquely identifying each
#'   pixel / observation.
#' @param statsModel the fitted `gamlss` (BEINF-family) model.
#' @param origDataVars character vector of the variables used in model
#'   fitting (response, predictors, random effects, plus `idCol`).
#'
#' @return A list with entries `validMetrics`, `confMatrix`,
#'   `Rsquared`, `RsqGAMLSS`, `TGD` and `coefs`.
#' @keywords internal
calcCrossValidMetrics <- function(samp, fullDT, origData, level = NULL, idCol, statsModel, origDataVars) {
  ## predict requires the original and new data to have the same columns
  if (!all(names(origData) %in% names(fullDT)))
    stop("'fullDT' needs to include all the columns in 'origData'")

  ## subset
  trainData <<- fullDT[sampID != samp, ..origDataVars]
  testData <- fullDT[sampID == samp, ..origDataVars]

  ## checks
  if (length(setdiff(unique(fullDT$FIRE_NAME),
                     unique(testData$FIRE_NAME))) |
      length(setdiff(unique(fullDT$FIRE_NAME),
                     unique(trainData$FIRE_NAME))))
    stop("Fires lost in sampling!")

    if (any(is.na(trainData)) | any(is.na(testData)))
    stop("Please remove NAs from the variables going in the model")


  ## trainData an testData cannot have extra cols
  cols <- names(origData)
  trainData <- trainData[, ..cols]
  trainData <<- trainData   ## needs to be in .GlobalEnv for gamlss
  testData <- testData[, ..cols]

  ## refit model on training sample
  ## then predict
  trainModel <- tryCatch(update(object = statsModel, data = trainData), error = function(e) e)

  if (is(trainModel, "error")) {
    validMetrics <- c("RMSE" = NA, "Rsquared" = NA, "MAE" = NA, AUC = NA)
  } else {
    params <- c("mu", "nu", "tau")
    names(params) <- params
    predictionsDT <- lapply(params, FUN = function(param) {
      predict(trainModel, what = param,
              newdata = testData, data = trainData,
              type = "response", level = level)
    })
    predictionsDT <- as.data.table(do.call(cbind, predictionsDT))

    ## add response variable
    set(predictionsDT, NULL, "SEV_PROP", testData$SEV_PROP)

    ## get fitted means - using method from gamlss.dist::meanBEINF
    ## tried generating many values and averaging, but doing that results in the same value
    if (trainModel$family[1] != "BEINF")
      stop("the object does not have a BEINF distribution")

    predictionsDT[, predSEV_PROP := calcMeanBEINF(mu, nu, tau)]

    ## add severity classes
    testData <- na.omit(fullDT[sampID == samp, ..origDataVars]) ## redo testData in case idCol was dropped when subsetting to model data
    predictionsDT[, c(idCol) := testData[[grep(idCol, names(testData))]]]
    cols <- c(idCol, "SEV_CLASS")
    predictionsDT <- fullDT[, ..cols][predictionsDT, on = idCol]

    ## convert to classes, using the quantiles corresponding to the observed class proportions
    ## accumulate proportions to get probabilities
    quantProbs <- cumsum(table(predictionsDT$SEV_CLASS)/nrow(predictionsDT))
    classRanges <- c(0, quantile(predictionsDT$predSEV_PROP, probs = quantProbs))

    predictionsDT[, predSEV_CLASS := cut(predSEV_PROP, breaks = classRanges,
                                         include.lowest = TRUE, right = FALSE)]  ## classify as with intervals as ],]

    ## convert to numbered factor (subtracting one, because classes are 0-5)
    predictionsDT[, predSEV_CLASS := as.numeric(predSEV_CLASS)-1]
    classes <- as.character(sort(unique(fullDT$SEV_CLASS)))
    predictionsDT[, `:=`(SEV_CLASS = factor(SEV_CLASS, levels = classes),
                         predSEV_CLASS = factor(predSEV_CLASS, levels = classes))]

    ## VALIDATION STATISTICS WITH CLASSES ----------------------------------
    ## calculate overall statistics
    validMetrics <- caret::multiClassSummary(predictionsDT[, list(obs = SEV_CLASS,
                                                                  pred = predSEV_CLASS)],
                                             lev = classes)
    ## calculate confusion matrix
    confMatrix <- caret::confusionMatrix(data = predictionsDT$predSEV_CLASS, reference = predictionsDT$SEV_CLASS)

    ## VALIDATION STATISTICS WITH CONTINUOUS VARIABLE -----------------------
    browser()
    ##calculate AUC
    RsqGAMLSS <- Rsq(trainModel)
    TGDstats <- getTGD(trainModel, newdata = testData[, .SD, .SDcols = names(trainData)], data = trainData)   ## testData may have additional cols (sampID)
    Rsquared <- caret::postResample(pred = predictionsDT$predSEV_PROP, obs = predictionsDT$SEV_PROP)
    Rsquared <- Rsquared["Rsquared"]
  }


  ## COEFFICIENTS
  list(validMetrics = validMetrics, confMatrix = confMatrix,
       Rsquared = Rsquared, RsqGAMLSS = RsqGAMLSS, TGD = TGDstats$TGD,
       coefs = coefAll(trainModel))
}

