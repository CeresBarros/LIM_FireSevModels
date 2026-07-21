# LIM_FireSevModels

Empirical models of **wildfire severity** in Alberta and Saskatchewan boreal forests,
using fire, vegetation, topography, and weather covariates. This is the empirical
modelling component of the *Landscapes in Motion* project; the mechanistic SpaDES
simulation component lives in a separate repository:
[`LIM_PBH`](https://github.com/CeresBarros/LIM_PBH).

## Scope

Analyses cover:

- Exploratory analysis of fire severity data (`analyses/DAfires_expAnalyses*.Rmd`)
- Gradient-boosted tree models of fire severity via **XGBoost**
  (`analyses/DAfires_sevModelsBoost.Rmd`)
- Beta-inflated regression models via **GAMLSS**
  (`analyses/DAfires_sevModelsGAMLSS*.Rmd`)
- Fire-database processing (CNFD, provincial fire inventories)
- Data preparation utilities in `analyses/R_tools/`

## Repository layout

```
analyses/
├── DAfires_expAnalyses.Rmd            # exploratory analyses
├── DAfires_sevModelsBoost.Rmd         # XGBoost severity models
├── DAfires_sevModelsGAMLSS.Rmd        # GAMLSS severity models (earlier)
├── DAfires_sevModelsGAMLSS2026.Rmd    # GAMLSS severity models (current)
├── Fires_CNFD.Rmd / .R                # CNFD fire database prep
├── FiresDA_FMAs.R                     # fires × Forest Management Areas
├── FI2CASFRI_checkerrors.R            # CASFRI cross-check
└── R_tools/                           # helper scripts (data prep, summaries)
0_dataPrep_projections.R               # reproject Alberta fire shapefiles (Dave's data)
data/                                  # small reference data + CHECKSUMS; large inputs gitignored
Docker/                                # Dockerfile + run scripts
packages/                              # library path for host R (contents gitignored)
packages_docker/                       # library path for Docker R (contents gitignored)
LIM_FireSevModels.Rproj
```

## Cloning

```bash
git clone git@github.com:CeresBarros/LIM_FireSevModels.git
```

No submodules.

## R environment

`.Rprofile` (not tracked; provide your own) is expected to set a project-local
library path under `packages/<platform>/<R version>/` and add the
`predictiveecology.r-universe.dev` repo, e.g.:

```r
options(repos = c(
  CRAN = "https://cran.rstudio.com",
  PE   = "https://predictiveecology.r-universe.dev/"
))
```

R version 4.5 is the current development target; the Docker image (see `Docker/`)
provides a reproducible environment. Key modelling dependencies: `xgboost`, `gamlss`,
`gamlss.dist`, plus the tidyverse / `terra` / `sf` stack for data prep.

## Getting started

1. Clone the repository.
2. Provide a local `.Rprofile` / `.Renviron` if you need custom paths or credentials.
3. Open `LIM_FireSevModels.Rproj` in Positron or RStudio.
4. Install dependencies (see the top of each `.Rmd` for its package list).
5. If starting from raw fire shapefiles, run `0_dataPrep_projections.R` first;
   otherwise begin with the relevant `analyses/*.Rmd` document.

## Provenance

This repository was derived from the `xgboost` branch of the original
[`LandscapesInMotion`](https://github.com/CeresBarros/LandscapesInMotion) repository
in July 2026, preserving history for the empirical-modelling paths.

## Licence

Released under the **Apache License, Version 2.0**. Crown copyright applies —
see [`LICENSE`](LICENSE) for the notice and full licence text.
