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
| `DAfires_sevModelsBoost.Rmd` | active | XGBoost severity models (GPBoost sections abandoned Oct 2026; leave untouched) |
| `DAfires_expAnalyses.Rmd` | active | Exploratory analyses of fire severity data |
| `DAfires_collinearityCheck.Rmd` | active (new, Oct 2026) | Collinearity among topographic, weather and vegetation candidates; exports `analyses/outputs/nonCollinearVars.rds` (gitignored) used to build the model candidate list. Co-authored by the assistant. |
| `plot_validationDesign.R` | active (new, Oct 2026) | Regenerates the pinned methods figure `analyses/Figs/validationDesign.png` |
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

- **Caveat (2026-10-30): the `packages/<platform>/4.6/` library is empty**, and `/usr/bin/R` is still R 4.5.3 (R 4.6.1 is at `/opt/R/4.6.1`). In practice all work so far runs on R 4.5.3 with the `4.5/` library; the 4.6 library needs populating before switching.
- R 4.6 (4.6.1 on this machine) is the current development target — upgraded from R 4.5 (Oct 2026). `.Rprofile` now resolves libraries to `packages/<platform>/4.6/`; the old `4.5/` library is still on disk.
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
- `0_dataPrep_projections.R` uses the old `raster` / `sp` / `shapefile()` API and was written for R 3.4; expect to modernize before rerunning under R 4.6.
- Two `*_FIXED.R` helpers patch upstream `gamlss`/`gamlss.inf` bugs — keep them sourced whenever the active GAMLSS Rmd is run.
- `simLinks.sh` is present but not currently used; ignore its paths.
- `R/R_tools/inputMaps.R` was **removed** (Aug 2026) as dead code: its four `sp`/`raster`/`rgeos`-based study-region helpers (`loadShpAndMakeValid`, `loadStudyRegions`, `shpStudyRegionCreate`, `createPrjFile`) had no callers here, and a cross-repo check of the upstream `LandscapesInMotion` confirmed they were unused on the `development`, `master`, and `xgboost` branches too. Recover from git history if study-region loading is ever needed (expect to modernize to `sf`/`terra`/`geodata`). `moduleSticker.R` was deleted earlier by the user.

## Manuscript

`manuscript/manuscript.qmd` is a Quarto document using the Elsevier journal
format (`quarto-journals/elsevier` extension, vendored and committed under
`manuscript/_extensions/quarto-journals/elsevier/`). It holds the **full
text of `manuscript/old/FireSeverity_MS.pdf`** ("Predictive models of fire
severity: from complex distribution modelling to machine learning"),
transcribed section-by-section (Introduction through Discussion, References,
Tables 1–4, Figure captions, Appendices 1–3), not just the extension's
starter placeholder content.

- Render with `quarto render manuscript/manuscript.qmd` from the repo root
  (or `cd manuscript && quarto render manuscript.qmd`). Produces
  `manuscript.pdf` via TinyTeX/XeLaTeX; TinyTeX (v2026.01) is already
  installed on this machine, no LaTeX setup needed.
- Bibliography: `manuscript/references.bib`, cited with `@key` and
  natbib/`elsarticle-harv.bst` (author-year style, set via
  `format.elsevier-pdf.journal.cite-style: authoryear` in the YAML).
  Most in-text citations have been converted from the original
  `[CITE: Author-YYYY]`/`[REF]` transcription placeholders to real pandoc
  `@key`/`[@key]` citations, and `references.bib` now has matching bib
  entries for most of them (including `andison2012` and
  `forestrycanadafiredangergroup1992`, added 2026-09-28). The reference
  list **does render** — BibTeX/natbib populate it at the `\bibliography{}`
  command's location in the generated `.tex` (near the very end, after
  Appendix 3's supplementary figures — e.g. page 46 of 50 in the last
  render), independent of any `# References` markdown heading, which is
  just inert text.
  - **Still outstanding**: a few in-text citations remain as stray
    backslash-escaped text (`\@key`, `\[\@key\]`) rather than real pandoc
    citations, so pandoc treats them as literal punctuation and they don't
    resolve — e.g. `\@ferster2016`, `\[\@ferster2016\]`, `\@ferster2026`
    (also a typo — no such key exists, only `ferster2016`), `\[\@ospina2010\]`,
    `\[\@stasinopoulos2007\]`, `\[\@stasinopoulos2017\]`. Grep for `\\@` to
    find remaining instances.
  - Minor BibTeX field-quality warnings persist on render (don't block
    output, but produce slightly malformed entries): trailing comma after
    the sole author name in `batunacun2021` and
    `forestrycanadafiredangergroup1992`; empty `journal`/`booktitle` in
    `amiro2001`/`chen2016`/`smithson2013`; missing `institution` in
    `cosco2011`/`kuhn2022`; `goldstein2005` sets both `author` and `editor`
    (BibTeX only uses one) and has empty `chapter`/`pages`.
  - Four citations (Belote et al. 2015, Lydersen et al. 2016 — Discussion,
    pre-fire vegetation/tree-density effects on post-fire mortality; Bolker
    et al. 2009, McCullagh & Nelder 1989 — Methods, GLM framing of beta
    regression) were cited in the original PDF's body but absent from its
    own reference list; their bib entries have since been added
    (`belote2015`, `lydersen2016`) or may still need tracking down — check
    current `references.bib` and `manuscript.qmd` for `TODO` markers before
    assuming these are resolved.
