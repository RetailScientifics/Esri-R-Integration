# !diagnostics suppress = getSpatialData, getSpatialVariable, LocationSquareFootage, latitude, longitude, user, MEDHINC_CY

#' Define users and API keys, to secure access to this endpoint.
apiCredentials <- tibble(
  id = 1,
  user = c('demo_user'),
  key = c("some_secret_key")
)

#* @filter cors
cors <- function(res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  plumber::forward()
}

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


#* @get /runmodel
#* @post /runmodel
#* @serializer unboxedJSON
modelFunction <- function(inputDataframe) {
  assign("inputDataframe", inputDataframe, envir = .GlobalEnv)
  
  #' Parse input
  print('Parsing input..')
  input <- jsonlite::fromJSON(inputDataframe) %>%
    as.tibble %>%
    mutate(
      LocationSquareFootage = LocationSquareFootage %>% as.numeric,
      Latitude = Latitude %>% as.numeric,
      Longitude = Longitude %>% as.numeric
    )
  assign("input", input, envir = .GlobalEnv)
  
  #' Stage data
  print('Staging data..')
  stageData <- getSpatialData(input$Latitude, input$Longitude) %>%
    select( colnames(.) %>% order ) %>%
    select( -OBJECTID, -ID, -NAME, -ST_ABBREV ) %>%
    mutate(
      x = input$Latitude,
      y = input$Longitude
    )
  
  #' Run model
  print('Running model')
  predicted_medIncome <- predict(
    lmFit,
    stageData %>% select(-MEDHINC_CY)
  )
  
  actual_medIncome <- stageData %>% pull(MEDHINC_CY)
  
  #' Format output
  outputObject = list(
    'Square Meters' = measurements::conv_unit(input$LocationSquareFootage, 'ft2', 'm2'),
    'Actual Median Income' = actual_medIncome %>% round,
    'Predicted Median Income' = predicted_medIncome %>% round,
    'Percent Error' = (100 * abs(actual_medIncome - predicted_medIncome) / actual_medIncome) %>% round(2)
  );
  
  #' Return object (automatically converted to JSON)
  return(outputObject);
}