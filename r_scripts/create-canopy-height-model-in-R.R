## ----set-up, message=FALSE, warning=FALSE-------------------------------------------------

# Load needed packages
library(raster)
library(rgdal)

# set working directory to ensure R can find the file we wish to import and where
# we want to save our files. Be sure to move the download into your working directory!
system("mkdir ~/data")

# Optional - download your own dataset using the NEON API - this file is already available in the NEON_workshop/data
#system("cd ~/data && wget -q https://ndownloader.figshare.com/files/7907590 -O NEONDSFieldSiteSpatialData.zip && unzip NEONDSFieldSiteSpatialData.zip")



# Use this line to work with the dataset already saved to the NEON_workshop directory
# Change this to "~/data/" if you want to download the dataset above using the line above
wd <- "~/data/" #This will depend on your local environment
setwd(wd)

## ----download-topo-in-bulk-------------------------

library(httr)
library(jsonlite)
library(dplyr, quietly=T)
library(downloader)

# Request data using the GET function & the API call
req <- GET("http://data.neonscience.org/api/v0/products/DP1.10003.001")
req <- GET("http://data.neonscience.org/api/v0/products/DP3.30024.001")
req
req.content <- content(req, as="parsed")
names(req.content$data)
req.text <- content(req, as="text")

# Flatten data frame to see available data. 
avail <- jsonlite::fromJSON(req.text, simplifyDataFrame=T, flatten=T)
View(avail)

elev.urls <- unlist(avail$data$siteCodes$availableDataUrls)
length(elev.urls) #total number of URLs
elev.urls[1:10] #show first 10 URLs available

# get data availability for WOOD July 2015
elev_TEAK <- GET(elev.urls[grep("TEAK/2019", elev.urls)])
elev.files <- jsonlite::fromJSON(content(elev_TEAK, as="text"))

View(elev.files$data$files)

DSM.files=elev.files$data$files[grep("DSM.tif", elev.files$data$files$name, fixed = T),]

View(DSM.files)

## now, make a loop to download every file by pasting name together

system("mkdir ~/data/DSM/ && mkdir ~/data/DSM/TEAK/")
pre = "cd ~/data/DSM/TEAK/ && wget -q "

for(f in 1:length(DSM.files$name)){
  print(paste0("File #",f," ",DSM.files$name[f]))
  file_names = paste0('"',DSM.files$url[f],'"', " -O ", DSM.files$name[f])
  command = paste0(pre,file_names)
  system(command)

} # END f

## ----import-dsm---------------------------------------------------------------------------

# assign raster to object
dsm <- raster(paste0(wd,"NEON-DS-Field-Site-Spatial-Data/SJER/DigitalSurfaceModel/SJER2013_DSM.tif"))

# view info about the raster.
dsm

# plot the DSM
plot(dsm, main="Lidar Digital Surface Model \n SJER, California")



## ----plot-DTM-----------------------------------------------------------------------------

# import the digital terrain model
dtm <- raster(paste0(wd,"NEON-DS-Field-Site-Spatial-Data/SJER/DigitalTerrainModel/SJER2013_DTM.tif"))

plot(dtm, main="Lidar Digital Terrain Model \n SJER, California")



## ----calculate-plot-CHM-------------------------------------------------------------------

# use raster math to create CHM
chm <- dsm - dtm

# view CHM attributes
chm

plot(chm, main="Lidar Canopy Height Model \n SJER, California")



## ----challenge-code-raster-math, include=TRUE, results="hide", echo=FALSE-----------------
# conversion 1m = 3.28084 ft
chm_ft <- chm*3.28084

# plot 
plot(chm_ft, main="Lidar Canopy Height Model \n in feet")



## ----canopy-function----------------------------------------------------------------------
# Create a function that subtracts one raster from another
# 
canopyCalc <- function(DTM, DSM) {
  return(DSM -DTM)
  }
    
# use the function to create the final CHM
chm2 <- canopyCalc(dsm,dtm)
chm2

# or use the overlay function
chm3 <- overlay(dsm,dtm,fun = canopyCalc) 
chm3 



## ----write-raster-to-geotiff, eval=FALSE, comment=NA--------------------------------------
# write out the CHM in tiff format. 
writeRaster(chm,paste0(wd,"chm_SJER.tif"),"GTiff")


