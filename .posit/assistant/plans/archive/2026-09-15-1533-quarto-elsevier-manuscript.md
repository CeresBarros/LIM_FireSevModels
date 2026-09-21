# Plan: Add a Quarto (Elsevier template) manuscript to this project

## Context

- This repo has no existing `_quarto.yml` / Quarto project — it's an R project (`.Rproj`) with standalone `.Rmd` analysis files under `analyses/`.
- Quarto CLI 1.7.32 is available on the system.
- The Elsevier template (https://github.com/quarto-journals/elsevier) is distributed as a Quarto **extension** (`quarto-journals/elsevier`), installed via `quarto add quarto-journals/elsevier` inside a target directory, which creates a `_extensions/quarto-journals/elsevier/` folder plus a starter `template.qmd`.

## Proposed structure

Nest the manuscript in its own subdirectory so it doesn't mix with the analysis Rmds or get swept up in unrelated tooling (git tracking, `.gitignore` rules for `data/`, etc.):

```
manuscript/
├── _extensions/
│   └── quarto-journals/
│       └── elsevier/        # installed via `quarto add`, vendored/committed
├── manuscript.qmd           # renamed from template's starter .qmd
├── references.bib
└── (figures/tables as needed, or reused from analyses/Figs)
```

Rationale for a standalone document (not a `_quarto.yml` "project"/book/website):
- Elsevier journal articles are normally a single rendered document, not a multi-page site.
- Avoids interfering with how `analyses/*.Rmd` currently render standalone via their own YAML.
- Keeps the door open to add a `_quarto.yml` later if the manuscript grows multiple `.qmd` parts (main text + supplementary), using `project: type: default` and `render:` list.

## Steps

1. Create `manuscript/` directory at the repo root.
2. Run `quarto add quarto-journals/elsevier` with working directory `manuscript/` to install the extension (creates `_extensions/quarto-journals/elsevier/` and a starter template file).
3. Rename/adjust the starter `.qmd` to `manuscript.qmd`, update YAML front matter (title, authors, affiliations, journal metadata) as placeholders for the user to fill in.
4. Add a starter `references.bib` (empty or with one placeholder entry) and wire it into the YAML (`bibliography: references.bib`).
5. Confirm render works: `quarto render manuscript/manuscript.qmd`.
6. Note in `AGENTS.md` (project memory) that a `manuscript/` Quarto document now exists, its purpose, and the render command — so future assistant sessions know about it.

## Decisions (confirmed by user)

1. **Location/name**: `manuscript/manuscript.qmd`.
2. **Git tracking**: commit `_extensions/quarto-journals/elsevier/` (no `.gitignore` entry needed for it).
3. **Content**: use the template's placeholder content as-is for now (no pulling in text/figures from existing analysis Rmds).
4. **LaTeX/PDF rendering**: checked via `quarto check` — TinyTeX v2026.01 is already installed and working at `~/.TinyTeX/bin/x86_64-linux` (bundled with this Quarto install, path `/usr/lib/rstudio-server/bin/quarto/bin`). **No LaTeX installation step is needed**; step 5 (render) should work as-is.
   - Side note (informational only, no action planned): `quarto check` also reports the R library path used here has no `knitr`/`rmarkdown` installed. This only matters if the manuscript later gains executable R code chunks (e.g. `{r}` chunks producing figures/tables) — a plain-prose Elsevier template with no code chunks doesn't need them. Flagging so it's not a surprise later.
