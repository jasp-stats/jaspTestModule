testAnalysisColumnFunc <- function(jaspResults, dataset, options)
{   
    print('options') 
    print(options) 

    if( options[["AddColumnField"]]             == "" &
        options[["ComputedColumnField"]]        == "" &
        options[["AddColumnsPattern"]]          == "" &
        options[["AddComputedColumnsPattern"]]  == "")
    {
        jaspResults[["typeSomethingPlease"]] <- createJaspHtml("Please enter something in one of the textfields to create some columns", dependencies=c('AddColumnField', 'ComputedColumnField', 'AddColumnsPattern', 'AddComputedColumnsPattern'))
    } else {
        jaspResults[["typeSomethingPlease"]] <- createJaspHtml("Columns should be created now, check your data ;)", dependencies=c('AddColumnField', 'ComputedColumnField', 'AddColumnsPattern', 'AddComputedColumnsPattern'))

        if( options[["AddColumnField"]]             != "") 
        {
            createAndFillAJaspColumn(jaspResults, options[["AddColumnField"]], dependencies="AddColumnField")
        }

        if( options[["ComputedColumnField"]]        != "") 
        {
            createAndFillAJaspColumn(jaspResults, options[["ComputedColumnField"]], dependencies="ComputedColumnField")
        }

        if( options[["AddColumnsPattern"]]          != "") 
        {
            container    <- createJaspContainer(dependencies=c("AddColumnsPattern", "AddThisManyColumns"))
            encodedNames <- jaspBase::createColumns(paste0(options$AddColumnsPattern, 1 + 0:options$AddThisManyColumns))

            for(col in encodedNames)
                createAndFillAJaspColumn(container, col, dependencies=c("AddColumnsPattern"))

            jaspResults[["AddColumnsPatternContainer"]] <- container
        }

        if( options[["AddComputedColumnsPattern"]]  != "")
        {
            container    <- createJaspContainer(dependencies=c("AddComputedColumnsPattern", "AddThisManyComputedColumns"))
            encodedNames <- jaspBase::createColumns(paste0(options$AddComputedColumnsPattern, 1 + 0:options$AddThisManyComputedColumns))

            for(col in encodedNames)
                createAndFillAJaspColumn(container, col, dependencies=c("AddComputedColumnsPattern"))

            jaspResults[["AddComputedColumnsPatternContainer"]] <- container
        }
    }
}

generateDataForColumn <- function()
{
    return(rnorm(.dataSetRowCount()))
}

createAndFillAJaspColumn <- function(container, name, dependencies)
{
    col <- createJaspColumn(name, dependencies=dependencies)
    col$setScale(generateDataForColumn())

    container[[name]] <- col
}