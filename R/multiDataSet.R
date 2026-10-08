# Multi-dataset aware analyses (jasp-desktop branch dataSetAwareVarForm, jaspBase branch
# multiDataSetAware). An analysis whose Description/Analysis entry sets multiDataSetAware gets
# every dataset it references as `datasets`. Engine runs key that list by SLICE id (the resolved
# filter id of each queued dataset+filter pair, attrs "dataSetIds"/"dataSetNames" map a key back),
# jaspTools handouts key it by dataset id - both are indexed safely through jaspBase's helpers.
# Encoding stays PER DATASET: variable options carry names like "JASPColumn_<dataSetId>_<n>_Encoded"
# (each dataset's own ColumnEncoder, prefix embeds the dataset id) and the dataframes' columns are
# the very same strings, so a value indexes its column directly: slice[[value]]. Two differently
# filtered versions of one dataset are two slices, both available; which one a form uses is the
# filter id in its selection option (jaspBase::getSelectionSlice). Result strings are decoded back
# to the original names on the way to the GUI, so putting encoded names in tables/plots is not
# just allowed, it is how provenance survives.
# While such a run is active, readDataSet* stops: one 'current dataset' is meaningless here.

multiDataSetFuncInternal <- function(jaspResults, dataset, options, datasets = NULL) {
  aware <- !is.null(datasets)

  jaspResults[["explanation"]] <- createJaspHtml(paste0(
    if (aware)
      paste0("<b>Aware run.</b> This analysis received ", length(datasets),
             " slice(s) as the `datasets` argument; readDataSet() is disabled while it runs.")
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

  rows <- data.frame(id = character(), title = character(), rows = integer(),
                     cols = integer(), columnNames = character(), stringsAsFactors = FALSE)

  if (!is.null(datasets)) {
    for (key in names(datasets)) {
      df <- datasets[[key]]
      rows <- rbind(rows, data.frame(
        id   = as.character(attr(datasets, "dataSetIds")[[key]] %||% key),
        title = as.character(attr(datasets, "dataSetNames")[[key]] %||% key),
        rows  = nrow(df), cols = ncol(df),
        columnNames = paste(names(df), collapse = ", "),
        stringsAsFactors = FALSE))
    }
  } else if (!is.null(dataset)) {
    rows <- data.frame(id = "(current)", title = "(the one dataset)", rows = nrow(dataset),
                       cols = ncol(dataset), columnNames = paste(names(dataset), collapse = ", "),
                       stringsAsFactors = FALSE)
  }

  table$setData(rows)
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

  rows <- data.frame(source = character(), variable = character(), dataSetId = character(),
                     dataSetName = character(), n = integer(), values = character(),
                     stringsAsFactors = FALSE)

  for (entry in list(list(form = "A", sel = "dataSetA", values = .dependentValues(options$dependentA)),
                     list(form = "B", sel = "dataSetB", values = .dependentValues(options$dependentB)))) {

    for (value in entry$values) {
      # The form's own selection (a filter id) picks the slice its variables live in - two forms
      # on one dataset with different filters then see different rows. Handout runs (jaspTools)
      # carry no filter-keyed selection, so route by the dataset id embedded in the name there
      # (loudly ambiguous when that dataset has several slices - never silently the first!).
      key   <- if (is.null(datasets)) NULL else jaspBase::getSliceKey(options, datasets, entry$sel, column = value)
      slice <- if (is.null(datasets)) dataset else if (!is.null(key)) datasets[[key]] else NULL

      columnData <- if (!is.null(slice) && value %in% names(slice)) slice[[value]] else NULL

      row <- list(
        source      = entry$form,
        variable    = value,
        dataSetId   = if (is.null(datasets)) "-" else if (is.null(key)) as.character(jaspBase::dataSetIdFromEncoded(value)) else jaspBase::sliceDataSetId(datasets, key),
        dataSetName = if (is.null(datasets)) "-" else if (is.null(key)) jaspBase::dataSetNameFromEncoded(value, datasets) else jaspBase::sliceTitle(datasets, key),
        n           = NA_integer_, values = "")

      if (!is.null(columnData))
        row <- .fillDescription(row, columnData)

      rows <- rbind(rows, data.frame(row, stringsAsFactors = FALSE, check.names = FALSE))
    }
  }

  table$setData(rows)
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

`%||%` <- function(x, y) if (is.null(x)) y else x

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
