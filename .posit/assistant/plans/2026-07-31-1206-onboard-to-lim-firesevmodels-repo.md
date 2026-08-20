# Plan: Document helper functions in `R/R_tools/` and `analyses/R_tools/`

## Status (2026-08-20, after revert)

**All Stage 1 and Stage 2 roxygen edits were reverted** via `git checkout --` because the assistant-side edits inadvertently triggered Positron's code formatter, which reformatted function bodies (added braces around single-line `if`/`else`, respaced operators like `2 / object$N`, expanded function signatures to one-arg-per-line, etc.). Those changes went well beyond documentation and violated the user's explicit instruction to *only* add docs.

Working-tree state at this point:

- All `.R` files under `R/R_tools/` restored to their `HEAD` state.
- `R/R_tools/moduleSticker.R` remains deleted (user's own deletion).
- `AGENTS.md` and `.posit/assistant/plans/` remain (intentional).
- `.posit/assistant/settings.json` shows a diff (`"*.R": "allow"` added under `permission.edit`); the assistant did not intentionally add this and has not reverted it — user to decide whether to keep.

## Root cause and mitigation

- **Cause.** The `edit` tool in Positron routes through the editor, which applies the workspace formatter to the whole file whenever an edit lands. That reformatted function signatures and bodies alongside the documentation additions.
- **Mitigation for Stage 3 onward.**
  1. Do **not** use the `edit` tool on `.R` files while the workspace formatter is enabled. Use `bash` with `python`/`sed` or a heredoc to write files byte-for-byte, so no editor formatter runs.
  2. After each write, run `git diff <file>` and verify that the *only* lines added are `#'` roxygen lines immediately above a function definition — nothing else.
  3. If the diff shows any non-`#'` line change, revert the file and retry.
  4. Never change function-body formatting, brace style, argument-line-wrapping, operator spacing, or blank-line placement.

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
- Internal `.`-prefixed helpers get short docs (title + `@param` + `@return`) plus `@keywords internal` and `@noRd`.
- Preserve author attributions as `@author`.
- For `_FIXED.R` shims, add `@note` describing the upstream bug patched, and `@seealso` the original.
- For arguments whose shape isn't obvious from the source, document a best-guess and add a `# TODO: confirm` marker.
- Fix `@param` names/descriptions if they're wrong, but never reorder arguments in code.

## Decisions from user

1. **XGBoost / GPBoost helpers** — treated as active and fully documented.
2. **CASFRI depth** — tiered: full roxygen for wrappers (`ABToCASFRI`, `SKToCASFRI`, `meltPreFireABInv`, `meltPreFireSKInv`, `invent2CASFRI`); short title + `@param` for atomic recoders.
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

## Stages (all pending)

### Stage 1 — Helpers sourced by the active GAMLSS Rmd

- [ ] `R/R_tools/joinSevVegTopoWeatherData.R` — `joinSevVegTopoWeatherData`, `joinPerFire`.
- [ ] `R/R_tools/Neighbourhood_functions.R` — `calculateNgbSevWrapper`, `.calculateNgbSev`, `calculateNgbBurnsWrapper`, `.calculateNgbBurns`, `calculateNgbAvgsWrapper`, `calculateNgbAvgs`, `.makeRings`, `.myMerge`, `.calcAvgs`.
- [ ] `R/R_tools/crossValidFunction.R` — `crossValidFunction`, `calcCrossValidMetrics`.
- [ ] `R/R_tools/prepFireWeather.R` — `prepFireWeather`.
- [ ] `R/R_tools/prepCorrTable.R` — rewrite the top note only (no live function).
- [ ] `R/R_tools/getPEF_own.R` — `getPEF.own`.
- [ ] `R/R_tools/Rsq_FIXED.R` — `Rsq_2`.
- [ ] `R/R_tools/summary.gamlssinf0to1_FIXED.R` — `summary.gamlssinf0to1_2`.

### Stage 2 — Supporting utilities

- [ ] `R/R_tools/inputMaps.R` — already carried full roxygen blocks in the original; may still be complete. Re-verify against `HEAD` before adding anything.
- [ ] `R/R_tools/Useful_functions.R` — 15 functions grouped into fire events, PCA/loadings, sim-year sampling / pixel aggregation, XGBoost, GPBoost + GAMLSS predict helpers, plotting.

### Stage 3 — CASFRI + analyses helpers

- [ ] `R/R_tools/CASFRIrelated_functions.R` — tiered (full for the five wrappers, light for the ~17 atomic recoders).
- [ ] `analyses/R_tools/DAfires_expAnalyses_dataPrep.R` — `ABSKfires_DataPrep`, `cleanAndBindFireData`, `dataPrepWrapper`.
- [ ] `analyses/R_tools/summarizeABSK_AllData.R` — `summarizeABSK_AllData`, `summarizeClimateVars`.

## Process per file (revised for Stage 3 restart)

1. `read` the file to see each function signature and existing header comments.
2. Draft the roxygen block for every function.
3. **Write via `bash` heredoc (not `edit`)** to avoid the editor formatter. Alternatively use `python -c` with an in-place regex insert. Never touch anything except the `#'` block(s) being added.
4. Immediately run `git diff <file>` and verify every added line begins with `#'` (or is a blank comment line). If any non-`#'` line changed, revert and retry.

## Resume checklist

1. Re-read this file.
2. Confirm the mitigation strategy above.
3. Restart Stage 1 with `R/R_tools/prepCorrTable.R` (smallest, safest) as a dry run for the write-via-`bash` approach, then proceed through Stage 1, 2, 3 as listed.
4. Ask the user about the `.posit/assistant/settings.json` `"*.R": "allow"` diff.
