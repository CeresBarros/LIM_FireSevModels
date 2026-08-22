# AGENTS.md — LIM_FireSevModels

Quick-start notes for AI assistants (and humans) working in this repo.

## Project

Empirical models of **wildfire severity** in Alberta and Saskatchewan boreal (and some montane) forests, using fire, vegetation, topography, and weather covariates. Side project of *Landscapes in Motion* (Foothills Research Institute). Mechanistic companion project: [`LIM_PBH`](https://github.com/CeresBarros/LIM_PBH).

Provenance: branched from the `xgboost` branch of [`LandscapesInMotion`](https://github.com/CeresBarros/LandscapesInMotion) in July 2026, preserving history for the empirical-modelling paths.

## Analyses

Current vs. legacy Rmds in `analyses/`:

| File | Status | Purpose |
|---|---|---|
| `DAfires_sevModelsGAMLSS_ngbAvg.Rmd` | **active** | Zero-one-inflated beta GAMLSS severity models with neighbourhood-averaged predictors |
| `DAfires_sevModelsBoost.Rmd` | active | XGBoost and GPBoost severity models |
| `DAfires_expAnalyses.Rmd` | active | Exploratory analyses of fire severity data |
| `Fires_CNFD.Rmd` / `Fires_CNFD.R` | active | CNFD fire-database prep |
| `FiresDA_FMAs.R` | active | Fires × Forest Management Areas |
| `FI2CASFRI_checkerrors.R` | active | CASFRI cross-check |
| `DAfires_sevModels.Rmd`, `DAfires_sevModelsGAMLSS.Rmd`, `DAfires_sevModelsGAMLSS_ngbAvg` predecessors, `DAfires_expAnalyses_BAD.Rmd` | legacy | Kept on disk; not the current entry points |

Typical run order from raw data:

1. `0_dataPrep_projections.R` — reproject Alberta fire shapefiles (Dave Andison's data). Written against R 3.4 / `raster` + `sp`; expect to modernize to `terra`/`sf` if rerun.
2. `analyses/Fires_CNFD.Rmd` — CNFD prep.
3. `analyses/FiresDA_FMAs.R` — fires × FMAs.
4. `analyses/DAfires_expAnalyses.Rmd` — EDA.
5. `analyses/DAfires_sevModelsGAMLSS_ngbAvg.Rmd` (GAMLSS) and/or `analyses/DAfires_sevModelsBoost.Rmd` (XGBoost/GPBoost).

## Environment

- R 4.5 is the current development target.
- `.Rprofile` sets `.libPaths()` to `packages/<platform>/<Rmajor.minor>/` (or `packages_docker/…` on R 4.1 Linux) and configures repos:
  - `CRAN = http://cran.rstudio.com`
  - `PE   = http://predictiveecology.r-universe.dev/`
- `.Renviron` (untracked) is expected to hold a GitHub PAT.
- Non-CRAN forks required by the active Rmd:
  - `CeresBarros/gamlss.spatial` (== 3.0-3.9000)
  - `PredictiveEcology/reproducible@AI` (== 2.1.2.9001)
  - `CeresBarros/ToolsCB` (>= 0.0.9001)
- Package installation in Rmds is driven by `Require::Require(..., install = FALSE)` — dependencies are listed at the top of each document.

## Caching

- The active Rmd sets `reproducible.cachePath = "analyses/cacheNEW"`.
- The older `analyses/cache/` is flagged in the Rmd as corrupted after a `reproducible` version change — do not reuse it.

## Data

Under `data/` (large inputs gitignored):

| Subfolder | Contents |
|---|---|
| `fires_Dave/` | `DEM/`, `fireSev/`, `fireWeather/` (+ `fireWeatherCode/`), `prefireVeg/`, `water/`, `all129-overview.xls`, `Variable_description.xlsx` |
| `maps/` | Alberta admin/study-area shapes, ecozones, foothills DEM/aspect/slope, `CHECKSUMS.txt` |
| `CA_admin/` | Canadian admin boundaries |
| `FMA/` | Forest Management Areas |
| `VegInventories/` | Vegetation inventories |
| `cache/` | Reference cache |

Root-level reference files: `LCC2010_LCC2005_correspondence.xlsx`, LCC2010 metadata doc, succession notes.

## Helper scripts (`R/R_tools/`)

| File | Role |
|---|---|
| `joinSevVegTopoWeatherData.R` | Rasterizes severity `sf`, joins veg/topo/weather by fire, saves per-fire tables |
| `Neighbourhood_functions.R` | Buffer/neighbourhood severity, burn proportion, and averaged-predictor calculations |
| `crossValidFunction.R` | k-fold cross-validation for `gamlss` models (parallel via `future`) |
| `prepFireWeather.R` | Assembles CNFD-style fire weather (adapted from Colin Ferster) |
| `prepCorrTable.R` | Correlation-table prep for predictor screening |
| `getPEF_own.R` | Partial-effect helpers |
| `CASFRIrelated_functions.R` | CASFRI utilities |
| `Useful_functions.R` | Misc utilities |
| `Rsq_FIXED.R` | Patch for `gamlss:::Rsq` on `gamlssinf0to1` (family handling) |
| `summary.gamlssinf0to1_FIXED.R` | Patch for `gamlss.inf:::summary.gamlssinf0to1` (vcov with random terms) |
| `moduleSticker.R` | Sticker generation |

`analyses/R_tools/` also contains `DAfires_expAnalyses_dataPrep.R` and `summarizeABSK_AllData.R`.

## Gotchas

- README file-layout list historically referenced `DAfires_sevModelsGAMLSS2026.Rmd`; the actual current file is `DAfires_sevModelsGAMLSS_ngbAvg.Rmd` (README has been corrected).
- `0_dataPrep_projections.R` uses the old `raster` / `sp` / `shapefile()` API and was written for R 3.4; expect to modernize before rerunning under R 4.5.
- Two `*_FIXED.R` helpers patch upstream `gamlss`/`gamlss.inf` bugs — keep them sourced whenever the active GAMLSS Rmd is run.
- `simLinks.sh` is present but not currently used; ignore its paths.
- `.posit/assistant/settings.json` contains a `git -C c:/Users/cbarros/GitHub/LIM_FireSevModels` allowlist that won't match this Linux checkout.
- `R/R_tools/inputMaps.R` was **removed** (Aug 2026) as dead code: its four `sp`/`raster`/`rgeos`-based study-region helpers (`loadShpAndMakeValid`, `loadStudyRegions`, `shpStudyRegionCreate`, `createPrjFile`) had no callers here, and a cross-repo check of the upstream `LandscapesInMotion` confirmed they were unused on the `development`, `master`, and `xgboost` branches too. Recover from git history if study-region loading is ever needed (expect to modernize to `sf`/`terra`/`geodata`).

## Assistant conventions in this repo

- Edits to `*.md` are pre-approved via `.posit/assistant/settings.json`; other file edits should be surfaced before writing.
- Prefer plan-then-implement flow; plans live under `.posit/assistant/plans/`.
