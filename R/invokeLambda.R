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
#' This functon has no parameters. The entire local environment will be sent 
#' to the R server. The local environment should have a no-parameter function 
#' called \code{run}. This function will be run, and it's return value will be
#' placed in the local environment with name \code{result}. Additionally, 
#' any variables the \code{run()} function assigns to the enclosing 
#' environment will be present when \code{rLambdaExecute} returns.
#'
#' (Note: this functionality is not working, for reasons still to be 
#' clarified. To get the final environment, it is necessary to 
#' execute \code{load("newdata.Rdata")}.)
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

