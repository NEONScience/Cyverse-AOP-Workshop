## ----install, eval=F-------------------------------------------------------------------------------------------
## 
## # run once to get the package, and re-run if you need to get updates
## install.packages("sp")  # working with spatial data
## install.packages("rgdal")  # working with spatial data
## install.packages("broom")  # tidy up data
## install.packages("ggplot2")  # plotting
install.packages("neonUtilities")  # work with NEON data
## install.packages("devtools")  # to use the install_github() function
devtools::install_github("NEONScience/NEON-geolocation/geoNEON")  # work with NEON spatial data
## 


## ----libraries, results="hide"---------------------------------------------------------------------------------

# run every time you start a script
library(sp)
library(rgdal)
library(broom)
library(ggplot2)
library(neonUtilities)
library(geoNEON)

options(stringsAsFactors=F)

## ----download-data, results="hide"------------------------------------------------------------------------------

system("mkdir ~/data")
system("cd ~/data && wget https://www.neonscience.org/sites/default/files/NEONDomains_0.zip && unzip NEONDomains_0.zip")
system("cd ~/data && wget https://data.neonscience.org/api/v0/documents/All_NEON_TOS_Plots_V8 -O All_NEON_TOS_Plots_V8.zip && unzip All_NEON_TOS_Plots_V8.zip && rm All_NEON_TOS_Plots_V8.zip")
system("cd ~/data && wget https://www.neonscience.org/science-design/field-sites/export -O field-sites.csv")



# set working directory to ensure R can find the file we wish to import and where
# we want to save our files. 

wd <- "~/data/" # This will depend on your local environment
setwd(wd)



## ----load-domains, results="hide"------------------------------------------------------------------------------

# upload data
neonDomains <- readOGR("NEON_Domains.shp" , layer="NEON_Domains")


## ----create-df, warning=FALSE----------------------------------------------------------------------------------

# First, add a new column termed "id" composed of the row names of the data
neonDomains@data$id <- rownames(neonDomains@data)

# Now, use tidy() to convert to a dataframe
# if you previously used fortify(), this does the same thing. 
neonDomains_points<- tidy(neonDomains, region="id")

# Finally, merge the new data with the data from our spatial object
neonDomainsDF <- merge(neonDomains_points, neonDomains@data, by = "id")


## ----explore-domains-------------------------------------------------------------------------------------------
# view data structure for each variable
str(neonDomainsDF)



## ----plot-domains, fig.width=8, fig.height=6-------------------------------------------------------------------
# plot domains
domainMap <- ggplot(neonDomainsDF) + 
        geom_map(map = neonDomainsDF,
                aes(x = long, y = lat, map_id = id),
                 fill="white", color="black", size=0.3)

domainMap



## ----load-explore-sites----------------------------------------------------------------------------------------
# read in the data
neonSites <- read.delim("field-sites.csv", sep=",", header=T)

# view data structure for each variable
str(neonSites)


## ----plot-sites, fig.width=8, fig.height=6---------------------------------------------------------------------
# plot the sites
neonMap <- domainMap + 
        geom_point(data=neonSites, 
                   aes(x=Longitude, y=Latitude))

neonMap 



## ----sites-color, fig.width=8, fig.height=6--------------------------------------------------------------------
# color is determined by the order that the unique values show up. Check order
unique(neonSites$Site.Type)

# add color
sitesMap <- neonMap + 
        geom_point(data=neonSites, 
                      aes(x=Longitude, y=Latitude, color=Site.Type)) + 
           scale_color_manual(values=c("lightskyblue", "forest green", 
                                       "blue4", "light green"),
                              name="",
                              breaks=unique(neonSites$Site.Type))
sitesMap



## ----TOS-readme------------------------------------------------------------------------------------------------

## load TOS plot readme
rdme <- read.delim('All_NEON_TOS_Plots_V8/readme.csv',
                   sep=',', header=T)

## View the variables
rdme[,1]



## ----get-mam-data, results="hide"------------------------------------------------------------------------------
# load mammal data
mam <- loadByProduct(dpID="DP1.10072.001", site="ONAQ",
                     startdate="2018-08", enddate="2018-08",
                     check.size=F)