- **Known design issue, not yet fixed**: the document currently produces a
  single combined reference list covering both the main text and the
  Appendices. The user wants **separate reference lists for the main text
  and for the Appendices** and is manually splitting `manuscript.qmd` into
  separate Quarto documents (one for main text, one for appendices) to
  achieve this — **the user is doing this split themselves; do not
  attempt it.**
- Figures (Fig. 1–8, S2.1–S2.2, S3.1–S3.8): Figures 1–8 now reference real
  image files under `../analyses/Figs/` (e.g.
  `analyses/Figs/firesEcozonesNatRAB.png`); the supplementary figures
  (S2.1–S2.2, S3.1–S3.8) still use `*[FIGURE PLACEHOLDER: fig-id]*` markers
  pending images.
- The upstream template's example content included R chunks
  (`knitr::kable()`, `plot()`) to generate a demo figure/table; those were
  removed (replaced with static markdown figure/table placeholders, then
  with the real manuscript content) because this R installation's library
  path lacks `knitr`/`rmarkdown`. Install those packages first if executable
  R chunks are wanted later.
- Journal formatting is controlled by the Elsevier `elsarticle.cls` LaTeX
  class shipped with the extension (`manuscript/elsarticle.cls`), not by
  Quarto/pandoc defaults — margins, headers, and title-page layout follow
  Elsevier's house style via the `journal.formatting` YAML key (currently
  `preprint`; do not also set `journal.model` alongside `preprint` — they're
  mutually exclusive per the class).
  - Author affiliation markers use `classoption: numafflabel` (numbered
    superscripts) instead of the class's own default (lettered
    superscripts, `\alph{affn}`) — this is a class-level option, not a
    Quarto/extension default.
  - Section numbering is explicitly disabled with `number-sections: false`
    in the document YAML — the extension's `_extension.yml` defaults this
    to `true`, but numbering is not enforced by `elsarticle.cls` itself.
- **Page breaks and landscape pages (done, 2026-09-25)**: `{{< pagebreak >}}`
  shortcodes precede every table caption (Tables 1–4), every figure
  placeholder/caption (Figures 1–8, S2.1–S2.2, S3.1–S3.8), and every
  Appendix heading (1, 2, 3). Table 1, Figure 8, and Figure S3.8 are each
  wrapped in a raw-LaTeX `` ```{=latex} \begin{landscape} ... \end{landscape} ```
  block so those pages render rotated; this requires `\usepackage{pdflscape}`,
  added via `include-in-header` in the YAML (`elsarticle.cls` doesn't ship
  landscape support itself). Verified by rendering to PDF and confirming
  rotated pages carry `/Rotate 90` via `qpdf --qdf`.
- **Table 3 fixed (2026-09-28)**: was originally left as prose text instead
  of a Markdown table; converted to a proper table (grouped by severity
  component — Expected mean, p0/p1, Expected variance — each with ZOIB
  parameters and a covariate-importance list as rows), matching the source
  PDF's Table 3 layout. No other part of the file was touched in that pass.
- Plan for this setup is archived at
  `.posit/assistant/plans/archive/2026-09-15-1533-quarto-elsevier-manuscript.md`.



