library(gamlss)
library(gamlss.spatial)
library(gamlss.data)

## EXAMPLE FROM DE BASTIANI

data("rent99")
data("rent99.polys")
rent99$cheating<-relevel(rent99$cheating,"1")
# creating new variables for interactions

# heating and years interaction
cy<-(as.numeric(rent99$cheating)-1)*rent99$yearc

# kitchen and years interation
ky<-(as.numeric(rent99$kitchen)-1)*rent99$yearc
# kitchen and area interation
ka<-(as.numeric(rent99$kitchen)-1)*rent99$area
# heating has its relevant level changed from 0 to 1
heating<-relevel(rent99$cheating,"1")
rent99 <- transform(rent99,heating=heating, cy=cy, ky=ky, ka=ka)   ## replaces variables in data.frame


m0 <- gamlss(rent ~ location+bath+kitchen+cheating+area+yearc+pb(area)+pb(yearc),
             sigma.fo = ~area + yearc + pb(area) + pb(yearc),
             nu.fo= ~area + yearc + pb(area) + pb(yearc),
             family=BCCGo, data=rent99)

m1 <- stepGAICAll.A(m0,
                    scope=list(
                      lower= ~location+bath+kitchen+cheating+area+ yearc+pb(area)+pb(yearc),
                      upper= ~(location+bath+kitchen+cheating+ area+yearc)^2+pb(area)+pb(yearc)),
                    sigma.scope=list(
                      lower= ~area+yearc,
                      upper= ~location+bath+kitchen+cheating+area+yearc+pb(area)+pb(yearc)),
                    nu.scope=list(
                      lower= ~area+yearc,
                      upper= ~location+bath+kitchen+ cheating+area+yearc+pb(area)+pb(yearc)),
                    k=4)


fd<-as.factor(rent99$district)
farea<-as.factor(names(rent99.polys))
## neighbour list
vizinhos <- polys2nb(rent99.polys)
#creating the precision matrix -- this is lambdaG, where G is the undirected graph
precision <- nb2prec(vizinhos, fd, area=farea)

## about 11 minutes
system.time({
m2<- gamlss(formula = rent ~ location + bath + kitchen + cheating + pb(area) +
              pb(yearc) + cy + ky + ka +
              gmrf(fd, area = farea, precision = precision, method="A"),  ## MRF
            sigma.formula =  ~ area + pb(yearc) + cheating,
            nu.formula =  ~pb(area) + pb(yearc) + kitchen,
            family = BCCGo, data = rent99, start.from=m1)
})

## 6 sec
system.time({
mrf.out <- MRFA(rent99$rent, x = fd, precision = precision, area = farea)
})

draw.polys(rent99.polys, fitted(mrf.out))

## WITH FIRE DATA

crsProj <- crs(vect("data/fires_Dave/fireSev/albertafires1_postfire.shp"), proj = TRUE)

SEV_PROPpoints <- summaryABSK_AllData[, .(pixID, FIRE_NAME, SEV_PROP, Lat, Long)]
SEV_PROPpoints <- st_as_sf(SEV_PROPpoints, coords = c("Long", "Lat"),
                           agr = "constant", crs = st_crs(crsProj))

## subset to a fire
firePoints <- SEV_PROPpoints[SEV_PROPpoints$FIRE_NAME == head(summaryABSK_AllData$FIRE_NAME, 1),]

## get fire perimeter
##HERE
firePerim <- firePoints |>
  st_union("MULTIPOINT")


##
dist <- 30
pointHex <- spsample(StudyArea_sp, type = "hexagonal", cellsize = 21750)
ngbs <- st_join(pointBuffer[, c("pixID", "geometry")], sevPoints[,c("pixID", "geometry")], suffix = c(".focal", ".ngbs"))
ngbs

fireRas <- raster(as_Spatial(sevPoints), resolution = resolution, crs = crs(sevPoints))
fireRas[] <- NA
fireRasIDs <- rasterize(as_Spatial(sevPoints), fireRas, field = "pixID")

## draw buffers
message(paste0("Drawing ", dist, "m buffers and counting burnt neighbours for ", fireID, " fire"))
w <- focalWeight(fireRas, d = dist*3, type = "circle")
w[w > 0] <- 1
w[w == 0] <- NA
w[ceiling(nrow(w)/2), ceiling(ncol(w)/2)] <- 0  ## exclude focal cell



