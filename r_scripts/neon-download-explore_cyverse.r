## Tutorial: https://www.neonscience.org/download-explore-neon-data 

## ----packages, eval=FALSE-----------------------------------------------------------------------------------------------------
## 
## install.packages("devtools")
install.packages("neonUtilities")
## install.packages("raster")
devtools::install_github("NEONScience/NEON-geolocation/geoNEON")
## install.packages("BiocManager")
## BiocManager::install("rhdf5")
## 


## ----setup, results='hide', message=FALSE, warning=FALSE----------------------------------------------------------------------

# load packages
library(neonUtilities)
library(geoNEON)
library(raster)
library(rhdf5)

# Set global option to NOT convert all character variables to factors
options(stringsAsFactors=F)



## ----stacking-portal, results="hide", message=FALSE, warning=FALSE------------------------------------------------------------

system("mkdir ~/data")

# Pre-staged dataset in the CyVerse Data Store for WREF downloaded 2020-10-19
# note: this system command in R is much slower than running directly in the Terminal when the output is not quieted
system("cd ~/data && wget -q https://data.cyverse.org/dav-anon/iplant/projects/NEON_workshop/data/NEON_par.zip")

# Modify the file path to match the path to your zip file
stackByTable("~/data/NEON_par.zip", nCores = 8)


## ----run-loadByProduct, results="hide", message=FALSE, warning=FALSE----------------------------------------------------------

veg_str <- loadByProduct(dpID="DP1.10098.001", site="WREF", 
              package="expanded", check.size=F)


## ----loadBy-list, eval=F------------------------------------------------------------------------------------------------------
## 
names(veg_str)
View(veg_str$vst_perplotperyear)

## 


## ----env, eval=F--------------------------------------------------------------------------------------------------------------
## 
list2env(veg_str, .GlobalEnv)
## 


## ----save-files, eval=F-------------------------------------------------------------------------------------------------------
## 
write.csv(vst_apparentindividual,
         "~/data/vst_apparentindividual.csv",
         row.names=F)
write.csv(variables_10098,
         "~/data/variables_10098.csv",
         row.names=F)
## 


## ----aop-tile, results="hide", message=FALSE, warning=FALSE-------------------------------------------------------------------

byTileAOP("DP3.30015.001", site="WREF", year="2017", check.size = F,
          easting=580000, northing=5075000, savepath="~/data")



## ----read-par, results="hide", message=FALSE, warning=FALSE-------------------------------------------------------------------

par30 <- readTableNEON(
  dataFile="~/data/NEON_par/stackedFiles/PARPAR_30min.csv", 
  varFile="~/data/NEON_par/stackedFiles/variables_00024.csv")
View(par30)



## ----read-par-var, results="hide", message=FALSE, warning=FALSE---------------------------------------------------------------

parvar <- read.csv("~/data/NEON_par/stackedFiles/variables_00024.csv")
View(parvar)

senspos <- read.csv("~/data/NEON_par/stackedFiles/sensor_positions_00024.csv")
View(senspos)


## ----plot-par, eval=TRUE------------------------------------------------------------------------------------------------------

plot(PARMean~startDateTime, 
     data=par30[which(par30$verticalPosition=="080"),],
     type="l")
lines(PARMean~startDateTime, 
      data=par30[which(par30$verticalPosition=="020"),],
      col="blue")
lines(PARMean~startDateTime, 
     data=par30[which(par30$verticalPosition=="010"),],
     col="red")

## Why so much light attenuation at the lower sensor positions?
## Visit the PhenoCam site to see images from every 15 minutes
## https://phenocam.sr.unh.edu/webcam/browse/NEON.D16.WREF.DP1.00042/


## ----read-vst-var, results="hide", message=FALSE, warning=FALSE---------------------------------------------------------------

View(variables_10098)

View(validation_10098)



## ----stems, results='hide', message=FALSE, warning=FALSE----------------------------------------------------------------------

names(vst_mappingandtagging) #this object was created using list2env() above
vegmap <- geoNEON::getLocTOS(vst_mappingandtagging, "vst_mappingandtagging")
names(vegmap)



## ----vst-merge, eval=TRUE-----------------------------------------------------------------------------------------------------

veg <- merge(vst_apparentindividual, vegmap, by=c("individualID","namedLocation",
                                  "domainID","siteID","plotID"))



## ----plot-vst, eval=TRUE------------------------------------------------------------------------------------------------------

symbols(veg$adjEasting[which(veg$plotID=="WREF_085")], 
        veg$adjNorthing[which(veg$plotID=="WREF_085")], 
        circles=veg$stemDiameter[which(veg$plotID=="WREF_085")]/100/2, 
        xlab="Easting", ylab="Northing", inches=F)

for(p in unique(veg$plotID)){
  symbols(veg$adjEasting[which(veg$plotID==p)], 
          veg$adjNorthing[which(veg$plotID==p)], 
          circles=veg$stemDiameter[which(veg$plotID==p)]/100/2, 
          xlab="Easting", ylab="Northing", inches=F, main=p)
}




## ----read-aop, eval=TRUE------------------------------------------------------------------------------------------------------



chm <- raster("~/data/DP3.30015.001/2017/FullSite/D16/2017_WREF_1/L3/DiscreteLidar/CanopyHeightModelGtif/NEON_D16_WREF_DP3_580000_5075000_CHM.tif")



## ----plot-aop, eval=TRUE------------------------------------------------------------------------------------------------------

plot(chm, col=topo.colors(6))


## Download all tiles that have veg plots
byTileAOP("DP3.30015.001", site="WREF", year="2017", check.size = T,
          easting=veg$adjEasting, northing=veg$adjNorthing, buffer=999, savepath="~/data")

a <- list.files("~/data/DP3.30015.001/2017/FullSite/D16/2017_WREF_1/L3/DiscreteLidar/CanopyHeightModelGtif/", pattern = glob2rx("*.tif$"), full.names = TRUE)
a

# These steps from the 'mosaic()' function help files:
x <- lapply(a, raster)
names(x)[1:2] <- c('x', 'y')
x$fun <- mean
x$na.rm <- TRUE

# Make the mosaic of four CHM tiles
y <- do.call(mosaic, x)



plot(y, col=topo.colors(6))
points(veg$adjEasting, veg$adjNorthing, pch=".", cex=2, col="red")
text(vst_perplotperyear$easting, vst_perplotperyear$northing, labels=substr(vst_perplotperyear$plotID,7,8))

