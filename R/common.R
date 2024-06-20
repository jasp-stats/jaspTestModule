tableOfOptions <- function(jaspResults, options, dataset) {
    optDF <- data.frame(optionName=names(options), as.character(options))

    # table for comparison thing in jasp
    jaspResults[['tableOfOptions']] <- createJaspTable(data=optDF, dependencies=names(options), position=-10)

    jaspResults[['dataset']] <- createJaspTable(data=dataset, dependencies=names(options), position=100)
}
