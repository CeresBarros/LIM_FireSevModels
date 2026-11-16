#' Shared settings for the severity models
#'
#' Settings that must be identical across the GAMLSS and XGBoost workflows.
#' Sourced by the analysis Rmds after the helper scripts and before
#' `analyses/R_tools/buildModelData.R`. Settings only, no functions; paths and
#' data `cacheId`s are set in each Rmd.
#'
#' Elements of `modelCfg`:
#' - `seed`: project seed for fold assignment and fitting.
#' - `holdoutFires`: `FIRE_NAME`s of the holdout fires (`NA` until decided).
#' - `nFolds`: number of fire-grouped CV folds (`NA` until decided).
#' - `bufferDists`: neighbourhood distances (m).
#' - `predSets`: explicit column names per neighbourhood set (Old-ngb and
#'   Ring-ngb are mutually exclusive, never combined).
#' - `weatherVars`: weather candidates (`NULL` until decided).
modelCfg <- list(
  seed = 4817L,
  holdoutFires = NA_character_,  ## TODO: main-plan decision 1
  nFolds = NA_integer_,          ## TODO: main-plan decision 2
  bufferDists = 30 * 2^(0:6)
)

modelCfg$predSets <- list(
  oldNgb = paste0("ngbPropBurns_", modelCfg$bufferDists, "m"),
  ringNgb = NULL                 ## TODO: after the dummy-class choices
)

modelCfg["weatherVars"] <- list(NULL)  ## TODO: main-plan decision 11
