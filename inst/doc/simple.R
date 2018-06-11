## ------------------------------------------------------------------------
# system("mkdir -p /tmp/testdir")
# setwd("/tmp/testdir")
# closeAllConnections()    # a wise precaution

## ------------------------------------------------------------------------
library(rLambda)
rLambdaInitialize(path="/anaconda3/bin/python")

## ------------------------------------------------------------------------
rm(list=ls())            # clean up
df <- data.frame(x = 1:10, y = 1:10 + rnorm(n=10))
run <- function()  {
  lm(y ~ x, df)
}
rLambdaExecute()

## ------------------------------------------------------------------------
# load("newdata.Rdata")
# summary(result)

## ------------------------------------------------------------------------
# setwd("~")
# system("rm -Rf /tmp/tempdir")