## ----find-sp-data----------------------------------------------------------------------------------------------
#
View(mam$variables_10072)



## ----print-mam-------------------------------------------------------------------------------------------------

head(mam$mam_pertrapnight[,1:18])



## ----print-ONAQ020---------------------------------------------------------------------------------------------
# view all trap locations in one plot
mam$mam_pertrapnight[which(mam$mam_pertrapnight$plotID=="ONAQ_020"),
                     c("trapCoordinate","decimalLatitude",
                       "decimalLongitude")]



## ----mam-getLocTOS, results="hide"-----------------------------------------------------------------------------
# download small mam
mam.loc <- getLocTOS(data=mam$mam_pertrapnight,
                           dataProd="mam_pertrapnight")



## ----mam-diff--------------------------------------------------------------------------------------------------
# print variable name that are new
names(mam.loc)[which(!names(mam.loc) %in% names(mam$mam_pertrapnight))]



## ----mam-grids-------------------------------------------------------------------------------------------------
# plot all trap locations at site
plot(mam.loc$adjEasting, mam.loc$adjNorthing, pch=".",
     xlab="Easting", ylab="Northing")



## ----plot-ONAQ003, fig.width=6, fig.height=6-------------------------------------------------------------------
# plot all trap locations in one grid (plot)
plot(mam.loc$adjEasting[which(mam.loc$plotID=="ONAQ_003")], 
     mam.loc$adjNorthing[which(mam.loc$plotID=="ONAQ_003")], 
     pch=".", xlab="Easting", ylab="Northing")



## ----plot-captures, fig.width=6, fig.height=6------------------------------------------------------------------
# plot all captures 
plot(mam.loc$adjEasting[which(mam.loc$plotID == "ONAQ_003")], 
     mam.loc$adjNorthing[which(mam.loc$plotID == "ONAQ_003")], 
     pch=".", xlab="Easting", ylab="Northing")

points(mam.loc$adjEasting[which(mam.loc$plotID == "ONAQ_003" & 
                               mam.loc$trapStatus == "5 - capture")], 
     mam.loc$adjNorthing[which(mam.loc$plotID =="ONAQ_003" &
                              mam.loc$trapStatus == "5 - capture")],
     pch=19, col="blue")



## ----soilT-load, results="hide"--------------------------------------------------------------------------------
# load soil temperature data of interest 
soilT <- loadByProduct(dpID="DP1.00041.001", site="TREE",
                    startdate="2018-07", enddate="2018-07",
                    avg=30, check.size=F)



## ----sens-pos--------------------------------------------------------------------------------------------------
# create object for sens. pos. file
pos <- soilT$sensor_positions_00041

# view names
names(pos)

# view table
View(pos)



## ----pos-levs--------------------------------------------------------------------------------------------------
# view names
unique(pos$HOR.VER)



## ----pos-rem---------------------------------------------------------------------------------------------------

pos <- pos[-intersect(grep("001.", pos$HOR.VER),
                      which(pos$end=="")),]



## ----pos-join--------------------------------------------------------------------------------------------------
# paste horizontalPosition and verticalPosition together
# to match HOR.VER
soilT$ST_30_minute$HOR.VER <- paste(soilT$ST_30_minute$horizontalPosition,
                                    soilT$ST_30_minute$verticalPosition,
                                    sep=".")

# left join to keep all temperature records
soilTHV <- merge(soilT$ST_30_minute, pos, 
                 by="HOR.VER", all.x=T)



## ----soilT-plot------------------------------------------------------------------------------------------------

gg <- ggplot(soilTHV, 
             aes(endDateTime, soilTempMean, 
                 group=zOffset, color=zOffset)) +
             geom_line() + 
        facet_wrap(~horizontalPosition)
gg



## ----soilT-plot-noQF-------------------------------------------------------------------------------------------

gg <- ggplot(subset(soilTHV, finalQF==0), 
             aes(endDateTime, soilTempMean, 
                 group=zOffset, color=zOffset)) +
             geom_line() + 
        facet_wrap(~horizontalPosition)
gg

