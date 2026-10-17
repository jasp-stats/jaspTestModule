# mds-plan D6.1 - the component-zoo echo. Receives the generated options + the per-slice
# `datasets` (contract: keyed by SLICE/filter id, attrs dataSetIds/dataSetNames map a key back
# to its dataset - see multiDataSet.R for the full contract notes) and reports, per control
# family, EVERY value exactly as received: the encoded name (results are decoded on the way out,
# which is itself part of what we verify), which slice index it resolved in, and the row
# children. Tools/verifyMultiDataSetRpc.py asserts all of it. Cheap by design: no statistics
# beyond a mean/level-list per resolved column.
#
# Families (see inst/qml/testMultiDataSetControls.qml):
#   assigned-list        Zoo A - plain assigned list under a selecting available list
#   combobox-host        Zoo A - DropDown served by the same host: value stays a PLAIN STRING
#   assigned-host        Zoo B - assigned list that IS its own selection host
#   components-rows      Zoo C - row-bearing variables list (the TableFields shape; shared
#                                 RowControls/TermRowKey machinery): per-row term + keep + shift;
#                                 same-name twin rows from two filters keep their OWN
#                                 children (the D6.1 TermRowKey re-keying)
#   interaction-list     Zoo D - combination terms: all components share the term filterId
#   factor-levels        Zoo E - encodeThis -> extras roundtrip (names never slice columns;
#                                 they must come back decoded, no raw JaspExtraOptions_ leakage)
#   textarea-host        Zoo F - R-code textarea: used columns encoded through its own host
#   bindto-cross-host    Zoo G - typed copy bound across differently-selected hosts: keeps the
#                                 SOURCE filterId, encodes through the SOURCE's view (D6.2)
#   scalar               M5 contract - plain values, no provenance anywhere

multiDataSetControlsFuncInternal <- function(jaspResults, dataset, options, datasets = NULL) {
  aware <- !is.null(datasets)

  jaspResults[["explanation"]] <- createJaspHtml(paste0(
    if (aware)
      paste0("<b>Aware run.</b> Component zoo received ", length(datasets),
             " slice(s) as `datasets`; every family below echoes what it received.")
    else
      "<b>Non-aware run.</b> No `datasets` argument: this analysis must run multiDataSetAware for the routing tables to mean anything.",
    "<br>See the check list at the top of Tools/verifyMultiDataSetRpc.py's zoo section for what each family proves."))

  dataSetOverviewTable(jaspResults, datasets, dataset)
  controlsProvenanceTable(jaspResults, options, datasets)

  if (isTRUE(options$showMeta))
    metaDump(jaspResults, options)
}

# ------------------------------------------------------------------ resolution helpers

.resolveSlice <- function(token, datasets) {
  # an aware option value IS the encoded column name of exactly one slice (C1/C3): index it
  if (is.null(datasets) || !is.character(token) || length(token) != 1 || !nzchar(token))
    return(NULL)
  hits <- names(datasets)[vapply(names(datasets),
                                 function(k) token %in% names(datasets[[k]]), logical(1))]
  if (length(hits) == 0) NULL else hits[[1]]
}

.sliceMeta <- function(key, datasets) {
  if (is.null(key)) return(list(id = "-", name = "-"))
  dsId   <- attr(datasets, "dataSetIds")[[key]]
  dsName <- attr(datasets, "dataSetNames")[[key]]
  list(id   = if (is.null(dsId))   as.character(key) else as.character(dsId),
       name = if (is.null(dsName)) as.character(key) else as.character(dsName))
}

.describeValue <- function(key, token, datasets) {
  if (is.null(key)) return(list(n = NA_integer_, values = ""))
  .fillDescription(list(n = NA_integer_, values = ""), datasets[[key]][[token]])
}

# ------------------------------------------------------------------ the echo table

