# Plan: output folders, shared config and data-assembly script for the re-validation

Sub-plan of `2026-10-29-1508-plan.md`. Status: **proposal, 2 decisions open** (see end). Nothing has been created yet except `analyses/outputs/` (holds `nonCollinearVars.rds`, from 2026-10-30).

Scope: the **GAMLSS Rmd (`DAfires_sevModelsGAMLSS_ngbAvg.Rmd`) only**. It is the reference for `cacheId`s and column names. The Boost Rmd stays as is until it is re-activated (section 6).

Line numbers refer to the files as of 2026-11-16. Re-check them before editing.

## 1. Folders

```
analyses/
  outputs/                 # gitignored (add explicit rule to analyses/.gitignore)
    nonCollinearVars.rds   # from the collinearity Rmd (exists)
    gamlss/                # models, summaries, CV results; figs/, cache/
    xgboost/               # later, when the Boost Rmd is re-activated
    holdout/               # final holdout predictions + metrics
```

- Manuscript figures stay in `analyses/Figs/`. Run and diagnostic figures go to `<framework>/figs/`.
- File names follow `<model>_<set>_<what>.<ext>` (e.g. `gamlss_ringNgb_stepGAIC.rds`), and each path is recorded in the run log.
- No saved data or fold files. The data comes from the cache, holdout IDs live in the config, and folds are recomputed from the seed.
- Flat layout (no `revalidation/` level); add sibling folders only if unrelated outputs appear.
- Legacy outputs stay where they are (decision 1 = A). Only new outputs go under `outputs/`.

## 2. Shared config: `analyses/R_tools/revalidationConfig.R` (tracked)

Holds only the settings that must match across frameworks. It defines one list, `revalCfg`, and contains no functions. It is written via heredoc.

| Element | Value | Status |
|---|---|---|
| `seed` | one random integer | set now |
| `holdoutFires` | `FIRE_NAME`s | `NA` until main-plan decision 1 |
| `nFolds` | grouped by `FIRE_NAME` | placeholder until main-plan decision 2 |
| `bufferDists` | `30 * 2^(0:6)` | set now |
| `predSets$oldNgb` | `ngbPropBurns_<d>m` names | set now |
| `predSets$ringNgb` | `<var>_<d>m` ring-average names (incl. dummy columns) | after the dummy-class choices |
| `weatherVars` | least-collinear weather candidates | after main-plan decision 11 |

Not in the config:
- **Paths:** each Rmd sets `outDir`, `runFigDir` and `fitCachePath` in its setup chunk.
- **Data `cacheId`s:** these stay at their `Cache()` calls.

The explicit `predSets` replace the regex `_[[:digit:]]{2,4}m$`, which matches both sets (caveat C1).

## 3. Shared data-assembly script: `analyses/R_tools/buildModelData.R` (tracked)

This replaces the `dataprep`, `addNgbNoBurns` and `addNgbAvgProperties` chunks of the GAMLSS Rmd (l.102–250) with a single `source()` chunk (`cache = FALSE`).

- **Your code moves in verbatim**, including the comments and the `rm()`/`gc()` calls. It stays a plain script rather than a function, so it creates the same objects as before.
- Only edits:
  - Both `bufferDists` loops → `revalCfg$bufferDists`.
  - Append a holdout flag and fold IDs from `revalCfg`.
- `cacheId`s are kept as in the Rmd: data `cc55d7d2a817284e`, `ngbNoBurns` `c7536dcb493ad453`, ring averages unpinned.
- It expects `doCache`, the sourced helpers and `revalCfg` to be in scope.
- After writing it, I'll diff it against the original chunk text.

## 4. Changes to the GAMLSS Rmd

"Me" = plumbing I can do once approved; "you" = implementation logic (working mode).

