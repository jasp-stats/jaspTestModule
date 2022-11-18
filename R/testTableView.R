tableView <- function(jaspResults, dataset, options) {

  dfContinuous <- data.frame(name = options$continuousVariables[[1L]]$values,
                             low  = options$continuousVariables[[2L]]$values,
                             high = options$continuousVariables[[3L]]$values)

  dfCategorical <- data.frame(name = options$categoricalVariables[[1L]]$values)
  if (length(options$categoricalVariables) > 1L)
    for (i in 2:length(options$categoricalVariables))
      dfCategorical[[paste0("level-", i - 1L)]] <- options$categoricalVariables[[i]]$values

  tbContinuous <- createJaspTable("Continuous table")
  tbContinuous$setData(dfContinuous)
  jaspResults[["tbContinuous"]] <- tbContinuous

  tbCategorical <- createJaspTable("Categorical table")
  tbCategorical$setData(dfCategorical)
  jaspResults[["tbCategorical"]] <- tbCategorical

}
