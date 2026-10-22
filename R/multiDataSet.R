# Multi-dataset aware analyses (jasp-desktop branch dataSetAwareVarForm, jaspBase branch
# multiDataSetAware). An analysis whose form declares a dataset selection (dataSetSelectionOption
# on a list/textarea - the Analysis finds out by itself, Description.qml no longer has a
# multiDataSetAware property) gets
# every dataset its options reference as `datasets`. Engine runs AND jaspTools::runAnalysis
# handouts both key that list by SLICE id - the resolved filter id of each queued dataset+filter
# pair (attrs "dataSetIds"/"dataSetNames" map a key back to its dataset) - so both are indexed
# the same way: the form's dataset selection option holds exactly that id, `datasets[[key]]` is
# the whole API, no accessor needed (jaspBase's slice-accessor family, e.g. getSelectionSlice,
# was retired with the zero-export datasets contract).
# Encoding stays PER FILTER: variable options carry names like
# "JASPColumn_D<dsId>_F<filterId>_<n>_Encoded" (the filter's encoder-view prefix embeds both
# ids) and the dataframes' columns are the very same strings, so a value indexes its column
# directly: slice[[value]]. Two differently filtered versions of one dataset are two slices,
# both available. Result strings are decoded back to the original names on the way to the GUI
# (Engine::sendString and the rbridge callbacks, all consumers of the one global strict decode
# table), so putting encoded names in tables/plots is not just allowed, it is how provenance
# survives: THE PROVENANCE IS IN THE NAME, never in a side channel. While such
# a run is active, readDataSet* stops: one 'current dataset' is meaningless here.
#
# Options contract (the Phase-3 flip): `options$.meta` is GENERATED at send
# time and carries no dataSetId/filterId; the transient `.filterIds` sidecar is stripped at the
# engine boundary before R sees anything. metaDump() below echoes both facts as the
# PROVENANCE_AUDIT marker the RPC verifier asserts on every run.
#
# Qualified column references: a TERM option may
# arrive with qualified surface forms ("Dataset"."Filter"."Column"("Type"), minimal per
# context); the C++ appliers parse them into typed terms with filterIds before the run, so R
# receives them as ordinary encoded names - no R-side grammar. A STRING option (plain
# text input) receives the qualified form verbatim - the v1 stance: it passes through and
# modules slice on it or not, at their choice; module code that needs to interpret one uses
# the echo pattern of multiDataSetControlsInternal (report what was received, then resolve on
# demand) and never re-implements the token grammar.
#
# The two aware analyses here: multiDataSetFuncInternal (form testMultiDataSet.qml - two
# per-list dataset selection options dataSetA/dataSetB, the wrapper fixture) and
# multiDataSetControlsInternal (the component zoo testMultiDataSetControls.qml,
# assigned lists, row controls with same-name twins, interactions, factor levels
# via encodeThis, a textarea host, a cross-host typed bindTo copy - each reports what it
# received and where it resolved).

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
      # The contract, no accessors: datasets is keyed by FILTER id and the form's dataset
      # selection option holds exactly that id, so the option IS the key - two forms on one
      # dataset with different filters index different slices. attrs dataSetIds/dataSetNames
      # map a key to its dataset (titles are display-only: user-editable, never a key).
      key <- if (is.null(datasets)) NULL else {
        sel <- trimws(as.character(utils::tail(unlist(options[[entry$sel]]), 1L)))
        if (is.na(sel) || !nzchar(sel) || !sel %in% names(datasets)) NULL else sel
      }
      slice <- if (is.null(datasets)) dataset else if (!is.null(key)) datasets[[key]] else NULL

      columnData <- if (!is.null(slice) && value %in% names(slice)) slice[[value]] else NULL

      row <- list(
        source      = entry$form,
        variable    = value,
        dataSetId   = if (is.null(key)) "-" else as.character(attr(datasets, "dataSetIds")[[key]]),
        dataSetName = if (is.null(key)) "-" else as.character(attr(datasets, "dataSetNames")[[key]]),
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
  metaText <- jsonlite::toJSON(if (is.null(meta)) list() else meta, auto_unbox = TRUE, pretty = 2)
  # R must never see provenance - the transient `.filterIds` sidecar is stripped
  # at the engine boundary and the send-time `.meta` carries no dataSetId/filterId.
  # The audit markers echo exactly what arrived so the RPC verifier can assert the contract.
  provenanceKeys <- sum(lengths(regmatches(metaText, gregexpr("dataSetId|filterId", metaText))))
  filterIdsSeen <- !is.null(options[[".filterIds"]])
  jaspResults[["metaDump"]] <- createJaspHtml(paste0(
    "<b>PROVENANCE_AUDIT filterIdsSeen=", if (filterIdsSeen) "true" else "false",
    " metaProvenanceKeys=", provenanceKeys, "</b><br>",
    "<b>options$.meta</b><br><pre>", metaText, "</pre>"))
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

# The non-aware counterpart (multiDataSetNonAwareInternal + Description entry) was removed by
# every other analysis here is already a plain single-dataset one, and the
# twin's generated wrapper had a stale qml pointer so its R entry point always errored. The
# "Non-aware run." branch above stays: it renders whenever `datasets` never arrives (old
# jaspBase, direct Internal calls).

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
