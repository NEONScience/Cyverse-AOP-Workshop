## ----os-avail-query-----------------------------------------------------------------------

# Load the necessary libraries
library(httr)
library(jsonlite)
library(dplyr, quietly=T)
library(downloader)

# Request data using the GET function & the API call
req <- GET("https://data.neonscience.org/api/v0/data/DP3.30006.001/SJER/2019-03")
req


## ----os-query-contents--------------------------------------------------------------------

# View requested data
req.content <- content(req, as="parsed")
names(req.content$data)



## ----os-query-contents-examples-----------------------------------------------------------

# View Abstract
#req.content$data$productAbstract

# View Available months and associated URLs for Onaqui, Utah - ONAQ
#req.content$data$siteCodes[[27]]



## ----os-query-fromJSON--------------------------------------------------------------------
# make this JSON readable -> "text"
req.text <- content(req, as="text")

# Flatten data frame to see available data. 
avail <- jsonlite::fromJSON(req.text, simplifyDataFrame=T, flatten=T)
avail



## ----os-query-avail-data------------------------------------------------------------------

# get data availability list for the product
hyp.urls <- unlist(avail$data$files$url)
length(hyp.urls) #total number of URLs
hyp.urls[1:10] #show first 10 URLs available



## ----os-query-bird-data-urls--------------------------------------------------------------
# get data availability for WOOD July 2015
hyp <- GET(hyp.urls[grep("257000_4112000", hyp.urls)])
hyp.files <- jsonlite::fromJSON(content(hyp, as="text"))

# view just the available data files 
brd.files$data$files



## ----os-get-bird-data---------------------------------------------------------------------

# Get both files
brd.count <- read.delim(brd.files$data$files$url
                        [intersect(grep("countdata", 
                                        brd.files$data$files$name),
                                    grep("basic", 
                                         brd.files$data$files$name))], 
                        sep=",")

brd.point <- read.delim(brd.files$data$files$url
                        [intersect(grep("perpoint", 
                                        brd.files$data$files$name),
                                    grep("basic", 
                                         brd.files$data$files$name))], 
                        sep=",")



## ----os-plot-bird-data--------------------------------------------------------------------
# Cluster by species 
clusterBySp <- brd.count %>%
  dplyr::group_by(scientificName) %>%
  dplyr::summarise(total=sum(clusterSize, na.rm=T))

# Reorder so list is ordered most to least abundance
clusterBySp <- clusterBySp[order(clusterBySp$total, decreasing=T),]

# Plot
barplot(clusterBySp$total, names.arg=clusterBySp$scientificName, 
        ylab="Total", cex.names=0.5, las=2)



## ----soil-data----------------------------------------------------------------------------
# Request soil temperature data availability info
req.soil <- GET("http://data.neonscience.org/api/v0/products/DP1.00041.001")

# make this JSON readable
# Note how we've change this from two commands into one here
avail.soil <- jsonlite::fromJSON(content(req.soil, as="text"), simplifyDataFrame=T, flatten=T)

# get data availability list for the product
temp.urls <- unlist(avail.soil$data$siteCodes$availableDataUrls)

# get data availability from location/date of interest
tmp <- GET(temp.urls[grep("MOAB/2017-03", temp.urls)])
tmp.files <- jsonlite::fromJSON(content(tmp, as="text"))
length(tmp.files$data$files$name) # There are a lot of available files
tmp.files$data$files$name[1:10]   # Let's print the first 10



## ----os-get-soil-data---------------------------------------------------------------------

soil.temp <- read.delim(tmp.files$data$files$url
                        [intersect(grep("002.504.030", 
                                        tmp.files$data$files$name),
                                   grep("basic", 
                                        tmp.files$data$files$name))], 
                        sep=",")



## ----os-plot-soil-data--------------------------------------------------------------------
# plot temp ~ date
plot(soil.temp$soilTempMean~as.POSIXct(soil.temp$startDateTime, 
                                       format="%Y-%m-%d T %H:%M:%S Z"), 
     pch=".", xlab="Date", ylab="T")



## ----aop-data-----------------------------------------------------------------------------
# Request camera data availability info
req.aop <- GET("http://data.neonscience.org/api/v0/products/DP1.30010.001")

# make this JSON readable
# Note how we've changed this from two commands into one here
avail.aop <- jsonlite::fromJSON(content(req.aop, as="text"), 
                      simplifyDataFrame=T, flatten=T)

# get data availability list for the product
cam.urls <- unlist(avail.aop$data$siteCodes$availableDataUrls)

# get data availability from location/date of interest
cam <- GET(cam.urls[intersect(grep("SJER", cam.urls),
                              grep("2017", cam.urls))])
cam.files <- jsonlite::fromJSON(content(cam, as="text"))

# this list of files is very long, so we'll just look at the first ten
head(cam.files$data$files$name, 10)



## ----download-aop-data, eval=FALSE--------------------------------------------------------
## 
## download(cam.files$data$files$url[grep("20170328192931",
##                                        cam.files$data$files$name)],
##          paste(getwd(), "/SJER_image.tif", sep=""), mode="wb")
## 


## ----get-bird-NLs-------------------------------------------------------------------------
# view named location
head(brd.point$namedLocation)



## ----brd-ex-NL----------------------------------------------------------------------------
# location data 
req.loc <- GET("http://data.neonscience.org/api/v0/locations/WOOD_013.birdGrid.brd")

# make this JSON readable
brd.WOOD_013 <- jsonlite::fromJSON(content(req.loc, as="text"))
brd.WOOD_013



## ----brd-extr-NL--------------------------------------------------------------------------

# load the geoNEON package
library(geoNEON)

# extract the spatial data
brd.point.loc <- getLocByName(brd.point)

# plot bird point locations 
# note that decimal degrees is also an option in the data
symbols(brd.point.loc$api.easting, brd.point.loc$api.northing, 
        circles=brd.point.loc$coordinateUncertainty, 
        xlab="Easting", ylab="Northing", tck=0.01, inches=F)



## ----brd-calc-NL--------------------------------------------------------------------------

brd.point.pt <- getLocTOS(brd.point, "brd_perpoint")


# plot bird point locations 
# note that decimal degrees is also an option in the data
symbols(brd.point.pt$easting, brd.point.pt$northing, 
        circles=brd.point.pt$adjCoordinateUncertainty, 
        xlab="Easting", ylab="Northing", tck=0.01, inches=F)



## ----get-loons----------------------------------------------------------------------------
loon.req <- GET("http://data.neonscience.org/api/v0/taxonomy/?family=Gaviidae&offset=0&limit=500")


## ----parse-loons--------------------------------------------------------------------------
loon.list <- jsonlite::fromJSON(content(loon.req, as="text"))


## ----display-loons------------------------------------------------------------------------
loon.list$data


## ----get-mammals--------------------------------------------------------------------------
mam.req <- GET("http://data.neonscience.org/api/v0/taxonomy/?taxonTypeCode=SMALL_MAMMAL&offset=0&limit=500&verbose=true")
mam.list <- jsonlite::fromJSON(content(mam.req, as="text"))
mam.list$data[1:10,]


## ----get-verbena--------------------------------------------------------------------------
am.req <- GET("http://data.neonscience.org/api/v0/taxonomy/?scientificname=Abronia%20minor%20Standl.")
am.list <- jsonlite::fromJSON(content(am.req, as="text"))
am.list$data

