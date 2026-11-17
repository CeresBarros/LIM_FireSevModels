# Plan: archive legacy outputs, figures, scripts and cache

Status: **proposal, awaiting final approval** (2026-11-17). Rows numbered for review.

Layout: `analyses/archived/` mirrors `analyses/` (outputs and scripts in `archived/`, figures in `archived/Figs/`, old cache in `archived/cache/`).

Cache rule (user, 2026-11-17): active scripts use the new `analyses/cache` (ex-`cacheNEW`) and are re-run against it; archived scripts point to `analyses/archived/cache`.

| # | Item | Action | Scripts / places to update |
|---|---|---|---|
| **Model outputs → `analyses/archived/`** | | | |
| 1 | `model8_4.rds` | move | Archived Rmds (row 21) |
| 2 | `model8_4FULL.rds` | move | `_ngbAvg.Rmd` l.257 → `analyses/archived/model8_4FULL.rds` (until W2 replaces it) |
| 3 | `modelNgbSev4FULL3.rds` + `_RESIDS.tif`, `_SUMMARY.txt`, `_crossValidOutputs.txt` | move | Archived Rmds (row 21) |
| 4 | `modelNgbSev4FULL4.rds` + `_RESIDS.tif`, `_SUMMARY.txt`, `_crossValidOutputs.txt` | move | Archived Rmds (row 21) |
| 5 | `modelNgbSev4FULL4Scaled.rds` + `_RESIDS.tif`, `_SUMMARY.txt`, `_CONFMATRX.txt`, `_obsVSpred.tif`, `_crossValidOutputs.txt` | move | Archived Rmds (row 21). Boost Rmd l.558–559, 1013, 1022, 1026, 1041: deferred to re-activation (paths break meanwhile) |
| 6 | `modelsGAMLSS_0-3Days_20m_goodSample_Nov1.RData` (37 GB) | move | None (commented-out lines only) |
| 7 | `modelsGAMLSS_allWeatherDays_20m_badSample_Oct10.RData` (14 GB) | move | None |
| 8 | `GPBoost/` | move → `archived/GPBoost/` | None |
| **Intermediates** | | | |
| 9 | `fireDataSummary/` | move | `DAfires_expAnalyses_BAD.Rmd` l.85 → `analyses/archived/fireDataSummary/` |
| 10 | `FireEvents/` | **keep** | — |
| 11 | `firesInFMAs/` | **keep** | — |
| 12 | `DAfires_expAnalyses_cache/`, `DAfires_expAnalyses_files/` | move | None (re-knit recreates them) |
| 13 | `DAfires_sevModels_cache/` | done (deleted by user) | — |
| 14 | `DAfires_expAnalysesGood.html` | **keep** (to be re-run) | — |
| **Figures** | | | |
| 15 | Legacy GAMLSS figures not in the manuscript (`p0/p1/meanSev/muSev/varSevPlots_`, `muSevPEFPlots_`, `*PEFPlotsNotForest_*` except `varSev…1`, `varSevPEFPlots_…1`, `varSevPEFPlots_…`) | move → `archived/Figs/` | Archived Rmds via `figDir` (row 21) |
| 16 | Manuscript-cited: `crossValidPlot_`, `meanSevPEFPlots_`, `p0PEFPlots_`, `p1PEFPlots_`, `varSevPEFPlots_…2`, `varSevPEFPlotsNotForest_…1`, `severityMaps_highAgreement` | move → `archived/Figs/` | `manuscript/manuscript.qmd` l.435–475 (7 paths) → `../analyses/archived/Figs/…` |
| 17 | `firesEcozonesNatRAB.png` | **keep** | — |
| 18 | `firesEcozones.png`, `severityMaps_lowAgreement.png` | **keep** | — |
| 19 | `PCAforest*` (5 files) | move → `archived/Figs/` | None (`DAfires_expAnalyses.Rmd` regenerates them) |
| 20 | `tuning_learningRate.png`, `Figs/XGBoost/`, `Figs/GPBoost/` | move → `archived/Figs/` (with subfolders) | None |
| **Scripts → `analyses/archived/`** (`git mv`; staging needs approval) | | | |
| 21 | `DAfires_sevModels.Rmd`, `DAfires_sevModelsGAMLSS.Rmd` | move | Path strings only: model files → `analyses/archived/…`; `figDir` → `analyses/archived/Figs`; `analyses/cache` → `analyses/archived/cache` (`sevModels.Rmd` l.55, 129, 296, 306, 330; `GAMLSS.Rmd` l.63, 81, 156, 166, 190) |
| 22 | `DAfires_expAnalyses_BAD.Rmd` | move | l.85 (row 9); l.30, 54 → `analyses/archived/cache` |
| 23 | `plot_4DaveFeb19.R`, `plot_ESAexperiment.R` | move | ESA l.128, 134 → `analyses/archived/ESA_mapsFig.png` |
| **Docs** | | | |
| 24 | README.md, `_ngbAvg.Rmd` l.227, AGENTS.md | edit | README: rewrite layout section explaining the `analyses/` hierarchy (active scripts, `R_tools/`, `templates/`, `outputs/<model>/`, `cache/`, `Figs/`, `archived/` mirroring `analyses/`). `_ngbAvg` l.227: update the mention of `DAfires_sevModelsGAMLSS.Rmd`. AGENTS.md: Analyses table, Caching section, legacy inventory |
| 25 | `analyses/.gitignore` | edit | Add `archived/cache`, `archived/GPBoost/*`, `archived/*_cache`, `archived/*_files` |
| **Caches** | | | |
| 26 | `cache/` → `archived/cache/` | move, then `reproducible::movedCache(new = "analyses/archived/cache", old = "analyses/cache")` (SQLite backend; `cache.db`) | Verify by loading one entry |
| 26b | `cacheNEW/` → `cache/` | rename (after 26) | File-based backend (`multifileDB.txt`); check whether `movedCache()` is needed, then verify by loading `cc55d7d2a817284e` and `c7536dcb493ad453` |
| 27 | Active scripts on `cacheNEW` | edit → `analyses/cache` | `_ngbAvg.Rmd` l.83–84 (drop commented line + "screwed up" note); `DAfires_collinearityCheck.Rmd` l.80–81; `DAfires_dataDictionary.Rmd` l.50, 70 |
| 28 | Active scripts already on `analyses/cache` | no edit; re-run against new cache | `DAfires_expAnalyses.Rmd` l.33; `FiresDA_FMAs.R` (fixed by user); Boost Rmd l.77, 151, 163, 193 (untouched; re-run at re-activation) |
| 29 | Plans | edit | `2026-10-30-outputs-config-plan.md` l.80, 90; main plan / run log: `cacheNEW` → `cache` |
| 30 | **Not moved:** `fireDataJoins/`, `FireEvents/`, `firesInFMAs/`, `outputs/`, `templates/`, `R_tools/`, active Rmds/scripts (incl. `FiresDA_FMAs.R`), `validationDesign.png/.mmd`, `analyses.zip` | — | — |