controlsProvenanceTable <- function(jaspResults, options, datasets) {
  table <- createJaspTable("Controls provenance")
  jaspResults[["controlsProvenance"]] <- table

  table$addColumnInfo("family",   title = "Family")
  table$addColumnInfo("option",   title = "Option")
  table$addColumnInfo("received", title = "Received value (decoded on the way out)")
  table$addColumnInfo("rowChild", title = "Row children")
  table$addColumnInfo("slice",    title = "Resolved slice (filter id)")
  table$addColumnInfo("dataSetId", title = "Dataset id")
  table$addColumnInfo("n",        title = "n")
  table$addColumnInfo("values",   title = "mean (scale) / levels (factor)")

  rows <- data.frame(family = character(), option = character(), received = character(),
                     rowChild = character(), slice = character(), dataSetId = character(),
                     n = integer(), values = character(), stringsAsFactors = FALSE)

  addRow <- function(df, family, option, received, rowChild = "", key = NULL,
                     n = NA_integer_, values = "") {
    meta <- .sliceMeta(key, datasets)
    rbind(df, data.frame(family = family, option = option, received = as.character(received),
                         rowChild = as.character(rowChild),
                         slice = if (is.null(key)) "-" else as.character(key),
                         dataSetId = meta$id, n = n, values = as.character(values),
                         stringsAsFactors = FALSE, check.names = FALSE))
  }

  # --- plain term lists: Zoo A / Zoo B / Zoo G ----------------------------------------------------
  for (entry in list(
      list(fam = "assigned-list",       opt = "assignedA", vals = .dependentValues(options$assignedA)),
      list(fam = "assigned-host",       opt = "assignedB", vals = .dependentValues(options$assignedB)),
      list(fam = "bindto-cross-host",   opt = "boundG",    vals = .dependentValues(options$boundG)))) {
    for (value in entry$vals) {
      key  <- .resolveSlice(value, datasets)
      desc <- .describeValue(key, value, datasets)
      rows <- addRow(rows, entry$fam, entry$opt, value, key = key, n = desc$n, values = desc$values)
    }
  }

  # --- combobox served by Zoo A's host: PLAIN string value (never term-objectified) ---------------
  combo <- trimws(as.character(utils::tail(unlist(options$comboA), 1L)))
  if (!is.na(combo) && nzchar(combo) && !identical(combo, "0")) {
    key  <- .resolveSlice(combo, datasets)
    desc <- .describeValue(key, combo, datasets)
    rows <- addRow(rows, "combobox-host", "comboA", combo, key = key, n = desc$n, values = desc$values)
  }

  # --- ComponentsList rows (Zoo C): per-row term + its OWN row children ----------------------------
  rowsC <- options$rowsC
  if (!is.null(rowsC) && is.list(rowsC) && !is.null(rowsC$value) && is.list(rowsC$value))
    rowsC <- rowsC$value                                  # tolerate a {value, ...} wrapper
  if (!is.null(rowsC) && is.list(rowsC)) {
    for (row in rowsC) {
      if (!is.list(row)) next
      tokens <- as.character(unlist(row$variable))
      token  <- if (length(tokens) > 0) tokens[[1]] else ""
      if (!nzchar(token)) next
      key  <- .resolveSlice(token, datasets)
      desc <- .describeValue(key, token, datasets)
      child <- paste0("keep=", if (is.null(row$keep)) "NA" else as.logical(row$keep),
                      ", shift=", if (is.null(row$shift)) "NA" else as.character(row$shift))
      rows <- addRow(rows, "components-rows", "rowsC", token, rowChild = child,
                     key = key, n = desc$n, values = desc$values)
    }
  }

  # --- interaction terms (Zoo D): components of one row share the term filterId --------------------
  # jaspBase hands {value,types} options UNWRAPPED to the analysis (the value list directly,
  # types as the sibling optionX.types), so accept both shapes.
  inter <- options$interactionD
  if (!is.null(inter) && is.list(inter)) {
    interRows <- if (!is.null(inter$value)) inter$value else inter
    for (row in interRows) {
      comps <- as.character(unlist(row$components))
      if (length(comps) == 0) next
      keys <- unique(vapply(comps, function(c) {
        k <- .resolveSlice(c, datasets); if (is.null(k)) "-" else k
      }, character(1)))
      joint <- if (length(keys) == 1 && keys[[1]] != "-") keys[[1]] else NULL
      rows <- addRow(rows, "interaction-list", "interactionD",
                     paste(comps, collapse = " : "), rowChild = paste0("order=", length(comps)),
                     key = joint,
                     n = if (is.null(joint)) NA_integer_ else
                       sum(!is.na(datasets[[joint]][[comps[[1]]]])),
                     values = if (is.null(joint)) paste("slices:", paste(keys, collapse = "/")) else
                       paste0("components share slice ", joint))
    }
  }

  # --- factor levels (Zoo E): extras-encoded names, NOT slice columns ------------------------------
  factors <- options$factorsE
  if (!is.null(factors) && is.list(factors)) {
    for (f in factors) {
      if (!is.list(f) || is.null(f$name)) next
      levels <- as.character(unlist(f$levels))
      rows <- addRow(rows, "factor-levels", "factorsE", f$name,
                     rowChild = paste(levels, collapse = ", "),
                     values = paste0(length(levels), " level(s), extras roundtrip"))
    }
  }

  # --- textarea (Zoo F): tokens encoded through the textarea's own host ----------------------------
  code <- options$codeF
  if (!is.null(code) && is.list(code)) {
    used <- unique(as.character(unlist(code$columns)))
    # the received model text itself (encoded at bind time through the host view; decoded again
    # on the way out - the verifier asserts it round-trips to the original plain text)
    if (is.character(code$model) && nzchar(code$model))
      rows <- addRow(rows, "textarea-host", "codeF(text)", code$model,
                     rowChild = "model as received (decoded on the way out)")
    for (token in used) {
      if (!nzchar(token)) next
      key  <- .resolveSlice(token, datasets)
      desc <- .describeValue(key, token, datasets)
      rows <- addRow(rows, "textarea-host", "codeF", token, rowChild = "detected column",
                     key = key, n = desc$n, values = desc$values)
    }
    model <- code$model
    if (is.character(model) && nzchar(model)) {
      # every column of every slice mentioned in the (encoded) model text resolves to that slice;
      # a token encoded through the WRONG namespace would not be found in the selected slice at all
      mentioned <- character()
      for (key in names(datasets))
        for (column in names(datasets[[key]]))
          if (grepl(column, model, fixed = TRUE)) mentioned <- c(mentioned, paste0(key, "|", column))
      if (length(mentioned) > 0)
        for (m in mentioned) {
          parts <- strsplit(m, "|", fixed = TRUE)[[1]]
          key <- parts[[1]]; column <- parts[[2]]
          desc <- .describeValue(key, column, datasets)
          rows <- addRow(rows, "textarea-host", "codeF(model)", column,
                         rowChild = "found in model text", key = key, n = desc$n, values = desc$values)
        }
      else
        rows <- addRow(rows, "textarea-host", "codeF(model)", "-",
                       rowChild = "no slice column mentioned in model text")
    }
  }

  # --- scalars (M5): plain values, no provenance anywhere ------------------------------------------
  rows <- addRow(rows, "scalar", "plainSwitch", as.character(isTRUE(options$plainSwitch)),
                 rowChild = "no provenance (C11 scalars unstamped)")
  rows <- addRow(rows, "combobox-plain", "comboG", as.character(options$comboG),
                 rowChild = "plain string (combos never term-objectified)")

  table$setData(rows)
}
