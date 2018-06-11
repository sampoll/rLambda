#' rLambdaInitialize
#' 
#' Initialize the interface to the Python 
#' engine and verify that required packages are installed.
#' 
#' By default the R package \code{reticulate} will check the 
#' system and use the first Python engine it finds. This is 
#' often not the one the user wants. A specific Python 
#' executable can be set by passing the path.
#'
#' The interface to AWS is provided by the Python package
#' \code{boto3} and the request and response are sent via JSON.
#' The Python packages \code{boto3} and \code{json} must be installed
#' and available to the requested Python executable.
#'
#' @param path The path to the Python executable to be used.
#' 
#' @examples
#' rLambdaInitialize(path='/anaconda3/bin/python')
#'
#' @importFrom reticulate py_discover_config
#' @importFrom reticulate py_module_available
#' @export

rLambdaInitialize <- function(path)  {
  if (!requireNamespace("reticulate"))
    stop("can't attach R package reticulate")
  Sys.setenv('RETICULATE_PYTHON'=path)
    py_discover_config()
  if (!py_module_available("json"))
    stop("python module json is not installed")
  if (!py_module_available("boto3"))
    stop("python module boto3 is not installed")
}

#' rLambdaExecute 
#'
#' Invoke a AWS Lambda function
#'
#' The Lambda function must be already created. The user's 
#' default credentials will be used to certify the user's
#' permission to invoke the function. Input should be 
#' passed by means of a file with JSON content. This 
#' content will be sent to the Lambda function's 
#' \code{event} parameter.
#'
#' @param jsonin A JSON file with the input to the Lambda function
#' @param lambdafname The name of the Lambda function
#' @return A list with the response key-value pairs.
#'
#' @importFrom reticulate import_builtins
#' @importFrom reticulate import
#' @importFrom reticulate py_to_r
#' @export

rLambdaExecute <- function()  {
  # Save everything in the environment to .Rdata, encode .Rdata in 
  # Base64, and print Base64 string to json. 
  save.image(file="data.Rdata")
  ss <- base64enc::base64encode("data.Rdata")

  system("rm -f r-lambda.json")
  fj <- file("r-lambda.json", "w")
  cat('{ "desc" : "Testing R Lambda function", "rscript" : "', ss, '"}', file=fj, sep="")
  close(fj)

  jsn <- import("json", convert = FALSE)
  bto <- import("boto3", convert = FALSE)
  builtins <- import_builtins()

  payload <- jsn$load(builtins$open("r-lambda.json"))
  lambda.client <- bto$client('lambda')
  response <- lambda.client$invoke(FunctionName='r-lambda',
              InvocationType='RequestResponse',
              Payload=jsn$dumps(payload))

  # Extract Base64 string from response.
  dct <- jsn$loads(response[['Payload']]$read()$decode('utf=8'))
  rdct <- py_to_r(dct)
  sss <- rdct[["RScript"]]

  # Decode Base64 to .Rdata and load .Rdata
  R <- base64enc::base64decode(sss)
  con <- file("newdata.Rdata", "wb")
  writeBin(R, con)
  close(con)

  rm(list=ls())
  load("newdata.Rdata")

}





# For vignette

# Start with a clean environment, because everything is sent
# to Lambda in one Base64 string.
#    rm(list=ls())
#    closeAllConnections()

# By convention, r-lambda runs the function run() once
# and returns everything in the environment.
#    df <- data.frame(x = 1:10, y = 1:10 + rnorm(n=10))
#    run <- function()  {
#      lm(x ~ y, df)
#    }