## Assistant conventions in this repo

- Edits to `*.md` are pre-approved via `.posit/assistant/settings.json`; other file edits should be surfaced before writing.
- Prefer plan-then-implement flow; plans live under `.posit/assistant/plans/`.
- **Document R functions with `#'` roxygen blocks, always.** This is unconditional — it does not depend on whether the code lives in a package. Two distinct kinds of `##` comment must not be confused:
  - **Pre-function `##` doc-style headers** — the `##`-prefixed lines *above* a function that describe it or its parameters (e.g. `## sp: is the species code`). These are legacy documentation: **convert them into the roxygen block and remove the originals**, so roxygen is the single source of truth. Do not leave them sitting alongside the roxygen, and do not substitute them (or a summary index) for per-function roxygen.
  - **In-function `##` comments** — `##` comments *inside* a function body that explain steps of the code (e.g. `## convert to CAPS`). These are ordinary code comments: **preserve them as-is**; they are not documentation to migrate.
  - Removing superseded pre-function `##` headers (and adding missing docs) is in scope for a documentation task — the heredoc-only rule below is about the editing *tool*, not a limit on touching comment lines.
- **Never modify R files with the `edit`/`write` tools — they trigger format-on-save (Air-style) reformatting even though Air is nominally disabled, producing large unwanted whitespace/brace/argument-splitting diffs.** Edit R files via a `bash` heredoc or an in-place `python3` script instead, so the editor formatter never runs.
- **After any R-file change, verify the diff is comment-only** with `git diff <file> | grep '^[+-]' | grep -v '^[+-]#'` (expect no output) and check `git diff --stat`. Confirm zero incidental deletions and that function signatures/bodies are untouched.
- **Preserve original code style when documenting** — do not reformat: keep original function signatures, single-line `if`/`else` (do not add braces), original operator spacing, and original blank-line layout. Only comment/`#'` lines should change (this includes removing superseded pre-function `##` doc headers, per above; in-function `##` comments stay).
- **Internal helpers always get `@keywords internal` (and only that — never `@noRd` alongside it, since `@noRd` suppresses the `.Rd` entirely and would override `@keywords internal`).** This applies to every non-user-facing (internal) function — not just `.`-prefixed helpers but also the internal recoders and any function only called internally by a wrapper (e.g. the CASFRI internal recoders, `calcCrossValidMetrics`, `joinPerFire`). Exported/user-facing wrappers, the `_FIXED.R` shims, and plotting/analysis entry points do **not** get this tag. When documenting a new function, decide its tier first (exported/user-facing vs. internal) and tag accordingly.
- **Other roxygen conventions**: preserve `@author` attributions; inherit upstream parameter docs with `@inheritParams pkg::fn` rather than duplicating; for the `_FIXED.R` shims add an `@note` describing the upstream bug and target version and `@seealso` the patched original (`gamlss::Rsq`, `gamlss.inf::summary.gamlssinf0to1`). Document best-guess argument shapes with a `# TODO: confirm` marker; fix wrong `@param` names/descriptions but **never reorder arguments in code**. CASFRI docs are tiered (see Stage 3 below): full roxygen for the 5 wrappers, short title + `@param` for the 17 internal recoders.
- **Never run R in the shared console (`executeCode`)** — it targets whichever console is in the foreground, which may be the user's session, so parallel work collides (agreed 2026-10-30). Instead run R outside the IDE: a persistent background `tmux` session (`pa-R`, started in the repo root) fed by a small send-and-capture helper script kept in the assistant's scratch directory, or one-off `Rscript` calls (e.g. for knitting). Never write objects to the user's session.
- **Git safety: never stage, commit, or push without explicit permission.** Before any `git add`/`git commit`/`git push`, stop and ask. Draft the proposed commit message and present it for review/approval. After the user approves, re-confirm approval immediately before running the commit or push. (Enforced in `.posit/assistant/settings.json`: `git add`/`commit`/`push` are set to `"ask"`.)
- **Flag known code issues rather than touching them**: `browser()` calls in `crossValidFunction.R` (`calcCrossValidMetrics`, ~line 161) and `Useful_functions.R` (`runXGBOOST` ~517, `runGPBOOST` ~785/~832) are **intentional markers of code still in development** — never remove them unilaterally; the user finishes that logic; `xgboostConfMat` returns only its last expression (`confMatrix`) with no explicit `return()`, inconsistent with `gpboostConfMat` which returns `list(validMetrics, confMatrix)`; hard-coded `set.seed(123)` in `crossValidFunction`.

