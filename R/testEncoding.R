testEncodingFunc <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  
  showData(dataset, jaspResults, "encodingsEtc", unlist(options$selected), "Selected data", options$genericFilter)
  showData(dataset, jaspResults, "variablesWithInteractions", unlist(options$variablesWithInteractions), "Variables With Interactions")
  showData(dataset, jaspResults, "variablesInsideComponentsList", unlist(options$componentsList[[1]]$variablesInComponentsList), "First Variables Inside Components List")
  showData(dataset, jaspResults, "variablesPairs", unlist(options$pairs), "Pairs Variables")
}

testEncodingPreloadDataFunc <- testEncodingFunc

showData <- function(dataset, jaspResults, name, cols, title, filter = "")
{
  if (is.null(dataset))
    dat <- .readDataSetToEnd(columns=cols)
  else
    dat <- dataset

  tab  <- createJaspTable(title)

  jaspResults[[name]] <- tab

  filName <- function(col) { return(paste0(col, "_filtered")); }

  for(col in cols)
  {
    print(paste0("Working on col: ", col))

    tab$addColumnInfo(name=col)
    colDat      <- dat[[.v(col)]]
    tab[[col]]  <- as.character(colDat)

    if (filter != "")
    {
        tab$addColumnInfo(name=filName(col))
        tab[[filName(col)]] <- eval(parse(text=paste0("colDat ", filter)))
    }
  }
}
