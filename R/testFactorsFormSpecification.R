# The term specification of the Factors Form: per form, the formula of each model as jaspBase::prepareModelTerms() reads
# it, and with a dependent variable the lm() fit with the coefficient labels the form gives the terms.
testFactorsFormSpecificationFuncInternal <- function(jaspResults, dataset, options) {

  tableOfOptions(jaspResults, options, dataset)

  forms <- c("optionalTerms", "forcedTerms", "noInterceptTerms", "basicTerms")
  for (i in seq_along(forms))
    .testModelTermsTable(jaspResults, dataset, options, forms[i], position = i)
}

.testModelTermsTable <- function(jaspResults, dataset, options, name, position) {

  table <- createJaspTable(title = paste("Models of", name), dependencies = c(name, "dependent", "variables"), position = position)
  table$addColumnInfo(name = "model",        title = "Model",           type = "string")
  table$addColumnInfo(name = "formula",      title = "Formula",         type = "string")
  table$addColumnInfo(name = "offset",       title = "Constant offset", type = "number")
  table$addColumnInfo(name = "coefficients", title = "Coefficients",    type = "string")
  jaspResults[[name]] <- table

  prepared <- try(jaspBase::prepareModelTerms(options[[name]], dataset), silent = TRUE)
  if (inherits(prepared, "try-error")) {
    table$setError(attr(prepared, "condition")$message)
    return()
  }

  dependent <- if (nzchar(options[["dependent"]])) options[["dependent"]]
  for (i in seq_along(prepared[["models"]])) {
    formula  <- jaspBase::modelTermsFormula(prepared, i, response = dependent)
    constant <- jaspBase::modelTermsConstantOffset(prepared, i)
    table$addRows(list(
      model        = prepared[["models"]][[i]][["title"]],
      formula      = paste(deparse(formula, width.cutoff = 500L), collapse = " "),
      offset       = constant,
      coefficients = if (is.null(dependent)) "" else .testModelTermsFit(prepared, i, formula, constant, dataset, dependent)
    ))
  }

  if (length(prepared[["nested"]]) > 0L)
    table$addFootnote(paste("Consecutive models nested:", paste(prepared[["nested"]], collapse = ", ")))
}

# The coefficients of the lm() fit of one model, labelled as the form labels its terms
.testModelTermsFit <- function(prepared, model, formula, constant, dataset, dependent) {

  data <- prepared[["data"]]
  data[[dependent]] <- dataset[[dependent]]
  data[[".constantOffset"]] <- rep(constant, nrow(data))  # lm() looks its offset up in the data
  fit <- try(stats::lm(formula, data = data, offset = .constantOffset), silent = TRUE)
  if (inherits(fit, "try-error"))
    return(paste("lm() failed:", attr(fit, "condition")$message))

  coefficients <- stats::coef(fit)
  labels       <- jaspBase::modelTermsLabels(prepared, model, names(coefficients))

  return(paste0(labels, " = ", signif(coefficients, 4), collapse = "; "))
}
