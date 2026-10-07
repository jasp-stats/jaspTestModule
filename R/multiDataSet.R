# Multi-dataset aware analyses (jasp-desktop branch dataSetAwareVarForm, jaspBase branch
# multiDataSetAware). An analysis whose Description/Analysis entry sets multiDataSetAware gets
# every dataset it references as `datasets`: a named list keyed by dataset id, with the user
# facing titles in attr(datasets, "dataSetNames"). Options and data share the ENCODED namespace:
# variable options carry names like "JASPColumn_<dataSetId>_<n>_Encoded" and the dataframes'
# column names are the very same strings (encoded by each dataset's own ColumnEncoder, whose
# prefix embeds the dataset id), so an analysis indexes with the option value as-is:
# getDataSetColumn(value, datasets) / datasets[[id]][[value]]. Result strings are decoded back to
# the original names on their way to the GUI, so putting encoded names in tables/plots is not
# just allowed, it is how provenance survives. jaspBase's dataSetIdFromEncoded /
# dataSetNameFromEncoded / getDataSetFor route values to their dataset.
# While such a run is active, readDataSet* stops: one 'current dataset' is meaningless here.

multiDataSetFuncInternal <- function(jaspResults, dataset, options, datasets = NULL) {
  aware <- !is.null(datasets)

  jaspResults[["explanation"]] <- createJaspHtml(paste0(
    if (aware)
      paste0("<b>Aware run.</b> This analysis received ", length(datasets),
             " dataset(s) as the `datasets` argument; readDataSet() is disabled while it runs.")
    else
      "<b>Non-aware run.</b> No `datasets` argument: data comes in through `dataset`/readDataSet as always, and the dataset selection in the form should have been inert.",
    "<br><br>Use two datasets in the workspace (File - New data set or add another CSV) and drag variables from both into the variables form."))

  dataSetOverviewTable(jaspResults, datasets, dataset)
  selectedVariablesTable(jaspResults, options, datasets, dataset)

  if (isTRUE(options$showMeta))
    metaDump(jaspResults, options)

  if (isTRUE(options$guardDemo))
    readDataSetGuardDemo(jaspResults)
}

dataSetOverviewTable <- function(jaspResults, datasets, dataset) {
  table <- createJaspTable("Datasets in this run")
  jaspResults[["dataSetOverview"]] <- table

  table$addColumnInfo("id",       title = "Dataset id")
  table$addColumnInfo("title",    title = "Title")
  table$addColumnInfo("rows",     title = "Rows")
  table$addColumnInfo("cols",     title = "Columns")
  table$addColumnInfo("columnNames", title = "Column names (decoded on the way out)")

  if (!is.null(datasets)) {
    titles <- attr(datasets, "dataSetNames")

    for (id in names(datasets)) {
      df <- datasets[[id]]
      table[[id]] <- list(
        id = id, title = titles[[id]], rows = nrow(df), cols = ncol(df),
        columnNames = paste(names(df), collapse = ", "))
    }
  } else if (!is.null(dataset)) {
    table[["current"]] <- list(
      id = "(current)", title = "(the one dataset)", rows = nrow(dataset), cols = ncol(dataset),
      columnNames = paste(names(dataset), collapse = ", "))
  }
}

selectedVariablesTable <- function(jaspResults, options, datasets, dataset) {
  table <- createJaspTable("Selected variables")
  jaspResults[["selectedVariables"]] <- table

  table$addColumnInfo("source",     title = "Form")
  table$addColumnInfo("variable",   title = "Variable (decoded on the way out)")
  table$addColumnInfo("dataSetId",  title = "Dataset id")
  table$addColumnInfo("dataSetName", title = "Dataset title")
  table$addColumnInfo("n",          title = "n")
  table$addColumnInfo("values",     title = "mean (scale) / first levels (factor)")

  for (entry in list(list(form = "A", values = .dependentValues(options$dependentA)),
                     list(form = "B", values = .dependentValues(options$dependentB)))) {
    for (value in entry$values) {
      # value indexes the data as-is in both modes: options and column names share the encoded
      # namespace (or are both plain, in a jaspTools run). Only the routing to one dataset out
      # of `datasets` is aware-specific; the non-aware run has exactly the one dataset anyway.
      columnData <- if (is.null(datasets)) {
        if (!is.null(dataset) && value %in% names(dataset)) dataset[[value]] else NULL
      } else {
        jaspBase::getDataSetColumn(value, datasets)
      }

      id  <- if (is.null(datasets)) NA_integer_ else jaspBase::dataSetIdFromEncoded(value)
      row <- list(
        source      = entry$form,
        variable    = value,
        dataSetId   = if (is.null(datasets)) "-" else if (is.na(id)) "none (legacy)" else as.character(id),
        dataSetName = if (is.null(datasets)) "-" else jaspBase::dataSetNameFromEncoded(value, datasets),
        n           = NA_integer_, values = "")

      if (!is.null(columnData))
        row <- .fillDescription(row, columnData)

      table[[paste0(entry$form, ":", value)]] <- row
    }
  }
}

metaDump <- function(jaspResults, options) {
  meta <- options[[".meta"]]
  jaspResults[["metaDump"]] <- createJaspHtml(paste0(
    "<b>options$.meta</b><br><pre>",
    jsonlite::toJSON(if (is.null(meta)) list() else meta, auto_unbox = TRUE, pretty = 2),
    "</pre>"))
}

readDataSetGuardDemo <- function(jaspResults) {
  message <- tryCatch(
    {
      .readDataSetToEnd(columns = "MPG")   # would work outside an aware run
      "<b>No error</b> - readDataSet() should have stopped though! (not in multi-dataset mode?)"
    },
    error = function(e) paste0("<b>readDataSet() stopped it, as it should:</b><br>",
                               "<pre>", conditionMessage(e), "</pre>"))

  jaspResults[["guardDemo"]] <- createJaspHtml(message)
}

# Non-aware counterpart (Description entry func: "multiDataSetNonAware"; the engine appends
# Internal because hasWrappers is on for the whole module). Same form and body, but reached
# through the old single-dataset path: no datasets argument, so readDataSet/dataset rule.
multiDataSetNonAwareInternal <- function(jaspResults, dataset, options) {
  multiDataSetFuncInternal(jaspResults, dataset, options)
}

# ------------------------------------------------------------------ internals

.dependentValues <- function(values) {
  if (is.null(values)) return(character(0))
  values <- unlist(values, recursive = TRUE)
  as.character(values[!is.na(values) & as.character(values) != ""])
}

.fillDescription <- function(entry, columnData) {
  if (is.numeric(columnData)) {
    entry$n      <- sum(!is.na(columnData))
    entry$values <- sprintf("mean %.2f, sd %.2f", mean(columnData, na.rm = TRUE), sd(columnData, na.rm = TRUE))
  } else {
    levels <- unique(as.character(stats::na.omit(columnData)))
    entry$n      <- length(stats::na.omit(columnData))
    entry$values <- paste(utils::head(levels, 5), collapse = ", ")
  }
  entry
}
