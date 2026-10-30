# Plan: output folder + shared config for the re-validation runs

Sub-plan of `2026-10-29-1508-plan.md`. Status: **proposal, awaiting approval**. Nothing has been created, moved or edited yet.

Revision 2026-10-30 (user feedback): no `data/` output folder; paths set at the top of each Rmd, not in the config; data `cacheId`s stay where they are, not in the config.

## 1. New folders

```
analyses/
  outputs/                      # gitignored (new rule in analyses/.gitignore)
    revalidation/
      gamlss/     # fitted models, summaries, CV results; figs/ and cache/ subfolders
      xgboost/    # fitted models, tuning results, SHAP, CV results; figs/ and cache/ subfolders
      holdout/    # final holdout predictions + metrics
```

- Manuscript figures keep going to `analyses/Figs/` (like Figures 1–8 and `validationDesign`). Diagnostic/run figures go to each framework's `figs/` subfolder.
- No `data/` folder: the input data is already saved and the pre-processing is cached (`analyses/cacheNEW`). Holdout IDs live in the config; fold assignments are recomputed deterministically from the seed and fire list, so neither needs saving.
- File naming: `<model>_<set>_<what>.<ext>`, e.g. `gamlss_ringNgb_stepGAIC.rds`, `xgboost_oldNgb_cvMetrics.rds`. The run log records each path.
- `analyses/.gitignore` already ignores `*.rds/*.txt/*.png/*.tif`. Add an explicit `outputs/` rule so nothing in there gets committed by accident.

## 2. Shared config file (tracked)

`analyses/R_tools/revalidationConfig.R`, sourced by both Rmds right after the other `source()` calls. It holds **only the settings that must be identical across GAMLSS and XGBoost**, so the two comparisons can't drift apart. It defines a single list, `revalCfg`:

| Element | Value | Status |
|---|---|---|
| `seed` | one project seed (random integer) | set now |
| `holdoutFires` | `FIRE_NAME`s | `NA` placeholder until open decision 1 |
| `nFolds` / fold type | grouped by `FIRE_NAME` | placeholder until open decision 2 |
| `predSets$oldNgb` | explicit `ngbPropBurns_<d>m` column names | set now (from `bufferDists`) |
| `ringVars` + `predSets$ringNgb` | the non-climatic variable list averaged in rings (decision 9), and the resulting `<var>_<d>m` column names (dummy columns for `LandCover`/`DIST1`) | once the dummy and `Aspect` sub-choices are made |
| `bufferDists` | 30 × 2^(0:6) | set now (currently duplicated in 3 chunks/2 Rmds) |

Explicitly **not** in the config:
- **Paths** (output folder, figure folder, fit cache). These differ between the two frameworks, so each Rmd sets them in its setup chunk, e.g. `outDir <- "analyses/outputs/revalidation/gamlss"`, `runFigDir <- file.path(outDir, "figs")`, `fitCachePath <- …`. Only the shared parent (`analyses/outputs/revalidation/`) is a convention, recorded here and in AGENTS.md.
- **Data `cacheId`s.** These stay at their `Cache()` calls (in the Rmds) and inside the sourced functions. Moving them would add indirection without stopping drift. The one cross-script requirement is that both Rmds load the **same** data build (W1); check that directly rather than through the config.

Other notes:
- Explicit column lists replace the regex `_[[:digit:]]{2,4}m$`, which matches both sets (caveat C1).
- Contains settings only, no functions. It gets a roxygen-style header block, and the R file is written via heredoc per AGENTS.md.

## 3. Existing files: move or not?

The ~50 GB of legacy outputs sit loose in `analyses/` (`model8_4*.rds`, `modelNgbSev4FULL*`, `*_SUMMARY.txt`, `*_RESIDS.tif`, `*.RData`).

| Option | Effect |
|---|---|
| **A. Leave in place (recommended)** | Nothing breaks; new outputs are cleanly separated. The legacy Rmds keep working. |
| B. Move to `analyses/outputs/legacy/` | Tidier, and `mv` is cheap on the same filesystem. Breaks hard-coded paths: the active GAMLSS Rmd (l.354 `model8_4FULL.rds`), the Boost Rmd (l.557, 1012, 1040 → `modelNgbSev4FULL4Scaled*`), and the legacy Rmds (`DAfires_sevModels*.Rmd`, many lines). All would need updating. |

None of the active Rmd's outputs (`modelNgbAvg4FULL4*`) exist on disk yet, so there is nothing new to move.

