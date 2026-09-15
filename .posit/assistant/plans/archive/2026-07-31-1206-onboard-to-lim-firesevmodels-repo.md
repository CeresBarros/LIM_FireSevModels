# Plan: Document helper functions in `R/R_tools/` and `analyses/R_tools/`

## Status (2026-09-15) — COMPLETE ✅ (archived)

All stages are done and pushed to `origin/main`. Every top-level function in
`R/R_tools/` and `analyses/R_tools/` now carries a `#'` roxygen block.

Final verification (2026-09-15): 129 roxygen titles across the two directories;
31 internal helpers tagged `@keywords internal`; **0** `@noRd` and **0**
`@export` tags remain. A scan for undocumented top-level functions returns only
false positives — the two `_FIXED.R` shims (roxygen separated from the
signature by a blank line) and four local closures defined inside function
bodies (`estimatesgamlss`, `unsigned.range`, `myAsNumeric`, `collapseCols`),
which are not top-level functions and need no blocks.

Final commits: `a113253` (Stage 4 — `analyses/R_tools/` roxygen), `6cb10a7`
(AGENTS.md status), `db816c3` (`.gitignore` diagnostics files). Earlier:
`f503e1c` (Stage 1), `f0fa101` (Stage 2), `0ae2fe2`/`917cfd2` (Stage 3
wrappers), `29afc37`/`c3c2d14`/`38a8a11` (Stage 3 internal recoders),
`674ab74` (`@noRd` removal).

Conventions that emerged during the pass and now live in `AGENTS.md`:

- Internal helpers get `@keywords internal` **only** — never `@noRd` alongside
  it (`@noRd` suppresses the `.Rd` and would override the keyword).
- Pre-function `##` doc-style headers are **migrated into roxygen and removed**;
  in-function `##` code comments are **preserved**.
- Terminology: "internal functions"/"internal helpers" (not exported) and
  "helper functions" (may be exported, called within wrappers). Avoid "atomic",
  which has a specific meaning in R.

- [x] `R/R_tools/prepCorrTable.R` — top note rewritten.
- [x] `R/R_tools/Rsq_FIXED.R` — `Rsq_2` roxygen block above the function; original signature and body untouched.
- [x] `R/R_tools/getPEF_own.R` — `getPEF.own` roxygen block (the `# TODO: confirm` on the unused `output` argument was later removed by the user as the description was accurate).
- [x] `R/R_tools/prepFireWeather.R` — `prepFireWeather` roxygen block replacing the two-line plain-comment header.
- [x] `R/R_tools/joinSevVegTopoWeatherData.R` — `joinSevVegTopoWeatherData` (exported) and `joinPerFire` (internal).
- [x] `R/R_tools/crossValidFunction.R` — `crossValidFunction` (exported) and `calcCrossValidMetrics` (internal).
- [x] `R/R_tools/summary.gamlssinf0to1_FIXED.R` — `summary.gamlssinf0to1_2` roxygen block replacing the plain-comment rationale.
- [x] `R/R_tools/Neighbourhood_functions.R` — all 9 functions (4 exported + 5 internal), replacing the pre-existing partial `#'` blocks that had bare `@param` tags and a stray `@param st_drop_geometry`.

## Stage 2 — DONE (committed `f0fa101`)

- [x] `R/R_tools/inputMaps.R` — REMOVED as dead code (no callers here or upstream); not documented.
- [x] `R/R_tools/Useful_functions.R` — per-function `#'` roxygen on all 16 functions (11 exported + 5 internal). Full blocks for exported functions; `@keywords internal` for `.calculateFireEvents`, `.tunexgboost`, `.predfunGAMLSS`, `.modelspecsfunGAMLSS`, `.functionNameHelper` (these originally also carried `@noRd`, stripped later in `674ab74`); `@inheritParams runXGBOOST` on `.tunexgboost` and `runGPBOOST`; filled the empty `@returns`/`@examples` stubs on `xgboostConfMat`/`gpboostConfMat`; `@note` on `xgboostConfMat` flagging the missing explicit `return()`. Comment-only diff (202/71), parses under R.

## Stage 3 — DONE

