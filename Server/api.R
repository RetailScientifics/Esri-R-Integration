#' Define users and API keys, to secure access to this endpoint.
apiCredentials <- tibble(
  id = 1,
  user = c('demo_user'),
  key = c("some_secret_key")
)

#' Allow cross-origin access to this endpoint (https://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
#* @filter cors
function(res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  plumber::forward()
}

#' Only allow endpoint access to users that supply the correct API key with theiry query.
#* @filter api-auth
function(req, res, apikey = "") {
  
  print("Checking for api key...")
  apikey <- toString(apikey)
  
  if ( nchar(apikey) == 0 || !(apikey %in% apiCredentials$key) ) {
    print(GetoptLong::qq("API key not valid (@{apikey}) "))
    res$status <- 401
    return(list(error = "Invalid API key."))
    
  } else {
    print(GetoptLong::qq("API key valid (@{apikey})"))
    req$user <- apiCredentials %>% filter(key == apikey) %>% head(1) %>% pull(user)
    forward()
  }
}

#' The /runmodel endpoint, see standalone_test notebook for details on how to
#' construct, mockup, and test this code locally before deploying to production.
#* @get /runmodel
#* @post /runmodel
#* @serializer unboxedJSON
function(inputDataframe) {
  assign("inputDataframe", inputDataframe, envir = .GlobalEnv)
  
  ## Parse input
  print('Parsing input..')
  input <- jsonlite::fromJSON(inputDataframe) %>%
    as.tibble %>%
    mutate(
      LocationSquareFootage = LocationSquareFootage %>% as.numeric,
      Latitude = Latitude %>% as.numeric,
      Longitude = Longitude %>% as.numeric,
      PopulationDensity = PopulationDensity %>% as.character %>% as.factor,
      PropBoomers = PropBoomers %>% as.character %>% as.factor,
      # Checkboxes aren't sent if they are not clicked:
      HighlyEducated = {if ( "HighlyEducated" %in% names(.) ) TRUE else FALSE },
      ManyWidows = {if ( "ManyWidows" %in% names(.) ) TRUE else FALSE },
      LargePopulation = {if ( "LargePopulation" %in% names(.) ) TRUE else FALSE },
      NeighborsToUse = NeighborsToUse %>% as.integer
    )
  assign("input", input, envir = .GlobalEnv)
  
  ## Stage Spatial Data
  print('Staging data..')
  distances <- geosphere::distm(
    c(input$Longitude, input$Latitude),
    stagedDemographyData[, 0:2]
  ) %>%
    t %>%
    as_tibble %>%
    mutate( index = 1:nrow(.) ) %>%
    rename(Distance = V1)
  
  # Pull the k nearest neighbors
  neighboringDemography <- stagedDemographyData %>%
    select(-MEDHINC_CY) %>%
    mutate(
      Distance = distances$Distance
    ) %>%
    arrange(Distance) %>%
    head(input$NeighborsToUse) %>%
    mutate(
      InvDistance = (1/Distance) / sum(1/.$Distance)
    ) %>%
    mutate(
      Contribution = InvDistance / sum(.$InvDistance)
    ) %>%
    select(
      x, y, Distance, Contribution, everything()
    )
  
  locationDemography <- neighboringDemography %>%
    mutate_each(
      funs( .*Contribution ),
      ASSCDEG_CY:VACANT_FY
    ) %>%
    mutate( collapseID = 1 ) %>%
    group_by( collapseID ) %>%
    summarize_all( funs(sum) ) %>%
    select( ASSCDEG_CY:VACANT_FY )
  
  stagedData <- input %>%
    rename(
      x = Longitude,
      y = Latitude
    ) %>%
    mutate(joinID = 1) %>%
    full_join(
      locationDemography %>% mutate(joinID = 1),
      by = "joinID"
    )
  
  ## Run Model on Staged Data
  print('Running model')

  predicted_revenue <- predict(
    lmFit,
    stagedData
  ) %>% as.numeric %>% round
  
  #' Format output
  outputObject = list(
    'Square Meters' = measurements::conv_unit(input$LocationSquareFootage, 'ft2', 'm2'),
    'Predicted Median Income' = predicted_revenue
  );
  
  print('Model complete.')
  
  #' Return object (automatically converted to JSON)
  return(outputObject);
}

#' A secondary endpoint, showing an example of how to return graphics 
#' such as the outputs of ggplot.
#' This endpoint displays a histogram and density plot of the Median Income 
#' variable within the Shapefile stored on the server.
#* @png
#* @post /plot
#* @get /plot
function() {
  plot <- ggplot( shapefile@data, aes(x = MEDHINC_CY) ) +
    geom_histogram( aes(y = ..density..), bins = 200 ) +
    geom_density( alpha = .2, fill = "#FF6666" ) +
    theme( axis.text.y = element_blank() )
  
  print(plot)
}