## 4. Script changes (all places found)

**Owner** column: "me" = config/path plumbing I can do if you approve; "you" = implementation logic, per the working mode.

### `analyses/DAfires_sevModelsGAMLSS_ngbAvg.Rmd` (active)
| Line(s) | Change | Owner |
|---|---|---|
| after 87 | `source("analyses/R_tools/revalidationConfig.R")` | me |
| 71–72, 91 | `figDir` defined twice; keep one (manuscript figures, `analyses/Figs/`). Add local `outDir`, `runFigDir` and `fitCachePath` for the GAMLSS outputs in the setup chunk | me |
| 76 | `reproducible.cachePath = "analyses/cacheNEW"`: unchanged | — |
| 106, 147, 191 | pinned data `cacheId`s: unchanged | — |
| 125–128, 177–180 | `bufferDists` loops → `revalCfg$bufferDists` | me |
| 164–193 | ring averages: `vars` → all non-climatic candidates (`revalCfg$ringVars`), dummy-code categoricals, handle `Aspect`, change/remove the pinned `cacheId` (l.191) | **you** |
| 224–231, 332–339 | subsampling chunks (and their `set.seed(123)`) are removed (main plan step 4). Replace with holdout exclusion (`revalCfg$holdoutFires`) + one shared `na.omit()` over all candidate columns | **you** |
| 222, 359–374 | regex column selection → `revalCfg$predSets` | **you** (methodological, step 3) |
| 300–317 | base-model selection: add `k = log(n)` (default k = 2 now), run on the shared row set | **you** |
| 354 | `readRDS("analyses/model8_4FULL.rds")` → replaced by the new base model from l.300–317 (W2) | **you** |
| 447–505, 522, 545–549, 572, 631, 653, 669, 723, 736, 800, 2997 | `saveRDS`/`readRDS`/`sink`/`tiff` paths → `file.path(outDir, …)`. These chunks are after `## here!!` and will be rewritten by you, so use `outDir` as you rewrite them; I'll check paths in review rather than edit lines that are about to change | you (I review) |
| 574–588, 671–689 | `crossValidFunction(...)` calls: pass seed/folds once the function takes them | **you** |

### `analyses/DAfires_sevModelsBoost.Rmd`
| Line(s) | Change | Owner |
|---|---|---|
| after the `source()` block (l.81–86) | source the config | me |
| 77 | `reproducible.cachePath = "analyses/cache"` (flagged corrupted): decide after W1 whether to switch to `analyses/cacheNEW`. Add local `outDir`/`runFigDir`/`fitCachePath` for the XGBoost outputs | you decide; me for paths |
| 106 | data `cacheId = "0a70f8b25dc39895"`: stays local, but must load the same build as GAMLSS (W1) | **you** decide |
| 117–141 | `bufferDists` → config; old-ngb columns named `buffer_<d>m` here vs `ngbPropBurns_<d>m` in GAMLSS → standardise on `ngbPropBurns_` | me |
| — | **ring-averaged predictors are never computed in this Rmd**; Ring-ngb can't be fitted yet; see W3 | **you** |
| 320–340 | regex column selection (`"buffer"`) → `revalCfg$predSets` | **you** |
| 346, 398–451, 645 | `figDir`/`figDir2` → manuscript figures in `analyses/Figs/`, run figures in local `runFigDir` | me |
| 557, 1012, 1040 | reads legacy GAMLSS outputs for comparison → point at the new GAMLSS outputs once they exist | me, later |

### `R/R_tools/crossValidFunction.R`
| Line | Change | Owner |
|---|---|---|
| 56 | `set.seed(123)` hard-coded; needs a `seed` argument (signature change) and the grouped folds (plan step 2) | **you** |

### `R/R_tools/Useful_functions.R`
| Line | Change | Owner |
|---|---|---|
| 451 | `set.seed(12345)` in `runXGBOOST` → seed argument | **you** |
| 671–762 | pinned tuning `cacheId`s; see W4 | **you** |
| 855 | `set.seed(12345)` in `runGPBOOST`: **leave** (GPBoost abandoned) | — |

### Not changed
`analyses/R_tools/DAfires_expAnalyses_dataPrep.R` (already takes a `seed` argument, l.919–921), legacy Rmds, `R/R_tools/Neighbourhood_functions.R`.

### Bookkeeping (me)
`analyses/.gitignore` (+`outputs/`), main plan (link to this sub-plan, tick off), run log (path conventions), AGENTS.md (config + folder layout).

