library(raster)
library(rasterVis)

initBiomass_Veg <- raster("E:/GitHub/LandscapesInMotion/R/SpaDES/outputs/vegFB_1/ESA_poster/biomassMap_Year2.tif")

finalBiomass_noVegFB <- raster("E:/GitHub/LandscapesInMotion/R/SpaDES/outputs/vegFB_0/ESA_poster/biomassMap_Year100.tif")
finalBiomass_VegFB <- raster("E:/GitHub/LandscapesInMotion/R/SpaDES/outputs/vegFB_1/ESA_poster/biomassMap_Year100.tif")

meanSeverity_noVegFB <- stack(lapply(list.files("E:/GitHub/LandscapesInMotion/R/SpaDES/outputs/vegFB_0/ESA_poster",
                                                pattern = "severityMap", full.names = TRUE), raster))
meanSeverity_VegFB <- stack(lapply(list.files("E:/GitHub/LandscapesInMotion/R/SpaDES/outputs/vegFB_1/ESA_poster",
                                              pattern = "severityMap", full.names = TRUE), raster))

meanSeverity_noVegFB <- mean(meanSeverity_noVegFB, na.rm = TRUE)
meanSeverity_VegFB <- mean(meanSeverity_VegFB, na.rm = TRUE)

min_ = min(minValue(initBiomass_Veg), minValue(finalBiomass_noVegFB), minValue(finalBiomass_VegFB))
max_ = max(maxValue(initBiomass_Veg), maxValue(finalBiomass_noVegFB), maxValue(finalBiomass_VegFB))
r.range = c(min_, max_)

## initial and final biomassMaps
levelplot(stack(initBiomass_Veg, finalBiomass_noVegFB, finalBiomass_VegFB),
          between = list(x=1, y=0.2),
          names.attr = c("Initial veg. biomass",
                         "Final veg. biomass\n(no feedback)",
                         "Final veg. biomass\n(w/ feedback)"),
          col.regions = rev(terrain.colors(99)), colorkey = list(space = "bottom"),
          maxpixels = 1e7)

## Average severity of fires during 100y of simulation
levelplot(stack(meanSeverity_noVegFB, meanSeverity_VegFB),
          between = list(x=1, y=0.2), main = "Average changes in biomass after fire (severity)",
          names.attr = c("No feedback", "W/ feedback"),
          col.regions = rev(terrain.colors(99)), colorkey = list(space = "bottom"))
