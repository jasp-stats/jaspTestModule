testAnalysisColumnFunc <- function(jaspResults, dataset, options)
{   
  tableOfOptions(jaspResults, options)

    if( options[["AddColumnField"]]             == "" &
        options[["ComputedColumnField"]]        == "" &
        options[["AddColumnsPattern"]]          == "")
    {
        jaspResults[["typeSomethingPlease"]] <- createJaspHtml("Please enter something in one of the textfields to create some columns", dependencies=c('AddColumnField', 'ComputedColumnField', 'AddColumnsPattern', 'AddComputedColumnsPattern'))
    } 
    else 
    {
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
            baseNames    <- paste0(options$AddColumnsPattern, 1:options$AddThisManyColumns)
            encodedNames <- jaspBase::createColumns(baseNames)

            #createColumns returns a list of the encoded columnnames, but if it returns only one and only one was requested it might be empty?
            if(length(encodedNames) == length(baseNames))
            {
                for(col in encodedNames)
                    createAndFillAJaspColumn(container, col, dependencies=c("AddColumnsPattern"))

                jaspResults[["AddColumnsPatternContainer"]] <- container
            }
            else 
            {
                nameString <- paste0(baseNames, collapse=", ")
                jaspResults[["AddColumnsPatternProblem"]] <- createJaspHtml(paste0("A column this analysis tried to add already exists, change the pattern.\nGenerated names are: '", nameString,"'"), dependencies="AddColumnsPattern", elementType="errorMsg")
            }
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