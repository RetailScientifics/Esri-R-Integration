#!/usr/bin/env Rscript

client_name <- "esri_demo"
client_port <- 8012

sapply(c(
	'plumber',
	'tidyverse'
), function(p) {
	if (!requireNamespace(p, quietly = TRUE)) {
		install.packages(p, quiet = TRUE)
	}
	require(p, character.only = TRUE, quietly = TRUE)
})
print("Libraries loaded. Now loading static files.")

shapefile <- readOGR(
	dsn = "files/2016_Population_Density_by_Congressional_District.shp",
	stringsAsFactors = FALSE
)

shapefile@data <- shapefile@data %>%
	mutate_at(vars(TOTPOP_CY:GenSilent), as.numeric)

print('Static files loaded. Now loading model function and serving API endpoint.')
plumb(GetoptLong::qq("@{getwd()}/models/@{client_name}/api.R"))$run(port = client_port)
