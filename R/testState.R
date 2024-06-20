testStateFunc <- function(jaspResults, dataset, options) {
  tableOfOptions(jaspResults, options, dataset)
  

  if (is.null(jaspResults[['state']]))
    jaspResults[['state']] <- createJaspState(options$saveMe, dependencies=c("checkbox_0", "saveMe"))

  jaspResults[['boodschap']] <- createJaspHtml(text=paste0('state contains: ', jaspResults[['state']]$object), position = 1)


  #Must contain should support both a single value being in a list, or all values in a list.
  #First multiple values in contains
  #Not however all values! Because then we could just use the normal dependencies...
  remade <- FALSE
  if (is.null(jaspResults[['stateMustContainMultiple']])) {
    remade <- TRUE
    variablesOrder <- options[["variablesForState"]]

    if(length(variablesOrder) > 1) {
      variablesOrder <- variablesOrder[-1] #Drop one element

      obj <- createJaspState(options$saveMe, dependencies = "saveMe")
      obj$dependOn(optionContainsValue = list("variablesForState" = variablesOrder))
      jaspResults[['stateMustContainMultiple']] <- obj
    
      text <- sprintf("recreated stateMustContainMultiple, dependencies are %s", paste(variablesOrder, collapse = ", "))
    }
    else
      text <- "Add more variables!"
  }
  else
    text <- sprintf("stateMustContainMultiple retrieved from state")

  jaspResults[['boodschap2']] <- createJaspHtml(text = text, position = 2)


  
  placePos <- 3
  #here a single variable in a list should be enough for keeping it or dropping it
  for(v in options[["variablesForState"]]) {
    nameState <- paste0('stateMustContainSingle', v)

    remade <- FALSE
    if (is.null(jaspResults[[nameState]])) {
      remade <- TRUE
      obj <- createJaspState(options$saveMe, dependencies = "saveMe")
      obj$dependOn(optionContainsValue = list("variablesForState" = v))
      jaspResults[[nameState]] <- obj
    }
    text <- if (remade)
      sprintf("recreated %s, dep is %s and values are %s", nameState, v, paste(options[["variablesForState"]], collapse = ", "))
    else
      sprintf("%s retrieved from state", nameState)


    boodschapObj                             <- createJaspHtml(text = text, position = placePos )
    jaspResults[[paste0('boodschap2_', v) ]] <- boodschapObj
    jaspResults[[paste0('boodschap2_', v) ]]$dependOn(optionsFromObject=jaspResults[[nameState]])

    placePos <- placePos + 1
  }

  
  if (length(options[["tabview"]]) == 0)
    return()

  remade <- FALSE
  if (is.null(jaspResults[['nestedDepends']])) {
    remade <- TRUE
    obj <- createJaspState(options$saveMe, dependencies = "saveMe")
    obj$dependOn(nestedOptions = c("tabview", 1, "checkbox_2"))
    jaspResults[['nestedDepends']] <- obj
  }
  text <- if (remade)
    sprintf("recreated nestedDepends")
  else
    sprintf("nestedDepends retrieved from state")

  jaspResults[['boodschap3']] <- createJaspHtml(text = text, position = placePos)

  for (i in seq_along(options[["tabview"]])) {

    jaspKey <- paste0("nestedMustContain", i)

    remade <- FALSE
    if (is.null(jaspResults[[jaspKey]])) {
      remade <- TRUE
      obj <- createJaspState(options$saveMe, dependencies = "saveMe")
      variablesOrder <- options[["tabview"]][[i]][["variablesForState"]]
      if (is.null(variablesOrder))
        variablesOrder <- "" # ??? That won't be a proper dependency will it?

      if(length(variablesOrder) > 1)
        variablesOrder <- variablesOrder[-1]

      obj$dependOn(nestedOptionsContainsValue = list(key = c("tabview", i, "variablesForState"), value = variablesOrder))
      jaspResults[[jaspKey]] <- obj
    }
    text <- if (remade)
      sprintf("recreated nestedMustContain_%d, dependencies are %s", i, paste(variablesOrder, collapse = ", "))
    else
      sprintf("nestedMustContain__%d retrieved from state", i)

    boodschapKey <- paste0("boodschap", jaspKey)
    jaspResults[[boodschapKey]] <- createJaspHtml(text = text, position = placePos + i)

  }

}


