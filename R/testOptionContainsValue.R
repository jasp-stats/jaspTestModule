testOptionContainsValue <- function(jaspResults, dataset, options)
{

  if(is.null(jaspResults[['state']])) {
    state <- "empty"
    jaspResults[['state']] <- createJaspState()
    jaspResults[['state']]$dependOn(optionContainsValue = list(restrictedModels = options[["restrictedModels"]][[1]]))
    # alternatively remove once anything in the tabview changed
    # jaspResults[['state']]$dependOn(options = "restrictedModels")
  } else {
    state <- "full"
  }

  jaspResults[['boodschap']] <- createJaspHtml(text=paste0('state for model 1 is: ', state))
}


