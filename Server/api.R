# !diagnostics suppress=qq

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
		print(qq("API key not valid (@{apikey}) "))
		res$status <- 401
		return(list(error = "Invalid API key."))

	} else {
		print(qq("API key valid (@{apikey})"))
		req$user <- apiCredentials %>% filter(key == apikey) %>% head(1) %>% pull(user)
		forward()
	}
}


#* @get /runmodel
#* @post /runmodel
#* @serializer unboxedJSON
modelFunction <- function(inputDataframe, latitude, longitude) {
	print('Running model..')

	input <- jsonlite::fromJSON(inputDataframe) %>%
		as.tibble %>%
		mutate(LocationSquareFootage = LocationSquareFootage %>% as.numeric)

	totpop <- getSpatialVariable(latitude, longitude, dmas, 'TOTPOP_CY')

	outputObject = list(
		'Squared SqFt' = input$LocationSquareFootage ^ 2 ,
		'Total Population' = totpop
	);

	# Automatically converts to JSON
	return(outputObject);
}