## Documentation pass status

Staged roxygen documentation of `R/R_tools/` and `analyses/R_tools/` (plan under `.posit/assistant/plans/`):

- **Stage 1 — done**, committed as `f503e1c` ("doc clean-up. Stage 1."): `joinSevVegTopoWeatherData.R`, `Neighbourhood_functions.R`, `crossValidFunction.R`, `prepFireWeather.R`, `prepCorrTable.R`, `getPEF_own.R`, `Rsq_FIXED.R`, `summary.gamlssinf0to1_FIXED.R`.
- **Stage 2 — done**, committed as `f0fa101` ("doc clean-up. Stage 2: Useful_functions.R"): all 16 functions in `Useful_functions.R` given per-function `#'` roxygen (full blocks for exported functions; `@keywords internal` for the 5 internal helpers; `@inheritParams runXGBOOST` for `.tunexgboost` and `runGPBOOST`; filled-in `@return` for the previously-empty `xgboostConfMat`/`gpboostConfMat` stubs; an `@note` flagging `xgboostConfMat`'s missing explicit `return()`). Comment-only diff; parses under R.
- **Stage 3 — done**: `CASFRIrelated_functions.R` (22 functions total; tiered — full roxygen for the 5 wrappers, short title + `@param` for the 17 internal recoders). `getPEF.own` in `getPEF_own.R` was already fully documented back in Stage 1 (`f503e1c`), so no further Stage 3 work remained.
  - **Part 1 done** (`0ae2fe2`, "doc clean-up. Stage 3 (part 1): CASFRI wrappers"): full `#'` roxygen for the 5 wrappers (`invent2CASFRI`, `ABToCASFRI`, `SKToCASFRI`, `meltPreFireABInv`, `meltPreFireSKInv`); fixed a `CASFIR`→`CASFRI` header typo.
  - **Part 1b done** (`917cfd2`, "doc clean-up. Stage 3 (part 1b): DRY the CASFRI wrapper roxygen with @inheritParams"): `SKToCASFRI`/`meltPreFireABInv` inherit shared params from `ABToCASFRI`; `meltPreFireSKInv` inherits from `meltPreFireABInv`; `ABToCASFRI`'s `@param inv` made province-neutral so SK wrappers inherit `inv` without a local override.
  - **Part 2 done** (`29afc37` "CASFRI internal funs docs #1", `c3c2d14` "doc: drop legacy ## doc headers…", `38a8a11` "consistent references to perl functions and CASFRI"): short title + `@param` roxygen for the 17 internal recoders (`spLatinName`, `TypeForest`, `spPercent`, `spPercentAdjust`, `originUpper`, `originLower`, `nonVegNatSK`, `nonVegAnthSK`, `nonForestVegSK`, `wetlandCodesSK`, `wetlandCodesSK2`, `wetlandCodesAB`, `soilMoistureRegime`, `NFLAdjustAB`, `SMRAdjustAB`, `addWaterInfo`, `correctCSGPFTTYPE`), all tagged `@keywords internal` and DRYed with `@inheritParams` (`spPercent` anchors the shared `province`/`MISSCODE`/`ERRCODE`). Stripped all `@noRd` lines repo-wide (`674ab74`), keeping `@keywords internal` only. Removed the legacy pre-function `##` doc headers that duplicated the new roxygen, and normalized `.pm`/CASFRI-manual wording (`38a8a11`). Comment-only diffs; all files parse.
  - **Stage 4 — done** (`a113253`, "doc clean-up. Stage 4: analyses/R_tools/ data-prep roxygen"): `analyses/R_tools/`. `DAfires_expAnalyses_dataPrep.R` — full roxygen for `ABSKfires_DataPrep` (user-facing orchestrator; legacy `##` header migrated) and `@keywords internal` for `cleanAndBindFireData` (internal helper); `dataPrepWrapper` kept its existing roxygen with the empty `@returns` filled in. `summarizeABSK_AllData.R` — full roxygen for `summarizeABSK_AllData` (user-facing) and `@keywords internal` for `summarizeClimateVars` (internal helper, `@inheritParams summarizeABSK_AllData`); both legacy `##` headers migrated. Comment/blank-only diffs; both files parse.

The roxygen documentation pass across `R/R_tools/` and `analyses/R_tools/` is **complete** (Stage 4 committed as `a113253`; AGENTS.md status `6cb10a7`). Verified 2026-09-15: 129 roxygen titles, 31 internal helpers tagged `@keywords internal`, zero `@noRd`/`@export` remaining. The plan is archived at `.posit/assistant/plans/archive/2026-07-31-1206-onboard-to-lim-firesevmodels-repo.md`.

**Typo fix** (`2026-09-15`): Fixed comment typo in `Rsq_FIXED.R` line 24 (`"this is design for gamlss objects only"` → `"this is designed for gamlss objects only"`). The two typos previously flagged in `summary.gamlssinf0to1_FIXED.R` (`covariante`→`covariance`, `calcualted`→`calculated`) do not appear in the current file.

All commits through the latest typo fix are pushed to `origin/main`.

## Re-validation of severity models (Oct 2026, in progress)

Plan and task tracker: `.posit/assistant/plans/2026-10-29-1508-plan.md` (single source of truth; tick boxes and record decisions/caveats there).

- **Done already**: data rebuilt with the new concentric-ring neighbourhood-averaged predictors and the land-cover bugfix (restored SK non-forest pixels verified).
- **Terminology**: *Old-ngb* = `ngbPropBurns_*`/buffer variables; *Ring-ngb* = concentric-ring averaged predictors. They are mutually exclusive (redundant) and never combined. *Calibration fires* = all non-holdout fires; *holdout fires* = 1–2 fires used once for the final evaluation; *outer/inner folds* = nested-CV terms; all folds are grouped by `FIRE_NAME`.
- **Design (decision 4)**: GAMLSS uses select-once: a new base model (no neighbourhood terms) re-selected on the calibration fires without subsampling, then one `stepGAICAll.A()` per set from it, all with `k = log(n)` on one shared `na.omit()` row set, followed by a residual spatial-autocorrelation check and grouped CV of the fixed formulas. If GAIC and CV disagree, fall back to nested CV. XGBoost uses nested grouped CV.
- **Code issues found**: GAMLSS CV currently stratifies *by* fire (fires are split across train/test); XGBoost uses random pixel folds, trains on all rows (`list(seq(NROW(dat)), tr)`), and tunes and SHAP-prunes on all rows; the GAMLSS neighbourhood scope regex `_[[:digit:]]{2,4}m$` (Rmd ~359-374) matches **both** sets.
- **Caveats C1–C9** (in the plan; carry into the manuscript methods/discussion). C9 (pending): Old-ngb `ngbPropBurns_*` is derived from the response's burned/unburned status, so it is only valid if that status is known at prediction time. C1–C8: mixed sets in previous runs; `log(n)` assumes residual independence; the fire random effect doesn't handle within-fire autocorrelation, and unseen fires get population-level predictions; select-once optimism; stepwise path dependence; different validation designs for GAMLSS vs XGBoost; few fires; the final model isn't cross-validated itself.
- **Working mode (updated 2026-10-30)**: the **user writes the implementation code** and owns the methodological decisions and the `browser()`-marked logic. Do not write implementation code into the repo unless the user explicitly asks for that piece. The assistant is responsible for:
  - **Bookkeeping**: keep the plan's checkboxes, decisions and caveats (C1–C8, plus new ones) current, and keep AGENTS.md in sync.
  - **Proactive warnings**: flag potential bugs, statistical or leakage problems, reproducibility risks, and better ways to do things, including file/folder structure. Flag these unprompted, but don't act on them without approval.
  - **Running and tracking fits on request**: when asked, run model fitting/validation code and log each run (date, model type, predictor set, rows/fires, folds, seed, key settings, metrics, output/cache paths, notes) in the run log `.posit/assistant/plans/2026-10-29-1508-runlog.md`.
  - Also on request: review diffs, explain existing code, sketch approaches or pseudocode, and write test/check snippets.
- **Pinned figure for the manuscript**: validation-design schematic (methods figure) at `analyses/Figs/validationDesign.png`, drawn with ggplot2 on 2026-10-30. `analyses/Figs/validationDesign.mmd` holds the Mermaid text version but is **not** the PNG's source. The PNG is gitignored (`*.png`); regenerate it by running `analyses/plot_validationDesign.R` from the repo root (tracked; ggplot2 + ragg).

## Legacy inventory (snapshot 2026-10-30)

Tracks legacy code and outputs so nothing is deleted, overwritten or silently reused during the re-validation. **Do not delete or move anything listed here without the user's approval.** Status key: *legacy* = superseded, kept for reference; *in use* = still read by an active script; *abandoned* = GPBoost; *superseded-pending* = will be replaced by re-validation outputs. Sizes are approximate. When new outputs replace an item, update its row.

### Code
| Path | Status | Notes |
|---|---|---|
| `analyses/DAfires_sevModels.Rmd` | legacy | Original GAMLSS workflow; produced most figures currently cited in the manuscript (see Figures below) |
| `analyses/DAfires_sevModelsGAMLSS.Rmd` | legacy | Predecessor of `_ngbAvg`; same data `cacheId` `185c…` |
| `analyses/DAfires_expAnalyses_BAD.Rmd` | legacy | Superseded EDA |
| `analyses/DAfires_expAnalysesGood.html` | legacy (tracked) | Rendered EDA output |
| `analyses/DAfires_sevModelsBoost.Rmd`, GPBoost sections | abandoned | Leave untouched |
| `R/R_tools/Useful_functions.R` `runGPBOOST`, `gpboostConfMat` | abandoned | Leave untouched |
| `analyses/plot_4DaveFeb19.R` | legacy | Reads Windows paths from the `LandscapesInMotion` SpaDES outputs (`E:/GitHub/...`); not runnable here |
| `analyses/plot_ESAexperiment.R` | legacy | ESA-poster figures from SpaDES outputs; writes `analyses/ESA_mapsFig.png` |
| `0_dataPrep_projections.R` | legacy (R 3.4 API) | See Gotchas |
| `simLinks.sh` | unused | See Gotchas |

### Model objects and text outputs (`analyses/`, all gitignored)
| File(s) | Date | Size | Status | Read by |
|---|---|---|---|---|
| `model8_4.rds` | 2022-12 | 0.6 GB | legacy | `DAfires_sevModels.Rmd:1374`, `DAfires_sevModelsGAMLSS.Rmd:1235` |
| `model8_4FULL.rds` | 2026-03 | 1.5 GB | **in use**, superseded-pending (W2) | `_ngbAvg.Rmd:354`: read for its formulas (base for neighbourhood scopes, l.356–374), and the fitted object is also the start model passed to `stepGAICAll.A()` (l.377). Fitted on pre-fix data. This read is in the part of the Rmd not yet redone (after the `## here!!` marker, l.321); the user plans to replace it with the base model from the re-run `nonspatialpreds` selection |
| `modelNgbSev4FULL3.rds` + `_RESIDS.tif`, `_SUMMARY.txt`, `_crossValidOutputs.txt` | 2020–2026 | 1.0 GB | legacy | — |
| `modelNgbSev4FULL4.rds` + `_RESIDS.tif`, `_SUMMARY.txt`, `_crossValidOutputs.txt` | 2021–2022 | 1.7 GB | legacy | legacy Rmds |
| `modelNgbSev4FULL4Scaled.rds` + `_RESIDS.tif`, `_SUMMARY.txt`, `_CONFMATRX.txt`, `_obsVSpred.tif`, `_crossValidOutputs.txt` | 2023–2026 | 1.6 GB | **in use**, superseded-pending | `DAfires_sevModelsBoost.Rmd:557, 1012, 1040` (GAMLSS-vs-XGBoost comparison); legacy Rmds |
| `modelsGAMLSS_0-3Days_20m_goodSample_Nov1.RData` | 2020-01 | 37 GB | legacy | only commented-out `load()` lines |
| `modelsGAMLSS_allWeatherDays_20m_badSample_Oct10.RData` | 2019-12 | 14 GB | legacy | — |
| `modelNgbAvg4FULL4*.rds/.txt/.tif` | — | — | **not on disk**: written/read by `_ngbAvg.Rmd` (l.447–800, 2997) but never produced | — |
| `analyses/GPBoost/` (`modelGPB_de7d….rds`, `gp_model_de7d….json`) | 2025 | 36 MB | abandoned | — |

### Caches
| Path | Size | Status | Notes |
|---|---|---|---|
| `analyses/cache/` | 36 GB | **in use**, flagged corrupted | Still read: `ngbNoBurns` via `loadFromCache(…, "c7536dcb493ad453")` (`_ngbAvg.Rmd:147`); Boost Rmd data `0a70f8b25dc39895` (W1). Do not delete. |
| `analyses/cacheNEW/` | 3.7 GB | **in use** (current) | Data `185c1b8db3c9788d`, ring averages `e66855d04c369d12` |
| `analyses/DAfires_expAnalyses_cache/`, `_files/` | 32 MB | legacy | knitr chunk cache / figure output from 2023 |
| `analyses/DAfires_sevModels_cache/` | empty | legacy | |
| pinned `cacheId = "85b6d427b43ff53d"` (CV results) | — | legacy | Commented-out `loadFromCache` in `_ngbAvg.Rmd:590, 691` and legacy Rmds |

### Data-prep intermediates (`analyses/`)
| Path | Size | Status | Notes |
|---|---|---|---|
| `fireDataJoins/` | 49 GB | in use (data prep) | Per-fire joined tables (`joinSevVegTopoWeatherData.R`, `DAfires_expAnalyses_dataPrep.R`) |
| `fireDataSummary/`, `FireEvents/` | 30 MB | legacy | 2018–2019 |
| `firesInFMAs/`, `CASFRI/` | empty | legacy | |

### Figures (`analyses/Figs/`, gitignored)
| Files | Status | Notes |
|---|---|---|
| `crossValidPlot_DAfires_sevModels.png`, `firesEcozonesNatRAB.png`, `meanSevPEFPlots_…`, `p0PEFPlots_…`, `p1PEFPlots_…`, `severityMaps_highAgreement.png`, `varSevPEFPlots_DAfires_sevModels2.png`, `varSevPEFPlotsNotForest_DAfires_sevModels1.png` | **cited in manuscript**, superseded-pending | Produced by the legacy GAMLSS Rmds from `modelNgbSev4FULL4*`; must be regenerated from the re-validated models. The filenames are reused by `_ngbAvg.Rmd`, so a re-run **overwrites** them. |
| other `*_DAfires_sevModels*.png`, `PCAforest*.png`, `firesEcozones.png`, `severityMaps_lowAgreement.png`, `tuning_learningRate.png` | legacy | 2021–2025 |
| `XGBoost/` (~150 files: SHAP partial-dependence, tuning, residuals, severity maps) | legacy, superseded-pending | Oct–Nov 2025 runs with random pixel folds |
| `GPBoost/` (~55 files) | abandoned | |
| `validationDesign.png` / `.mmd` | current | Pinned methods figure |

### Repo root
| Path | Size | Status | Notes |
|---|---|---|---|
| `analyses.zip` | 31 GB | legacy archive | Contents unverified |
| `diagnostics-2026-08-26T…zip` | 0.4 MB | legacy | Positron diagnostics export (gitignored) |

### New outputs (re-validation, Oct 2026)
| Path | Status | Notes |
|---|---|---|
| `analyses/outputs/nonCollinearVars.rds` | current | From `DAfires_collinearityCheck.Rmd`; topographic/vegetation/climate/categorical lists + `meta`. The `climate` element is FWI-only until decision 11 |
| `analyses/DAfires_collinearityCheck.html`, `_files/`, `_cache/` | current | Knitted output; `_files`/`_cache` gitignored, the `.html` is not |

**Overwrite risk:** `_ngbAvg.Rmd` writes manuscript-cited figure names into `analyses/Figs/` and model files into `analyses/`. Until outputs are redirected (outputs/config sub-plan), running its chunks overwrites legacy files listed above.

## Open items

- `.posit/assistant/settings.json` is rewritten live by the permission system. Current state: `permission.edit` allows `*.md`, `*.json`, and `*.R` (the last is intentionally kept by the user — the heredoc-only rule for R files is a behavioural convention, not permission-enforced); the `bash` allowlist includes both `"python *"` and `"python3 *"`; `git add`/`commit`/`push` are set to `"ask"`. The stale Windows-path `git -C c:/Users/cbarros/...` allowlist entries still don't match this Linux checkout (optional cleanup).