| Where | Change | Owner |
|---|---|---|
| setup (after `source()` block, ~l.95) | source `revalidationConfig.R`; one `figDir` (`analyses/Figs`); add `outDir`, `runFigDir`, `fitCachePath` | me |
| l.102–250 | replace with `source("analyses/R_tools/buildModelData.R")` (section 3) | me |
| subsampling chunks + `set.seed(123)` | remove; holdout exclusion + one shared `na.omit()` over all candidates | you |
| regex column selection (scope building) | → `revalCfg$predSets` | you |
| `nonspatialpreds` base selection | `k = log(n)`, on the shared row set | you |
| `readRDS("analyses/model8_4FULL.rds")` | → new base model (W2) | you |
| `saveRDS`/`readRDS`/`sink`/`tiff` after `## here!!` | use `outDir`/`runFigDir` as you rewrite; I check in review | you |
| `crossValidFunction()` calls | pass seed/folds | you |

Other files:
- `R/R_tools/crossValidFunction.R` l.56: replace the hard-coded `set.seed(123)` with a `seed` argument and add grouped folds. Owner: you.
- Unchanged: `analyses/R_tools/DAfires_dataPrep.R`, `R/R_tools/Neighbourhood_functions.R`, the legacy Rmds.
- Bookkeeping (me): `analyses/.gitignore`, the main plan, the run log, AGENTS.md.

## 5. Caches

1. Data stays in `analyses/cacheNEW` with its pinned IDs. Don't move cache folders.
2. Fits go to `fitCachePath` (`outputs/gamlss/cache`), passed as `cachePath =` to the fitting `Cache()` calls only. This cache can be wiped without losing the data build.
3. Changed arguments (seed, holdout, column sets) trigger recomputes by design. Old cache entries become orphans, not errors.
4. Pinned `cacheId`s skip the input check. Keep them only on the data objects, where the inputs don't change.
5. Fitting chunks use `cache = FALSE` so knitr's cache doesn't serve stale objects on top of `reproducible`'s.

## 6. Deferred: Boost Rmd re-activation (to-do, not current work)

- Source the config and `buildModelData.R` in place of its `dataprep`/`addNgbNoBurns` chunks (l.95–144). This drops its own `ngbNoBurns` ID `9a366f60217632b1`.
- Rename `buffer_*` → `ngbPropBurns_*` (l.524–532, 1003–1009). Use `revalCfg$predSets` instead of the `"buffer"` regex (l.320–340).
- Switch `reproducible.cachePath` from `analyses/cache` (corrupted) to `cacheNEW`. Add `outDir`/`runFigDir`/`fitCachePath`, and split `figDir`/`figDir2`.
- `runXGBOOST` (`Useful_functions.R`):
  - Seed argument instead of `set.seed(12345)` (l.451).
  - **Remove the pinned tuning `cacheId`s** (`8a518e3d96830586`, `cd64c0826cfcecc2`, `3499577823e6a19d`; l.671–762). They would return the old full-data tuning, which is silent leakage (W4, confirmed).
  - Leave `runGPBOOST` alone.
- Point the GAMLSS-comparison reads (l.557, 1012, 1040) at the new GAMLSS outputs.

## 7. Open warning

- **W2:** `model8_4FULL.rds` was fitted on pre-fix data. It will be replaced by the base model re-selected on the calibration rows (no subsampling, `k = log(n)`). Until then, don't use its fitted object as the `stepGAICAll.A()` start model.

Resolved 2026-11-16:
- **W1:** both Rmds use data `cc55d7d2a817284e`.
- **W3:** adopted as section 3.
- **W5:** `buffer_` names exist only in the Boost Rmd; deferred to section 6.
- **W6:** the GAMLSS `ngbNoBurns` ID is the reference.

## Open decisions

1. OK for me to write `revalidationConfig.R` and `buildModelData.R` and do the "me" rows in section 4?
2. Separate fit cache per framework under `outputs/<model>/cache` (recommended), or keep everything in `cacheNEW`?