- [x] `R/R_tools/CASFRIrelated_functions.R` **wrappers** — full roxygen for the 5 wrappers (`invent2CASFRI`, `ABToCASFRI`, `SKToCASFRI`, `meltPreFireABInv`, `meltPreFireSKInv`); committed `0ae2fe2` (+ `CASFIR`→`CASFRI` typo fix), then DRY-ed via `@inheritParams` in `917cfd2` (SK/melt wrappers inherit shared params; `ABToCASFRI`'s `@param inv` made province-neutral).
- [x] `R/R_tools/CASFRIrelated_functions.R` **internal recoders** (17) — title + `@param` pass, all tagged `@keywords internal` and DRY-ed with `@inheritParams` (`spPercent` anchors shared `province`/`MISSCODE`/`ERRCODE`): `spLatinName`, `TypeForest`, `spPercent`, `spPercentAdjust`, `originUpper`, `originLower`, `nonVegNatSK`, `nonVegAnthSK`, `nonForestVegSK`, `wetlandCodesSK`, `wetlandCodesSK2`, `wetlandCodesAB`, `soilMoistureRegime`, `NFLAdjustAB`, `SMRAdjustAB`, `addWaterInfo`, `correctCSGPFTTYPE`. Legacy pre-function `##` headers migrated into the roxygen and removed; `.pm`/CASFRI-manual wording normalized (`29afc37`, `c3c2d14`, `38a8a11`).

## Stage 4 — DONE (`a113253`)

- [x] `analyses/R_tools/DAfires_expAnalyses_dataPrep.R` — full roxygen for `ABSKfires_DataPrep` (user-facing orchestrator; legacy `##` header migrated), `@keywords internal` for `cleanAndBindFireData`; `dataPrepWrapper` kept its block with the empty `@returns` filled and its `@export` + orphaned `@importFrom` tags removed.
- [x] `analyses/R_tools/summarizeABSK_AllData.R` — full roxygen for `summarizeABSK_AllData`, `@keywords internal` + `@inheritParams` for `summarizeClimateVars`; both legacy `##` headers migrated.

## Mitigation in force

- User has disabled Air globally across all projects.
- Assistant continues to write via `bash`+`python3` heredoc, and to run
  `git diff <file> | grep '^[+-][^+-#]' | grep -v '#'` after each write to
  confirm only comment lines changed. If any non-comment line moved, revert
  and retry.
- `"*.R": "allow"` under `permission.edit` in `.posit/assistant/settings.json`
  was **removed** (`3be14db`) so R edits fall back to the default prompt; only
  `"*.md"`/`"*.json"` remain allowed. Note the `bash` allowlist has `"python *"`
  but not `"python3 *"` — re-adding `"python3 *": "allow"` would spare the
  heredoc workflow repeated prompts (pending user decision). The stale
  Windows-path `git -C c:/...` entries still don't match this Linux checkout.

## User style notes (learned 2026-08-20)

- Keep function signatures as originally authored (may be a single line even if long).
- Keep single-line `if (cond) stmt` / `if (cond) x else y` — do not add braces.
- Keep operator spacing as authored (`2/object$N`, not `2 / object$N`).
- Keep author's blank-line and section-comment layout as-is.
- Only touch `#'` roxygen blocks and, where a pre-existing plain-comment header documented the function, replace that specific header with a roxygen block (leave surrounding blank lines and section rules alone).

## Goal (unchanged)

Add roxygen2-style documentation headers to helper functions used across the fire severity models pipeline. Documentation only — no code changes.

## Documentation style (unchanged)

- Roxygen2 `#'` comment blocks directly above each function.
- Internal helpers get short docs (title + `@param` + `@return`) plus `@keywords internal` **only** (the original plan said `@keywords internal` *and* `@noRd`; this was corrected mid-pass — `@noRd` suppresses the `.Rd` entirely and overrides the keyword, so all `@noRd` tags were stripped in `674ab74`).
- Preserve author attributions as `@author`.
- For `_FIXED.R` shims, add `@note` describing the upstream bug patched, and `@seealso` the original.
- For arguments whose shape isn't obvious from the source, document a best-guess and add a `# TODO: confirm` marker.
- Fix `@param` names/descriptions if they're wrong, but never reorder arguments in code.

## Decisions from user

1. **XGBoost / GPBoost helpers** — treated as active and fully documented.
2. **CASFRI depth** — tiered: full roxygen for wrappers (`ABToCASFRI`, `SKToCASFRI`, `meltPreFireABInv`, `meltPreFireSKInv`, `invent2CASFRI`); short title + `@param` for the internal recoders. (This decision originally said "atomic recoders"; the terminology was corrected mid-pass — see the status note above.)
3. **Inferred parameters** — document best-guess with `# TODO: confirm` markers.
4. **`moduleSticker.R`** — deleted by the user (no callers repo-wide).
5. **Scope discipline** — documentation only. No code cleanup, formatting changes, or refactors. If code issues are found, flag them for later, do not touch.

## Inconsistencies / issues to flag for later (not fixed here)

- `R/R_tools/Rsq_FIXED.R`: comment typo `"design"` should read `"designed"`.
- `R/R_tools/summary.gamlssinf0to1_FIXED.R`: comment typos `covariante` → `covariance`, `calcualted` → `calculated`.
- `R/R_tools/crossValidFunction.R`: `set.seed(123)` hard-coded inside `crossValidFunction`; `browser()` call at line ~161 in `calcCrossValidMetrics` will halt execution when reached.
- `R/R_tools/Useful_functions.R`: `browser()` calls inside `runXGBOOST` (line ~468) and `runGPBOOST` (lines ~785, ~832).
- `R/R_tools/Useful_functions.R`: `xgboostConfMat` computes `validMetrics` but has no explicit `return()` — only the last expression (`confMatrix`) is returned. Inconsistent with `gpboostConfMat`, which returns `list(validMetrics, confMatrix)`.
- `R/R_tools/Neighbourhood_functions.R`: pre-existing partial roxygen blocks on `calculateNgbAvgsWrapper`, `calculateNgbAvgs`, `.makeRings`, `.calcAvgs` have incomplete or bare `@param` tags (e.g. `@param buffers` with no description; a stray `@param st_drop_geometry`).
- `.posit/assistant/settings.json` diff includes `"*.R": "allow"` under `permission.edit` that the assistant did not consciously add — origin unclear.
- Repo-wide reminder: the Windows `git -C c:/Users/cbarros/...` allowlist entries in `.posit/assistant/settings.json` still don't match this Linux checkout (already noted in `AGENTS.md`).

## Original stage breakdown (all now complete — see status above)

### Stage 1 — Helpers sourced by the active GAMLSS Rmd

- [x] `R/R_tools/joinSevVegTopoWeatherData.R` — `joinSevVegTopoWeatherData`, `joinPerFire`.
- [x] `R/R_tools/Neighbourhood_functions.R` — `calculateNgbSevWrapper`, `.calculateNgbSev`, `calculateNgbBurnsWrapper`, `.calculateNgbBurns`, `calculateNgbAvgsWrapper`, `calculateNgbAvgs`, `.makeRings`, `.myMerge`, `.calcAvgs`.
- [x] `R/R_tools/crossValidFunction.R` — `crossValidFunction`, `calcCrossValidMetrics`.
- [x] `R/R_tools/prepFireWeather.R` — `prepFireWeather`.
- [x] `R/R_tools/prepCorrTable.R` — rewrite the top note only (no live function).
- [x] `R/R_tools/getPEF_own.R` — `getPEF.own`.
- [x] `R/R_tools/Rsq_FIXED.R` — `Rsq_2`.
- [x] `R/R_tools/summary.gamlssinf0to1_FIXED.R` — `summary.gamlssinf0to1_2`.

### Stage 2 — Supporting utilities

- [x] `R/R_tools/inputMaps.R` — REMOVED as dead code; not documented.
- [x] `R/R_tools/Useful_functions.R` — 16 functions (11 exported + 5 internal).

### Stage 3 / 4 — CASFRI + analyses helpers

- [x] `R/R_tools/CASFRIrelated_functions.R` — tiered (full for the five wrappers, title + `@param` for the 17 internal recoders).
- [x] `analyses/R_tools/DAfires_expAnalyses_dataPrep.R` — `ABSKfires_DataPrep`, `cleanAndBindFireData`, `dataPrepWrapper`.
- [x] `analyses/R_tools/summarizeABSK_AllData.R` — `summarizeABSK_AllData`, `summarizeClimateVars`.

## Process per file (as used)

1. `read` the file to see each function signature and existing header comments.
2. Draft the roxygen block for every function.
3. **Write via `bash`/`python3` heredoc (not `edit`)** to avoid the editor formatter.
4. Immediately run `git diff <file>` and verify only comment/blank lines changed; confirm the file still parses.

## Follow-ups carried forward (see `AGENTS.md` "Open items")

The code issues flagged below were deliberately **not** fixed under this
documentation-only plan and remain outstanding: `browser()` calls in
`crossValidFunction.R` and `Useful_functions.R`, `xgboostConfMat`'s missing
explicit `return()`, the hard-coded `set.seed(123)`, the `_FIXED.R` comment
typos, and the stale Windows-path `git -C c:/...` allowlist entries in
`.posit/assistant/settings.json`.
