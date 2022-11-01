testStateFunc <- function(jaspResults, dataset, options) {

  if (is.null(jaspResults[['state']]))
    jaspResults[['state']] <- createJaspState(options$saveMe, dependencies=c("checkbox_0", "saveMe"))

  jaspResults[['boodschap']] <- createJaspHtml(text=paste0('state contains: ', jaspResults[['state']]$object), position = 1)


  remade <- FALSE
  if (is.null(jaspResults[['stateMustContain']])) {
    remade <- TRUE
    variablesOrder <- options[["variablesForState"]]
    obj <- createJaspState(options$saveMe, dependencies = "saveMe")
    obj$dependOn(optionContainsValue = list("variables" = variablesOrder))
    jaspResults[['stateMustContain']] <- obj
  }
  text <- if (remade)
    sprintf("recreated stateMustContain, dependencies are %s", paste(variablesOrder, collapse = ", "))
  else
    sprintf("stateMustContain retrieved from state")

  jaspResults[['boodschap2']] <- createJaspHtml(text = text, position = 2)

  if (length(options[["tabview"]]) == 0)
    return()

  remade <- FALSE
  if (is.null(jaspResults[['nestedDepends']])) {
    remade <- TRUE
    obj <- createJaspState(options$saveMe)
    obj$dependOn(nestedOptions = c("tabview", 1, "checkbox_2"))
    jaspResults[['nestedDepends']] <- obj
  }
  text <- if (remade)
    sprintf("recreated nestedDepends")
  else
    sprintf("nestedDepends retrieved from state")

  jaspResults[['boodschap3']] <- createJaspHtml(text = text, position = 3)

  for (i in seq_along(options[["tabview"]])) {

    jaspKey <- paste0("nestedMustContain", i)
    remade <- FALSE
    if (is.null(jaspResults[[jaspKey]])) {
      remade <- TRUE
      obj <- createJaspState(options$saveMe, dependencies = "saveMe")
      variablesOrder <- options[["tabview"]][[i]][["variablesForState"]]
      if (is.null(variablesOrder))
        variablesOrder <- ""
      obj$dependOn(nestedOptionsContainsValue = list(key = c("tabview", i, "variables"), value = variablesOrder))
      jaspResults[[jaspKey]] <- obj
    }
    text <- if (remade)
      sprintf("recreated nestedMustContain_%d, dependencies are %s", i, paste(variablesOrder, collapse = ", "))
    else
      sprintf("nestedMustContain__%d retrieved from state", i)

    boodschapKey <- paste0("boodschap", jaspKey)
    jaspResults[[boodschapKey]] <- createJaspHtml(text = text, position = 10 + i)

  }

}


