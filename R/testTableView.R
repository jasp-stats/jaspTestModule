tableView <- function(jaspResults, dataset, options) {
  tableOfOptions(jaspResults, options, dataset)
  

  testTypeData <- data.frame(String = options$testTypes[[1L]]$values,
                             Integer  = options$testTypes[[2L]]$values,
                             Double = options$testTypes[[3L]]$values)

  testButtonData <- data.frame(name = options$testButtons[[1L]]$values)
  if (length(options$testButtons) > 1L)
    for (i in 2:length(options$testButtons))
      testButtonData[[paste0("level-", i - 1L)]] <- options$testButtons[[i]]$values

  testTypeTable <- createJaspTable("Test types table")
  testTypeTable$setData(testTypeData)
  jaspResults[["testTypeTable"]] <- testTypeTable

  testButtonTable <- createJaspTable("Test Button table")
  testButtonTable$setData(testButtonData)
  jaspResults[["testButtonTable"]] <- testButtonTable
}
