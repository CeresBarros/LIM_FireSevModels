library(gridExtra)
library(rasterVis)
library(rgdal)
library(quickPlot)
library(raster)
library(data.table)
library(ggplot2)

setwd("E:/GitHub/LandscapesInMotion")

outputsPath = "R/SpaDES/outputs/"

scens <- dir(outputsPath, pattern = "veg")

## get no. pixels in each fire
severities <- rbindlist(lapply(scens, FUN = function(scen) {
  d = file.path(outputsPath, scen)
  severities <- rbindlist(lapply(list.files(d, pattern = "severity", full.names = TRUE),
                                 FUN = function(rasfile) {
                                   ras <- raster(rasfile)
                                   severity <- data.table(sev = getValues(ras), 
                                                          year = sub(".*Year", "", sub(".tif", "", rasfile)))
                                   severity 
                                 }))
  severities[, scen := scen]
  severities
}))

## density plot of changes in severity (aka biomass)
severities[, sev :=-sev]   ## invert values so that biomass gains become positive

dev(width = 5, height = 4)
ggplot(data = na.omit(severities)) + 
  geom_density(aes(x = log(sev+abs(min(sev))), fill = scen), alpha = 0.5) +
  geom_vline(aes(xintercept = log(abs(min(sev))))) +
  scale_fill_discrete(labels = c("vegFB_0" = "No veg. feedback",
                                 "vegFB_1" = "W/ veg. feedback")) +
  theme_bw() + theme(legend.position = "bottom", text = element_text(size = 18)) +
  labs(x = expression(paste("log(prop. ", Delta, " biomass)")),
       y = "Density", fill = "", title = "Changes in biomass")

# ggsave("severityDensity.png", device = "png", width = 7.270833, height = 3.750000)

## get no. pixels in each fire
fireSizes <- rbindlist(lapply(scens, FUN = function(scen) {
  d = file.path(outputsPath, scen)
  rstCurrentBurn <- readRDS(list.files(d, pattern = "rstCurrentBurn", full.names = TRUE))
  
  fireSizes <- rbindlist(lapply(rstCurrentBurn, FUN = function(ras) {
    if(class(ras) == "RasterLayer") {
      fireSizes <- as.data.table(table(getValues(ras), dnn = c("FireID")))
      fireSizes
    }
  }))
  fireSizes[, scen := scen]
  fireSizes
}))

fireSizes

dev(width = 5, height = 4)
ggplot(data = fireSizes) +
  geom_density(aes(x = log(N), fill = scen), alpha = 0.5) +
  scale_fill_discrete(labels = c("vegFB_0" = "No veg. feedback",
                                 "vegFB_1" = "W/ veg. feedback")) +
  theme_bw() + theme(legend.position = "bottom", text = element_text(size = 18)) +
  labs(x = "log(no. pixels)", y = "Density", 
       fill = "", title = "Fire sizes")

# ggsave("fireSizes.png", device = "png", width = 7.270833, height = 3.750000)

graphics.off()

startBiomass <- lapply(scens, FUN = function(scen) {
    d = file.path(outputsPath, scen)
    ras <- raster(list.files(d, pattern = "biomass.*Year2.tif", full.names = TRUE))
  })
names(startBiomass) = scens
  
  
finalBiomass <- lapply(scens, FUN = function(scen) {
  d = file.path(outputsPath, scen)
  ras <- raster(list.files(d, pattern = "biomass.*Year50.tif", full.names = TRUE))
})
names(finalBiomass) = scens

plot1 <- gplot(startBiomass[[1]]) +  
  geom_tile(aes(fill=value, alpha=!is.na(value)), size = 0.1,
            show.legend = FALSE) +
  scale_fill_gradient2(low = "white", high  = "darkgreen") +
  theme_bw() + theme(legend.position = "bottom", axis.title = element_text(size = 12),
                     axis.text = element_text(size = 6),
                     plot.margin = unit(x = c(0,0.1,0,0), units = "in")) +
  labs(x = "", y = "Latitude", 
       fill = "Biomass", title = "No  veg. feedback")

plot2 <- gplot(startBiomass[[2]]) +  
  geom_tile(aes(fill=value, alpha=!is.na(value)), size = 0.1, 
              show.legend = FALSE) +
  scale_fill_gradient2(low = "white", high  = "darkgreen") +
  theme_bw() + theme(legend.position = "bottom", axis.title = element_text(size = 12),
                     axis.text = element_text(size = 6),
                     plot.margin = unit(x = c(0,0.1,0,0), units = "in")) +
  labs(x = "", y = "", 
       fill = "Biomass", title = "W/  veg. feedback")

plot3 <- gplot(finalBiomass[[1]]) +  
  geom_tile(aes(fill=value, alpha=!is.na(value)), size = 0.1, 
              show.legend = FALSE) +
  scale_fill_gradient2(low = "white", high  = "darkgreen") +
  theme_bw() + theme(legend.position = "bottom", axis.title = element_text(size = 12),
                     axis.text = element_text(size = 6),
                     plot.margin = unit(x = c(0,0.1,0,0), units = "in")) +
  labs(x = "Longitude", y = "Latitude", 
       fill = "Biomass", title = "")

plot4 <- gplot(finalBiomass[[2]]) +  
  geom_tile(aes(fill=value, alpha=!is.na(value)), size = 0.1) +
  scale_fill_gradient2(low = "white", high  = "darkgreen") +
  scale_alpha_discrete(guide = FALSE) +
  theme_bw() + theme(legend.position = "none", axis.title = element_text(size = 12),
                     axis.text = element_text(size = 6),
                     plot.margin = unit(x = c(0,0.1,0,0), units = "in")) +
  labs(x = "Longitude", y = "", 
       fill = "Biomass", title = "")

leg <- ggpubr::get_legend(plot4)

grid.arrange(plot1, plot2, plot3, plot4)
png(filename = "analyses/ESA_mapsFig.png",
       width = 5.9, height = 8, res = 300, units = "in")
dev.off()


dev()
png(filename = "analyses/ESA_mapsFig.png",
    width = 5.9, height = 8, res = 300, units = "in")
plot(stack(startBiomass[[1]], startBiomass[[2]], 
           finalBiomass[[1]], finalBiomass[[2]]))
dev.off()
