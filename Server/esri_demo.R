#!/usr/bin/env Rscript

#' Similar to server-side setup in standalone_test.Rmd (almost a direct copy!)
#' Note that this is the actual file that must be run to start the server - in turn,
#' it sources api.R to define its endpoints.
#' 
#' For more information on how to set up endpoints, refer to the documentation
#' for the plumber package at https://www.rplumber.io/
#' 
#' This file can be run within RStudio, or as a standalone executable script.

options(digits = 22)

# Setup

## Libraries
sapply(c(
	'plumber',
	'GetoptLong',
	'tidyverse',
	'rgeos',
	'rgdal',
	'measurements',
	'caret',
	'rjson',
	'geosphere'
), function(p) {
	if (!requireNamespace(p, quietly = TRUE)) {
		install.packages(p, quiet = TRUE)
	}
	require(p, character.only = TRUE, quietly = TRUE)
})
print("Libraries loaded. Now loading static files.")

strInterpolate <- GetoptLong::qq

numConv <- function(x) {
	return(x %>% as.character %>% as.numeric)
}

getSpatialData <- function(lat, long) {
	thisPoint <- SpatialPoints(
		coords = tibble(
			long = long,
			lat = lat
		),
		proj4string = CRS(proj4string(shapefile))
	)
	result <- over(thisPoint, shapefile)
	return(result)
}

getSpatialVariable <- function(lat, long, variable) {
	result <- getSpatialData(lat, long)
	outputVar <- result[[variable]]
	return( if (outputVar %>% is.na) 0 else numConv(outputVar) )
}

## Static Files
lmFit <- readr::read_rds("./files/linear_model.rds")

shapefile <- rgdal::readOGR(
	dsn = "./files/2016_Population_Density_by_Congressional_District.shp",
	stringsAsFactors = FALSE
)

shapefile@data <- shapefile@data %>%
	mutate_at(
		vars(TOTPOP_CY:GenSilent),
		function(x) x %>% as.numeric %>% round(10)
	)

stagedDemographyData <- SpatialPointsDataFrame(gCentroid(shapefile, byid = TRUE), shapefile@data) %>%
	as.tibble() %>%
	select( colnames(.) %>% order ) %>%
	select( -OBJECTID, -ID, -NAME, -ST_ABBREV ) %>%
	select( x, y, everything() ) %>%
	# Dropping derived columns
	select(
		-POPDENS_CY, -GenBoom, -GRADDEG_CY, -WIDOWED_CY, -HHPOP_CY
	) %>%
	# Rearrange columns to see relevant variables in output
	select(
		x, y, MEDHINC_CY, everything()
	)


#' Start API server
#' Note: everything above this is preparatory code, these lines actually spin up the 
#' server and create a live endpoint.
print('Static files loaded. Now loading model function and serving API endpoint.')
p <- plumb("./api.R")
p$run(port = 8001)

# You should now be able to access localhost:8001/plot in your browser, for example. If this is 
# deployed on a remote server, substitute the server's domain name or IP address for localhost.
# This also requires port 8001 to be open, which may require adjusting firewall settings.