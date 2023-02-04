if (!exists("pkgDir")) {
  pkgDir <- file.path(
    if (Sys.info()[["user"]] == "rstudio") "packages_docker" else "packages",
    version$platform,
    paste0(version$major, ".", strsplit(version$minor, "[.]")[[1]][1])
  )

  if (!dir.exists(pkgDir)) {
    dir.create(pkgDir, recursive = TRUE)
  }
  .libPaths(pkgDir)
}

library(sf)
library(terra)
library(ggplot2)
library(ggpubr)
library(ggspatial)

figDir <- "analyses/Figs/"

firesABSK <- Cache(cleanAndBindFireData,
                   files = c("albertafires1_postfire", "albertafires2_postfire", "saskatchewanfires_postfire"),
                   fireDataPath = "data/fires_Dave/fireSev",
                   cacheRepo = "analyses/cache",
                   userTags = "allFireData")
firesABSK <- vect(firesABSK)

NRAlberta <- prepInputs(targetFile = "AB_Natural_Sub_Regions.shp",
                        archive = "AB_Natural_Sub_Regions.zip",
                        alsoExtract = "similar",
                        url = "https://drive.google.com/file/d/1hW6zy0CpUBdk-K2IAjzW4INjVl1J4aLJ",
                        fun = "sf::st_read",
                        destinationPath = "data/maps",
                        cacheRepo = "analyses/cache",
                        userTags = "NRAlberta")

NRAlberta <- Cache(prepInputs,
                   targetFile = "Natural_Regions_Subregions_of_Alberta.shp",
                   archive = asPath("natural_regions_subregions_of_alberta.zip"),
                   url = "https://www.albertaparks.ca/media/429607/natural_regions_subregions_of_alberta.zip",
                   alsoExtract = "similar",
                   fun = "sf::st_read",
                   destinationPath = "R/SpaDES/inputs/",
                   cacheRepo = "R/SpaDES/data/cache",
                   userTags = c("prepInputsNatSubRegionsAB_SA"))

NRAlberta <- vect(NRAlberta)

## dissolve by region
NRAlberta <- aggregate(NRAlberta[, "NRNAME"], by = "NRNAME", dissolve = TRUE)
NRAlberta <- project(NRAlberta, crs(firesABSK, proj = TRUE))

EcozonesCan <- prepInputs(targetFile = "ecozones.shp",
                          url = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/zone/ecozone_shp.zip",
                          archive = "ecozone_shp.zip",
                          fun = "sf::st_read",
                          destinationPath = "data/maps",
                          cacheRepo = "analyses/cache",
                          userTags = "EcozonesCan")
EcozonesCan <- vect(EcozonesCan)
EcozonesCan[EcozonesCan$ZONE_NAME == "Boreal PLain"]$ZONE_NAME <- "Boreal Plain"
EcozonesCan <- project(EcozonesCan, crs(firesABSK, proj = TRUE))

CA_admin <- vect("data/CA_admin/gpr_000a11a_e.shp")
CA_admin <- project(CA_admin, crs(firesABSK, proj = TRUE))

## crop layers to a slightly larger area
extentFires <- ext(rbind(firesABSK, NRAlberta))
extentFires <- extend(extentFires, 50000)
# NRAlberta <- crop(NRAlberta, extentFires)
EcozonesCan <- crop(EcozonesCan, extentFires)
CA_admin <- crop(CA_admin, extentFires)


png(file.path(figDir, "firesEcozonesNatRAB.png"), height = 7, width = 8,
    units = "in", res = 300)
plot(EcozonesCan, y = "ZONE_NAME", col = RColorBrewer::brewer.pal(name = "Pastel2", n = 6),
     border = NA, plg = list(x = "topright", inset = c(-0.255, 0)),
     mar = c(3.1, 3.1, 2.1, 7.5), main = "")
plot(CA_admin, legend = FALSE, add = TRUE)
plot(NRAlberta, y = "NRNAME", col = RColorBrewer::brewer.pal(name = "Set1", n = 5),
     border = RColorBrewer::brewer.pal(name = "Set1", n = 5), lwd = 2,
     alpha = 0.3, plg = list(x = "bottomright", inset = c(-0.24, 0)),
     mar = c(3.1, 3.1, 2.1, 7.5), add = TRUE)
text(CA_admin[CA_admin$PRENAME %in% c("Alberta", "Saskatchewan")],
     labels = "PRENAME", adj = c(0.5, 6))
plot(firesABSK, legend = FALSE, add = TRUE)
dev.off()