## 5. Effects on caches

1. **Data objects stay in `analyses/cacheNEW`**, with their `cacheId`s left in place. Nothing about the data cache changes, so the 3.7 GB of cached data (`185c…`, `e668…`) loads as before. Don't move cache folders: `reproducible` locates entries relative to the cache path.
2. **Fits get their own cache**, set per Rmd (`fitCachePath`, under `outputs/revalidation/`). Pass it as `cachePath =` to the fitting `Cache()` calls only; the global `reproducible.cachePath` stays on the data cache. It can be wiped between iterations without losing the data build, and it keeps new fits from mixing with older entries in `cacheNEW`.
3. **Expected recomputes, by design**: anything whose arguments change. Adding a `seed` argument, removing the holdout fires and new column sets all change the digest, so `crossValidFunction` and `runXGBOOST` results recompute. Old entries become orphans, not errors.
4. **Pinned `cacheId`s skip the digest, which is the main risk** (W4). A pinned `cacheId` returns the stored object even when the inputs changed.
5. **knitr chunk cache**: the Rmds set `cache = 2` globally. Fitting chunks should use `cache = FALSE` so knitr's cache doesn't sit on top of `reproducible`'s and serve stale objects. Data chunks already use `cache = FALSE`.

## 6. Warnings found while surveying (proactive flags)

- **W1. The Boost Rmd may use the pre-bugfix data.** It loads `summaryABSK_AllData` with `cacheId = "0a70f8b25dc39895"` from the old `analyses/cache`, while the GAMLSS Rmd uses `185c1b8db3c9788d` from `cacheNEW`. These may be different builds, and the old one may predate the land-cover fix. Check this read-only before anything else (row counts, number of `isForest == 0` pixels in SK). Both workflows must use the same data object.
- **W2 (largely covered by the user's in-progress work). The base model `model8_4FULL.rds` (Mar 2026) was fitted on the earlier data.** The `_ngbAvg.Rmd` chunks from the `## here!!` marker (l.321) onward have not been redone yet; the user's intended flow re-runs the non-neighbourhood selection (`nonspatialpreds`, l.300–317) on the new data, and that model replaces `model8.4` as the base. Confirmed 2026-10-30: that selection runs on the calibration rows only, without subsampling, and with `k = log(n)` (tasks in the main plan, step 4). Original note: It is the starting point for both Old-ngb and Ring-ngb selection (l.354), but it doesn't include the restored non-forest pixels or the holdout split. It is read for its formulas (l.356–374), but the **fitted object** is also the start model passed to `stepGAICAll.A(model8.4, …)` (l.377). Its formula can be reused, but it should be refitted on the calibration rows before `stepGAICAll.A()`; the start model's GAIC then comes from the same rows as the candidate models. Otherwise the GAIC comparison starts from a model fitted to different rows (cf. the identical-rows requirement).
- **W3. Ring-averaged predictors exist only in the GAMLSS Rmd.** Better structure: one shared data-assembly script (e.g. `analyses/R_tools/buildModelData.R`), sourced by both Rmds. It would load the cached data objects, join the Old-ngb and Ring-ngb columns, and add the holdout flag and fold IDs from the config. Nothing new is written to disk, since everything comes from the existing caches. Both Rmds then build an identical table (fixes W1 and W5 as well).
- **W4. Pinned `cacheId`s on the tuning steps in `runXGBOOST`** (`8a518e3d96830586`, `cd64c0826cfcecc2`, `3499577823e6a19d`) would return the old full-data tuning even after holdout removal or the switch to nested CV. That is silent leakage. They must be removed or disabled for the re-validation. The data `cacheId`s (`185c…`, `e668…`, `c753…`) are fine to keep pinned where they are, because the data inputs don't change.
- **W5. The ngb columns have inconsistent names** (`buffer_<d>m` vs `ngbPropBurns_<d>m`) across the two Rmds. The Old-ngb definition in the config fixes this only if the Boost Rmd renames its columns too.

## Decisions needed before implementing
1. Legacy files: leave in place (A) or move (B)?
2. OK for me to write the config file and do the remaining "me" plumbing (sourcing the config, `figDir`, `bufferDists`, Boost column naming), or do you want to write these too?
3. W1: should I run a read-only check comparing the two data caches?
4. Separate fit caches per framework under `outputs/revalidation/<model>/cache` (recommended), or keep everything in `cacheNEW`?
