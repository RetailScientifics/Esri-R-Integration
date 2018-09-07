#!/usr/bin/env Rscript
library(plumber)
library(GetoptLong)

client_name <- "esri_demo"
client_port <- 8012

dir <- getwd()

# Load and serve the model.
plumb(GetoptLong::qq("@{dir}/models/@{client_name}/api.R"))$run(port = client_port)
