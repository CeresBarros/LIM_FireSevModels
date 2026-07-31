# LIM_FireSevModels

Empirical models of **wildfire severity** in Alberta and Saskatchewan boreal forests (and a few montane forests) using fire, vegetation, topography, and weather covariates. This was a side project of the *Landscapes in Motion* project (Foothills Research Institute) aimed at developing empirical approaches to
parameterise wildfire severity in a simulation context. For the mechanistic lanscape simulation
modelling project see: [`LIM_PBH`](https://github.com/CeresBarros/LIM_PBH).

## Scope

Analyses cover:

- Exploratory analysis of fire severity data (`analyses/DAfires_expAnalyses*.Rmd`)
- Gradient-boosted tree models of fire severity via **extreme gradient boosting** (XGBoost) 
and **Gaussian process tree gradient boosting** (GPBoost)
  (`analyses/DAfires_sevModelsBoost.Rmd`)
- Zero-one-inflated beta regression models via **GAMLSS**
  (`analyses/DAfires_sevModelsGAMLSS*.Rmd`)
- Fire-database processing (CNFD, provincial fire inventories)
- Data preparation utilities in `analyses/R_tools/`

## Repository layout

```
analyses/
├── DAfires_expAnalyses.Rmd            # exploratory analyses
├── DAfires_sevModelsBoost.Rmd         # XGBoost and GPBoost severity models
├── DAfires_sevModelsGAMLSS.Rmd        # GAMLSS severity models (old version)
├── DAfires_sevModelsGAMLSS_ngbAvg.Rmd # GAMLSS severity models (current)
├── Fires_CNFD.Rmd / .R                # CNFD fire database prep
├── FiresDA_FMAs.R                     # fires × Forest Management Areas
├── FI2CASFRI_checkerrors.R            # CASFRI cross-check
└── R_tools/                           # helper scripts (data prep, summaries)
0_dataPrep_projections.R               # reproject Alberta fire shapefiles (David Andison's data)
data/                                  # small reference data + CHECKSUMS; large inputs gitignored
packages/                              # library path for host R (contents gitignored)
LIM_FireSevModels.Rproj
```

## Getting started

1. Clone the repository.

```bash
git clone git@github.com:CeresBarros/LIM_FireSevModels.git
```

2. Provide a local `.Rprofile` / `.Renviron` if you need custom paths or credentials.

`.Rprofile` (not tracked) is expected to set a project-local
library path under `packages/<platform>/<R version>/` and add the
`predictiveecology.r-universe.dev` repo, e.g.:

```r
options(repos = c(
  CRAN = "https://cran.rstudio.com",
  PE   = "https://predictiveecology.r-universe.dev/"
))
```

`.Renviron` should set your personal GitHub PAT.

R version 4.5 is the current development target.

3. Open `LIM_FireSevModels.Rproj` in Positron or RStudio.

4. Install dependencies (see the top of each `.Rmd` for its package list and automated package installation).

5. If starting from raw fire shapefiles, run `0_dataPrep_projections.R` first;
   otherwise begin with the relevant `analyses/*.Rmd` document.

## Provenance

This repository was derived from the `xgboost` branch of the original
[`LandscapesInMotion`](https://github.com/CeresBarros/LandscapesInMotion) repository
in July 2026, preserving history for the empirical-modelling paths.

## Disclaimer

Portions of this README and repository documentation were drafted with the
assistance of Anthropic's Claude.All AI-assisted output was reviewed and edited by the
authors, who remain responsible for the contents of this repository.
