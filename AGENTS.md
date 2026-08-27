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

1. `0_dataPrep_projections.R` — reproject Alberta fire shapefiles (Dave Andison's data). See Gotchas re: R 3.4 / `raster` + `sp` legacy API.
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
- `R/R_tools/inputMaps.R` was **removed** (Aug 2026) as dead code: its four `sp`/`raster`/`rgeos`-based study-region helpers (`loadShpAndMakeValid`, `loadStudyRegions`, `shpStudyRegionCreate`, `createPrjFile`) had no callers here, and a cross-repo check of the upstream `LandscapesInMotion` confirmed they were unused on the `development`, `master`, and `xgboost` branches too. Recover from git history if study-region loading is ever needed (expect to modernize to `sf`/`terra`/`geodata`). `moduleSticker.R` was deleted earlier by the user.

## Assistant conventions in this repo

- Edits to `*.md` are pre-approved via `.posit/assistant/settings.json`; other file edits should be surfaced before writing.
- Prefer plan-then-implement flow; plans live under `.posit/assistant/plans/`.
- **Document R functions with `#'` roxygen blocks, always.** This is unconditional — it does not depend on whether the code lives in a package. Do not substitute `##` comment blocks or a summary index for per-function roxygen.
- **Never modify R files with the `edit`/`write` tools — they trigger format-on-save (Air-style) reformatting even though Air is nominally disabled, producing large unwanted whitespace/brace/argument-splitting diffs.** Edit R files via a `bash` heredoc or an in-place `python3` script instead, so the editor formatter never runs.
- **After any R-file change, verify the diff is comment-only** with `git diff <file> | grep '^[+-]' | grep -v '^[+-]#'` (expect no output) and check `git diff --stat`. Confirm zero incidental deletions and that function signatures/bodies are untouched.
- **Preserve original code style when documenting** — do not reformat: keep original function signatures, single-line `if`/`else` (do not add braces), original operator spacing, and original blank-line layout. Only comment/`#'` lines should change.
- **Internal/atomic helpers always get `@keywords internal` (and only that — never `@noRd` alongside it, since `@noRd` suppresses the `.Rd` entirely and would override `@keywords internal`).** This applies to every non-user-facing function — not just `.`-prefixed helpers but also atomic recoders and any function only called internally by a wrapper (e.g. the CASFRI atomic recoders, `calcCrossValidMetrics`, `joinPerFire`). Exported/user-facing wrappers, the `_FIXED.R` shims, and plotting/analysis entry points do **not** get this tag. When documenting a new helper, decide its tier first and tag accordingly.
- **Other roxygen conventions**: preserve `@author` attributions; inherit upstream parameter docs with `@inheritParams pkg::fn` rather than duplicating; for the `_FIXED.R` shims add an `@note` describing the upstream bug and target version and `@seealso` the patched original (`gamlss::Rsq`, `gamlss.inf::summary.gamlssinf0to1`). Document best-guess argument shapes with a `# TODO: confirm` marker; fix wrong `@param` names/descriptions but **never reorder arguments in code**. CASFRI docs are tiered (see Stage 3 below): full roxygen for the 5 wrappers, short title + `@param` for the 17 atomic recoders.
- **Git safety: never stage, commit, or push without explicit permission.** Before any `git add`/`git commit`/`git push`, stop and ask. Draft the proposed commit message and present it for review/approval. After the user approves, re-confirm approval immediately before running the commit or push. (Enforced in `.posit/assistant/settings.json`: `git add`/`commit`/`push` are set to `"ask"`.)
- **Flag known code issues rather than touching them**: leftover `browser()` calls in `crossValidFunction.R` (`calcCrossValidMetrics`, ~line 161) and `Useful_functions.R` (`runXGBOOST` ~468, `runGPBOOST` ~785/~832); `xgboostConfMat` returns only its last expression (`confMatrix`) with no explicit `return()`, inconsistent with `gpboostConfMat` which returns `list(validMetrics, confMatrix)`; hard-coded `set.seed(123)` in `crossValidFunction`; comment typos in `Rsq_FIXED.R` (`design`→`designed`) and `summary.gamlssinf0to1_FIXED.R` (`covariante`→`covariance`, `calcualted`→`calculated`).

## Documentation pass status

Staged roxygen documentation of `R/R_tools/` and `analyses/R_tools/` (plan under `.posit/assistant/plans/`):

- **Stage 1 — done**, committed as `f503e1c` ("doc clean-up. Stage 1."): `joinSevVegTopoWeatherData.R`, `Neighbourhood_functions.R`, `crossValidFunction.R`, `prepFireWeather.R`, `prepCorrTable.R`, `getPEF_own.R`, `Rsq_FIXED.R`, `summary.gamlssinf0to1_FIXED.R`.
- **Stage 2 — done**, committed as `f0fa101` ("doc clean-up. Stage 2: Useful_functions.R"): all 16 functions in `Useful_functions.R` given per-function `#'` roxygen (full blocks for exported functions; `@keywords internal` for the 5 internal helpers; `@inheritParams runXGBOOST` for `.tunexgboost` and `runGPBOOST`; filled-in `@return` for the previously-empty `xgboostConfMat`/`gpboostConfMat` stubs; an `@note` flagging `xgboostConfMat`'s missing explicit `return()`). Comment-only diff; parses under R.
- **Stage 3 — in progress**: `CASFRIrelated_functions.R` (22 functions total; tiered — full roxygen for the 5 wrappers, short title + `@param` for the 17 atomic recoders).
  - **Part 1 done** (`0ae2fe2`, "doc clean-up. Stage 3 (part 1): CASFRI wrappers"): full `#'` roxygen for the 5 wrappers (`invent2CASFRI`, `ABToCASFRI`, `SKToCASFRI`, `meltPreFireABInv`, `meltPreFireSKInv`); fixed a `CASFIR`→`CASFRI` header typo.
  - **Part 1b done** (`917cfd2`, "doc clean-up. Stage 3 (part 1b): DRY the CASFRI wrapper roxygen with @inheritParams"): `SKToCASFRI`/`meltPreFireABInv` inherit shared params from `ABToCASFRI`; `meltPreFireSKInv` inherits from `meltPreFireABInv`; `ABToCASFRI`'s `@param inv` made province-neutral so SK wrappers inherit `inv` without a local override.
  - **Part 2 done** (uncommitted): short title + `@param` roxygen for the 17 atomic recoders (`spLatinName`, `TypeForest`, `spPercent`, `spPercentAdjust`, `originUpper`, `originLower`, `nonVegNatSK`, `nonVegAnthSK`, `nonForestVegSK`, `wetlandCodesSK`, `wetlandCodesSK2`, `wetlandCodesAB`, `soilMoistureRegime`, `NFLAdjustAB`, `SMRAdjustAB`, `addWaterInfo`, `correctCSGPFTTYPE`), all tagged `@keywords internal` and DRYed with `@inheritParams` (`spPercent` anchors the shared `province`/`MISSCODE`/`ERRCODE`). Also stripped all `@noRd` lines repo-wide, keeping `@keywords internal` only. Comment-only diffs; all files parse.
  - **Remaining**: `analyses/R_tools/DAfires_expAnalyses_dataPrep.R` (`ABSKfires_DataPrep`, `cleanAndBindFireData`, `dataPrepWrapper`) and `summarizeABSK_AllData.R` (`summarizeABSK_AllData`, `summarizeClimateVars`); `getPEF_own.R`'s `getPEF.own` remains undocumented. Continue via `bash`/`python3` heredoc with the comment-only `git diff` verification after each write.

Commits `d43ee3c`, `f0fa101`, `74e5e90`, `3be14db`, `0ae2fe2`, `917cfd2` are local and **not yet pushed**.

## Open items

- `.posit/assistant/settings.json` is rewritten live by the permission system. Current state: `permission.edit` allows `*.md`, `*.json`, and `*.R` (the last is intentionally kept by the user — the heredoc-only rule for R files is a behavioural convention, not permission-enforced); the `bash` allowlist includes both `"python *"` and `"python3 *"`; `git add`/`commit`/`push` are set to `"ask"`. The stale Windows-path `git -C c:/Users/cbarros/...` allowlist entries still don't match this Linux checkout (optional cleanup).
