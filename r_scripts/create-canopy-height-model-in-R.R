# This script based on the tutorial found here: https://www.neonscience.org/create-chm-rasters-r
before <- Sys.time()


## ----set-up, message=FALSE, warning=FALSE-------------------------------------------------

# Load needed packages
library(raster)
library(rgdal)
library(httr)
library(jsonlite)
library(dplyr, quietly=T)
library(downloader)

# set working directory to ensure R can find the file we wish to import and where
# we want to save our files. Be sure to move the download into your working directory!
system("mkdir ~/data")

# Optional - download the example dataset shown in the assoiciated tutorial
#system("cd ~/data && wget -q https://ndownloader.figshare.com/files/7907590 -O NEONDSFieldSiteSpatialData.zip && unzip NEONDSFieldSiteSpatialData.zip")


# Use this line to work with the dataset already saved to the NEON_workshop directory
# Change this to "~/data/" if you want to download the dataset above using the line above
wd <- "~/data/" #This will depend on your local environment
setwd(wd)

## ----download-topo-in-bulk-------------------------

# Use the NEON API to request information about available data products
# See: https://data.neonscience.org/data-api/ for more information about the API

# Request data using the GET function & the API call
req <- GET("http://data.neonscience.org/api/v0/products/DP3.30024.001")
req
req.content <- content(req, as="parsed")
names(req.content$data)
req.text <- content(req, as="text")

# Flatten data frame to see available data. 
avail <- jsonlite::fromJSON(req.text, simplifyDataFrame=T, flatten=T)
#View(avail)

elev.urls <- unlist(avail$data$siteCodes$availableDataUrls)
length(elev.urls) #total number of URLs
elev.urls[1:10] #show first 10 URLs available

# get data availability for WOOD July 2015
elev_TEAK <- GET(elev.urls[grep("TEAK/2019", elev.urls)])
elev.files <- jsonlite::fromJSON(content(elev_TEAK, as="text"))

View(elev.files$data$files)

# Select only the DSM TIFF files from the list
DSM.files=elev.files$data$files[grep("DSM.tif", elev.files$data$files$name, fixed = T),]

View(DSM.files)

## now, make a loop to download every file by pasting name together
# First, make new dir to save into
system("mkdir ~/data/DSM/")
system("mkdir ~/data/DSM/TEAK/")
pre = "cd ~/data/DSM/TEAK/ && wget -q "

for(f in 1:length(DSM.files$name)){
  print(paste0("File #",f," ",DSM.files$name[f]))
  file_names = paste0('"',DSM.files$url[f],'"', " -O ", DSM.files$name[f])
  command = paste0(pre,file_names)
  system(command)

} # END f


## Mosaic DSMs
DSM_list <- list.files("~/data/DSM/TEAK/", pattern = glob2rx("*.tif$"), full.names = TRUE)
DSM_list

# These steps from the 'mosaic()' function help files:
DSM_raster_list <- lapply(DSM_list, raster)
names(DSM_raster_list)[1:2] <- c('x', 'y')
DSM_raster_list$fun <- mean
DSM_raster_list$na.rm <- TRUE

print("Begin DSM Mosaic")
after <- Sys.time()
print(after-before)

# Make the mosaic of four CHM tiles
system.time(DSM_mosaic <- do.call(mosaic, DSM_raster_list))

print("End DSM Mosaic")
after <- Sys.time()
print(after-before)

plot(DSM_mosaic, col=terrain.colors(100))


## Do the same for DTM
DTM.files=elev.files$data$files[grep("DTM.tif", elev.files$data$files$name, fixed = T),]

## now, make a loop to download every file by pasting name together

system("mkdir ~/data/DTM/")
system("mkdir ~/data/DTM/TEAK/")
pre = "cd ~/data/DTM/TEAK/ && wget -q "

for(f in 1:length(DTM.files$name)){
  print(paste0("File #",f," ",DTM.files$name[f]))
  file_names = paste0('"',DTM.files$url[f],'"', " -O ", DTM.files$name[f])
  command = paste0(pre,file_names)
  system(command)
  
} # END f


## Mosaic DTMs
DTM_list <- list.files("~/data/DTM/TEAK", pattern = glob2rx("*.tif$"), full.names = TRUE)
DTM_list

# These steps from the 'mosaic()' function help files:
DTM_raster_list <- lapply(DTM_list, raster)
names(DTM_raster_list)[1:2] <- c('x', 'y')
DTM_raster_list$fun <- mean
DTM_raster_list$na.rm <- TRUE

print("Begin DTM Mosaic")
after <- Sys.time()
print(after-before)

# Make the mosaic of four CHM tiles
system.time(DTM_mosaic <- do.call(mosaic, DTM_raster_list))

print("DTM Mosaic Completed")
after <- Sys.time()
print(after-before)

plot(DTM_mosaic, col=terrain.colors(100))

## ----calculate-plot-CHM-------------------------------------------------------------------

# use raster math to create CHM
CHM <- DSM_mosaic - DTM_mosaic

# view CHM attributes
CHM

plot(CHM, main="Lidar Canopy Height Model \n TEAK, California")


## ----write-raster-to-geotiff, eval=FALSE, comment=NA--------------------------------------
# write out the CHM in tiff format. 
writeRaster(CHM,paste0(wd,"CHM_TEAK.tif"),"GTiff", overwrite=T)

after <- Sys.time()
print(after-before)
