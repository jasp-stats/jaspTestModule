testAnalysisColumnFunc <- function(jaspResults, dataset, options)
{
    dataset <- .readFullDatasetToEnd()
    print("testAnalysisColumnFunc")
    print(dataset)
    print(nrow(dataset))

    
    if( options[["AddColumnField"]]             == "" &
        options[["ComputedColumnField"]]        == "" &
        options[["AddColumnsPattern"]]          == "" &
        options[["AddComputedColumnsPattern"]]  == "")
    {
        jaspResults[["typeSomethingPlease"]] <- createJaspHtml("Please enter something in one of the textfields to create some columns", dependencies=c('AddColumnField', 'ComputedColumnField', 'AddColumnsPattern', 'AddComputedColumnsPattern'))
    } else {
        jaspResults[["typeSomethingPlease"]] <- createJaspHtml("Columns should be created now, check your data ;)", dependencies=c('AddColumnField', 'ComputedColumnField', 'AddColumnsPattern', 'AddComputedColumnsPattern'))

        if( options[["AddColumnField"]]             != "") {
            createAndFillAColumn(dataset, jaspResults, options[["AddColumnField"]], dependencies="AddColumnField")
        }

        if( options[["ComputedColumnField"]]        != "") {
            createAndFillAColumn(dataset, jaspResults, options[["ComputedColumnField"]], dependencies="ComputedColumnField")
        }

        if( options[["AddColumnsPattern"]]          != "") 
        {
            container <- createJaspContainer(dependencies=c("AddColumnsPattern", "addThisManyColumns"))

            for(colNum in range(options[["addThisManyColumns"]]))
                createAndFillAColumn(dataset, container, paste0(options[["AddColumnsPattern"]], "_", colNum), dependencies=c("AddColumnsPattern"))

            jaspResults[["AddColumnsPatternContainer"]] <- container
        }

        if( options[["AddComputedColumnsPattern"]]  != "")
        {
            container <- createJaspContainer(dependencies=c("AddComputedColumnsPattern", "addThisManyComputedColumns"))

            for(colNum in range(options[["addThisManyComputedColumns"]]))
                createAndFillAColumn(dataset, container, paste0(options[["AddComputedColumnsPattern"]], "_", colNum), dependencies=c("AddComputedColumnsPattern"))

            jaspResults[["AddComputedColumnsPatternContainer"]] <- container
        }
    }
}

generateDataForColumn <- function(dataset)
{
    rows <- nrow(dataset)
    print("generateDataForColumn")
    print(rows)

    return(rnorm(rows))
}

createAndFillAColumn <- function(dataset, container, name, dependencies)
{
    col <- createJaspColumn(name, dependencies=dependencies)
    col$setScale(generateDataForColumn(dataset))

    container[[name]] <- col
}