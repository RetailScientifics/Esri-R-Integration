#!/usr/bin/env Rscript

client_name <- "esri_demo"
client_port <- 8012
options(digits = 22)

sapply(c(
  'plumber',
  'GetoptLong',
  'tidyverse',
  'rgeos',
  'rgdal',
  'measurements',
  'caret',
  'rjson'
), function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, quiet = TRUE)
  }
  require(p, character.only = TRUE, quietly = TRUE)
})
print("Libraries loaded. Now loading static files.")

strInterpolate <- GetoptLong::qq


# Load in shapefiles and model files
shapefile <- readOGR(
  dsn = strInterpolate("@{getwd()}/files/2016_Population_Density_by_Congressional_District.shp"),
  stringsAsFactors = FALSE
)

shapefile@data <- shapefile@data %>%
  mutate_at(vars(TOTPOP_CY:GenSilent), as.numeric)

lmFit <- readr::read_rds(strInterpolate("@{getwd()}/files/linear_model.rds"))

# Set up functions
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

# Start API server
print('Static files loaded. Now loading model function and serving API endpoint.')
p <- plumb(strInterpolate("@{getwd()}/models/@{client_name}/api.R"))
p$run(port = client_port)