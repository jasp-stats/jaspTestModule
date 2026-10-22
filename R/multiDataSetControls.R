# the component-zoo echo. Receives the generated options + the per-slice
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
#   components-rows      Zoo C - row-bearing variables list (the TableFields shape; shared
#                                 RowControls/TermRowKey machinery), sourced from a
#                                 default-provider pool (every assigned list has >= 1 source -
#                                 owner rule; the bare standalone list died with Zoo B):
#                                 per-row term + keep + shift; same-name twin rows from two
#                                 filters keep their OWN children (the D6.1 TermRowKey
#                                 re-keying); the pool's key is -1, so the stamped twins are
#                                 never swept by any reset
#   pool-hostless        Zoo M - the default-provider pool's companion (no host selection,
#                                 participation key -1): sent-BARE terms resolve through the
#                                 analysis-level fallback (the C13 use-time resolution),
#                                 sent-stamped terms keep their own stamp
#   pool-f3              Zoo M - the EXTRA SOURCE's companion: the pool hosted by the THIRD
#                                 filter of the same test dataset (f3-origin terms carry its
#                                 stamp; the anchor scenario's namespace)
#   derived-pool         Zoo N - the derived pool's companion: refs from assignedA +
#                                 assignedDefault (mixed provenance), each keeping its own stamp
#   interaction-list     Zoo D - combination terms: all components share the term filterId
#   factor-levels        Zoo E - encodeThis -> extras roundtrip (names never slice columns;
#                                 they must come back decoded, no raw JaspExtraOptions_ leakage)
#   textarea-host        Zoo F - R-code textarea: used columns encoded through its own host
#   bindto-cross-host    Zoo G - typed copy bound across differently-selected hosts: keeps the
#                                 SOURCE filterId, encodes through the SOURCE's view (D6.2)
#   dropdown-dependent   Zoo I - dependent dropdown: option LIST driven by assignedA's value; its
#                                 value encodes through the SOURCE's host namespace (a dropdown
#                                 with a source inherits the source's selection host)
#   pairs-list           Zoo J - AssignedPairsVariablesList: its 2 columns are PAIRED into
#                                 2-component terms (bound value [["Score","Age"]]); per-pair
#                                 resolution + correlation
#   factors-form         Zoo K - FactorsForm (the FactorsList family): per factor name/title +
#                                 terms. The form's inner panels are not hosts, but the per-factor
# sidecar (FactorsFormBase::createFilterIds) now
#                                 transports each term's OWN filterId per factor and per term: a
#                                 factor term carries the stamp of the host its source list synced
#                                 it from (here assignedK -> filter 1) and encodes through THAT
#                                 filter's view - resolved slice by slice, no analysis-level
#                                 fallback (the D3.2 hostless-panel deferral is CLOSED; pinned
#                                 here, not faked).
# REGRESSION PINNED C++-SIDE: a factor term whose
#                                 column the resolved namespace lacks (e.g. a NOMINAL Group term
#                                 while the shown dataset is DataSet 2) used to FATAL the whole
#                                 run - rbridge_readDataSetRequested refused "Group.nominal"
#                                 ("not a columnname at all") because the collector inserted
#                                 explicitly-typed terms without an existence check (pre-existing
#                                 gap, reachable only since the aware stamping). The collector now
#                                 refuses to queue columns the resolved namespace does not have
#                                 (Common/columnencoder.cpp); with the per-factor sidecar the term
#                                 resolves in its OWN namespace (where the column exists), so the
#                                 phantom-namespace route is gone entirely - the zoo pins the
#                                 resolved row + clean audit instead of the old honest unresolved
#                                 row.
#   tableview            Zoo L - bound TableView (row count driven by Zoo H's integer); cells
#                                 are plain values (no provenance - not a Terms option) and are
#                                 USED in the cross-slice computation, not just echoed
#   scalar               M5 contract - plain values, no provenance anywhere
#
# RESULTS INVENTORY (the point of the zoo: data and flows must be VISIBLE, "show the
# loaded data"):
#   dataSetOverview      one row per slice (unchanged)
#   dataPreview_<key>    THE LOADED DATA: per slice, every column's name AND first `rowsH` VALUES
#                        (head of data per slice) - proves the qualified-name -> decoded-token ->
#                        correct-slice chain end to end, visible in the results panel. Row count
#                        driven by Zoo H's integer field (rowsH).
#   controlsProvenance   per family: every received value, its row children, resolved slice
#   scalarEchoes         scalar families as received + WHERE each is used
#   optionFlows          the flow demonstrations: dependent dropdown's effective selection,
#                        checkbox gate state, row-count effect, radio statistic
#   crossSlice           computations ACROSS slices/lists of different provenance: interaction
#                        product, cross-host column product, pair correlation, tableL multipliers
#                        applied per slice, scale factor, radio-driven statistic
#   encodeDemo           the encodeThis/FactorLevelList transformation APPLIED: factor/level
#                        names from Zoo E used to recode an actual column
#   gatedResult          the checkbox-gated sub-result: created ONLY when gateH is on (a gated
#                        result must be absent, not an empty table)
#   metaDump             the PROVENANCE_AUDIT (unchanged)
#
# Where a family cannot produce a computation for a principled reason it says so in its row
# (sliderH: a bare fraction has no sensible slice computation - echo only; tableL cells: plain
# values by design) - documented, not faked.

multiDataSetControlsFuncInternal <- function(jaspResults, dataset, options, datasets = NULL) {
  aware <- !is.null(datasets)

  jaspResults[["explanation"]] <- createJaspHtml(paste0(
    if (aware)
      paste0("<b>Aware run.</b> Component zoo received ", length(datasets),
             " slice(s) as `datasets`; every family below echoes what it received, the loaded ",
             "data is shown per slice (first ", .intOption(options$rowsH, 5L), " rows) and the ",
             "option flows are demonstrated with real computations.")
    else
      "<b>Non-aware run.</b> No `datasets` argument: this analysis must run multiDataSetAware for the routing tables to mean anything.",
    "<br>See the check list at the top of Tools/verifyMultiDataSetRpc.py's zoo section for what each family proves."))

  dataSetOverviewTable(jaspResults, datasets, dataset)
  dataPreviewTables(jaspResults, datasets, options)
  controlsProvenanceTable(jaspResults, options, datasets)
  scalarEchoTable(jaspResults, options)
  flowsTable(jaspResults, options, datasets)
  crossSliceTable(jaspResults, options, datasets)
  encodeDemoTable(jaspResults, options, datasets)

  # the checkbox-gated sub-result: a GATE, so the object must not exist while closed
  if (isTRUE(options$gateH))
    gatedResultTable(jaspResults, options, datasets)

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

# scalar option readers: scalars are never provenanced (M5), so they arrive as plain values
.intOption <- function(x, default = NA_integer_) {
  if (is.null(x) || length(x) != 1 || is.na(x)) return(default)
  v <- suppressWarnings(as.integer(x))
  if (is.na(v)) default else v
}
.numOption <- function(x, default = NA_real_) {
  if (is.null(x) || length(x) != 1 || is.na(x)) return(default)
  v <- suppressWarnings(as.numeric(x))
  if (is.na(v)) default else v
}
.strOption <- function(x, default = "") {
  if (is.null(x) || length(x) != 1 || is.na(x)) return(default)
  x <- trimws(as.character(x))
  if (!nzchar(x) || identical(x, "0")) default else x   # '0' is the empty combobox sentinel
}

# the first scale column of a slice (for computations), with its provenance label
.firstScaleColumn <- function(datasets, keys = names(datasets)) {
  for (key in keys) {
    df <- datasets[[key]]
    for (cn in names(df)) {
      col <- df[[cn]]
      if (is.numeric(col) && sum(!is.na(col)) > 1)
        return(list(key = key, column = cn, values = as.numeric(col)))
    }
  }
  NULL
}

.statLabel <- function(stat, values) {
  if (is.null(values) || !length(values)) return("n/a")
  if (identical(stat, "sum")) sprintf("sum %.2f", sum(values, na.rm = TRUE))
  else sprintf("mean %.2f", mean(values, na.rm = TRUE))
}

# ------------------------------------------------------------------ THE LOADED DATA (a)
# One table per slice: every column's name (decoded via jaspBase::decodeName - the engine keeps
# the same deterministic strict table as the desktop) and its first `rowsH` VALUES - the whole
# qualified-name -> decoded-token -> correct-slice chain, visible. Field names are passed DECODED
# (a non-token passes through the strict table untouched), with a " (k)" suffix when one slice
# holds several type-variant tokens for the same column (e.g. the same column encoded once as
# scale and once as ordinal) so the schema never collides.
dataPreviewTables <- function(jaspResults, datasets, options) {
  if (is.null(datasets)) return(invisible())
  maxRows <- max(.intOption(options$rowsH, 5L), 1L)

  for (key in names(datasets)) {
    df <- datasets[[key]]
    meta <- .sliceMeta(key, datasets)
    table <- createJaspTable(paste0("Loaded data - ", meta$name, " (slice ", key, ", ",
                                    nrow(df), " rows), first ", min(maxRows, nrow(df)), " rows"))
    jaspResults[[paste0("dataPreview_", key)]] <- table

    table$addColumnInfo("row", title = "row #")
    seen <- character()
    fields <- character()
    for (cn in names(df)) {
      label <- tryCatch(jaspBase::decodeName(cn), error = function(e) cn)
      if (label %in% seen) label <- paste0(label, " (", sum(seen == label) + 1, ")")
      seen <- c(seen, label)
      fields[[cn]] <- label
      table$addColumnInfo(label, title = label)
    }

    n <- min(maxRows, nrow(df))
    rows <- data.frame(row = seq_len(n))
    for (cn in names(df)) {
      col <- df[[cn]]
      if (is.factor(col)) col <- as.character(col)
      rows[[fields[[cn]]]] <- utils::head(col, n)
    }
    table$setData(rows)
  }
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

  # --- plain term lists: Zoo A / Zoo G / Zoo K's source / Zoo M / Zoo N ---------------------------
  for (entry in list(
      list(fam = "assigned-list",       opt = "assignedA",         vals = .dependentValues(options$assignedA)),
      list(fam = "factors-source",      opt = "assignedK",         vals = .dependentValues(options$assignedK)),
      list(fam = "bindto-cross-host",   opt = "boundG",            vals = .dependentValues(options$boundG)),
      list(fam = "pool-hostless",       opt = "assignedDefault",   vals = .dependentValues(options$assignedDefault)),
      list(fam = "pool-f3",             opt = "assignedThree",     vals = .dependentValues(options$assignedThree)),
      list(fam = "derived-pool",        opt = "assignedDerived",   vals = .dependentValues(options$assignedDerived)))) {
    for (value in entry$vals) {
      key  <- .resolveSlice(value, datasets)
      desc <- .describeValue(key, value, datasets)
      rows <- addRow(rows, entry$fam, entry$opt, value, key = key, n = desc$n, values = desc$values)
    }
  }

  # --- dependent dropdown (Zoo I): plain string value whose OPTION LIST is driven by assignedA ----
  comboI <- .strOption(options$comboI, default = "")
  if (nzchar(comboI)) {
    key  <- .resolveSlice(comboI, datasets)
    desc <- .describeValue(key, comboI, datasets)
    rows <- addRow(rows, "dropdown-dependent", "comboI", comboI, key = key, n = desc$n, values = desc$values)
  }

  # --- paired list (Zoo J): AssignedPairsVariablesList pairs its 2 columns into 2-component
  # terms (bound value [["Score","Age"]]) - one row per PAIR, both components resolved, and a
  # real computation per pair (correlation of the two paired columns in their shared slice).
  pairsJ <- options$pairsJ
  if (!is.null(pairsJ) && is.list(pairsJ)) {
    pairRows <- if (!is.null(pairsJ$value)) pairsJ$value else pairsJ
    pairIdx <- 0
    for (row in pairRows) {
      comps <- as.character(unlist(row))
      if (length(comps) == 0) next
      pairIdx <- pairIdx + 1
      keys  <- vapply(comps, function(c) { k <- .resolveSlice(c, datasets); if (is.null(k)) "-" else k }, character(1))
      joint <- if (length(unique(keys)) == 1 && keys[[1]] != "-") keys[[1]] else NULL
      child <- paste0("pair ", pairIdx, ": ",
                      paste(comps, "(", keys, ")", sep = "", collapse = " + "))
      corTxt <- ""
      if (!is.null(joint) && length(comps) == 2) {
        c1 <- datasets[[joint]][[comps[[1]]]]; c2 <- datasets[[joint]][[comps[[2]]]]
        if (is.numeric(c1) && is.numeric(c2) && sum(complete.cases(c1, c2)) > 2)
          corTxt <- sprintf("r = %.3f", stats::cor(c1, c2, use = "complete.obs"))
      }
      rows <- addRow(rows, "pairs-list", "pairsJ", paste(comps, collapse = " + "),
                     rowChild = child, key = joint, values = if (nzchar(corTxt)) corTxt else
                       paste0("slices: ", paste(unique(keys), collapse = "/")))
    }
  }

  # --- factors form (Zoo K): per factor name + title + its terms' slices ---------------------------
  factorsK <- options$factorsK
  if (!is.null(factorsK) && is.list(factorsK)) {
    for (f in factorsK) {
      if (!is.list(f) || is.null(f$name)) next
      vars  <- as.character(unlist(f$variables %||% f$indicators %||% f$components %||% list()))
      keys  <- vapply(vars, function(v) { k <- .resolveSlice(v, datasets); if (is.null(k)) "-" else k }, character(1))
      child <- paste0("title=", if (is.null(f$title)) "-" else f$title,
                      "; vars: ", if (length(vars)) paste(vars, "(", keys, ")", sep = "", collapse = ", ") else "(none)")
      rows <- addRow(rows, "factors-form", "factorsK", f$name, rowChild = child,
                     key = if (length(unique(keys)) == 1 && keys[[1]] != "-") keys[[1]] else NULL,
                     values = if (length(vars))
                       paste0(length(vars), " var(s), slices: ", paste(unique(keys), collapse = "/"))
                     else "empty factor")
    }
  }

  # --- bound table view (Zoo L): plain cells (not a Terms option - no provenance by design) --------
  tableL <- .tableViewOption(options$tableL)
  if (!is.null(tableL)) {
    rows <- addRow(rows, "tableview", "tableL",
                   paste0(nrow(tableL$values), " rows x ", ncol(tableL$values), " cols"),
                   rowChild = paste0("cells: ", paste(utils::head(as.character(tableL$values), 6), collapse = ", "),
                                     if (nrow(tableL$values) * ncol(tableL$values) > 6) ", ..." else ""),
                   values = "plain cells (no provenance: a tableview option is not a Terms option)")
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

# ------------------------------------------------------------------ scalar echoes (b)
# Every scalar family AS RECEIVED plus where it is USED - the "echo" half of the scalar contract;
# the "use" half lives in the flow/cross-slice tables.
scalarEchoTable <- function(jaspResults, options) {
  table <- createJaspTable("Scalar & simple control echoes")
  jaspResults[["scalarEchoes"]] <- table

  table$addColumnInfo("option",   title = "Option")
  table$addColumnInfo("family",   title = "Family")
  table$addColumnInfo("received", title = "Received value (as received)")
  table$addColumnInfo("usedIn",   title = "Used in")

  gated <- if (isTRUE(options$gateH)) "gate OPEN" else "gate closed (received, but control disabled in the form)"

  rows <- data.frame(
    option   = c("textH",   "rowsH",    "doubleH",  "sliderH",           "radioH",  "gateH",             "gatedH"),
    family   = c("text (BoundControlTextBox)", "integer (BoundControlNumberField)",
                 "real (BoundControlNumberField)", "slider", "radio (RadioButtonGroup)",
                 "checkbox (BoundControlCheckBox)", "real, checkbox-gated"),
    received = c(.strOption(options$textH), as.character(.intOption(options$rowsH)),
                 as.character(.numOption(options$doubleH)), as.character(.numOption(options$sliderH)),
                 as.character(.strOption(options$radioH)), as.character(isTRUE(options$gateH)),
                 paste0(as.character(.numOption(options$gatedH)), " (", gated, ")")),
    usedIn   = c("echoed verbatim (no computation has a use for free text)",
                 "data-preview row count + Zoo L row count",
                 "cross-slice scale factor",
                 "echo only by design: a bare fraction has no sensible slice computation (documented, not faked)",
                 "flow statistic (cross-slice table)",
                 "gates the gated sub-result",
                 "gated sub-result threshold"),
    stringsAsFactors = FALSE)

  table$setData(rows)
}

# ------------------------------------------------------------------ flow demonstrations (c)
flowsTable <- function(jaspResults, options, datasets) {
  table <- createJaspTable("Option flows")
  jaspResults[["optionFlows"]] <- table

  table$addColumnInfo("flow",     title = "Flow")
  table$addColumnInfo("trigger",  title = "Trigger (control)")
  table$addColumnInfo("effect",   title = "Effect")
  table$addColumnInfo("observed", title = "Observed in this run")

  # 1. dependent dropdown: assignedA's content drives comboI's option list
  assignedA <- .dependentValues(options$assignedA)
  comboI    <- .strOption(options$comboI, "")
  comboIKey <- .resolveSlice(comboI, datasets)
  rows <- data.frame(
    flow    = "dependent dropdown",
    trigger = "assignedA (Zoo A's list)",
    effect  = "comboI's option list = assignedA's terms; its effective selection follows",
    observed = paste0("source list: [", paste(assignedA, collapse = ", "), "]; selection: ",
                      if (nzchar(comboI)) paste0("\"", comboI, "\" -> slice ",
                                                 if (is.null(comboIKey)) "?" else comboIKey) else "(empty)"),
    stringsAsFactors = FALSE)

  # 2. checkbox gate: gateH toggles the existence of the gated sub-result
  rows <- rbind(rows, data.frame(
    flow    = "checkbox gate",
    trigger = "gateH (Zoo H checkbox)",
    effect  = "gated sub-result exists only while the gate is open; gatedH is its threshold",
    observed = paste0("gate ",
                      if (isTRUE(options$gateH))
                        paste0("OPEN -> 'Gated sub-result' table produced (threshold ", .numOption(options$gatedH), ")")
                      else
                        "closed -> no gated sub-result"),
    stringsAsFactors = FALSE))

  # 3. number field: rowsH controls the shown row count (previews + Zoo L)
  tableL <- .tableViewOption(options$tableL)
  previewRows <- if (is.null(datasets)) 0 else
    min(.intOption(options$rowsH, 5L), min(vapply(datasets, nrow, integer(1))))
  rows <- rbind(rows, data.frame(
    flow    = "number field -> shown rows",
    trigger = "rowsH (Zoo H integer)",
    effect  = "row count of every 'Loaded data' preview and of the Zoo L table view",
    observed = paste0("rowsH=", .intOption(options$rowsH), "; previews show ", previewRows,
                      " rows; tableL has ",
                      if (is.null(tableL)) "?" else nrow(tableL$values), " rows"),
    stringsAsFactors = FALSE))

  # 4. radio: picks the statistic used by the cross-slice computation
  statCol <- .columnByToken(.strOption(options$comboA, ""), datasets)
  rows <- rbind(rows, data.frame(
    flow    = "radio -> statistic",
    trigger = "radioH (Zoo H radio group)",
    effect  = "the 'radio-driven statistic' row of the cross-slice table switches mean/sum",
    observed = .statLabel(.strOption(options$radioH, "mean"),
                          if (is.null(statCol)) NULL else statCol$values),
    stringsAsFactors = FALSE))

  # 5. variables list -> interaction terms: the terms (and their computation) follow the list
  inter <- options$interactionD
  nTerms <- 0L
  if (!is.null(inter) && is.list(inter)) {
    interRows <- if (!is.null(inter$value)) inter$value else inter
    nTerms <- length(interRows)
  }
  rows <- rbind(rows, data.frame(
    flow    = "variables list -> interaction terms",
    trigger = "interactionD (Zoo D list)",
    effect  = "the 'interaction product' rows of the cross-slice table follow the list's terms",
    observed = paste0(nTerms, " term(s) received"),
    stringsAsFactors = FALSE))

  table$setData(rows)
}

# ------------------------------------------------------------------ cross-slice computations (c)
# The results-side point of provenance: computations that COMBINE values of different slices /
# lists, each row carrying its inputs' provenance as dataset titles + slice keys (never tokens).
crossSliceTable <- function(jaspResults, options, datasets) {
  table <- createJaspTable("Cross-slice computations")
  jaspResults[["crossSlice"]] <- table

  table$addColumnInfo("computation", title = "Computation")
  table$addColumnInfo("inputs",      title = "Inputs (with provenance)")
  table$addColumnInfo("value",       title = "Value")

  rows <- data.frame(computation = character(), inputs = character(), value = character(),
                     stringsAsFactors = FALSE)
  addRow2 <- function(computation, inputs, value) {
    rbind(rows, data.frame(computation = computation, inputs = inputs, value = as.character(value),
                           stringsAsFactors = FALSE))
  }

  label <- function(key) {
    if (is.null(key)) return("?")
    meta <- .sliceMeta(key, datasets)
    paste0(meta$name, " (slice ", key, ")")
  }

  # 1. interaction terms (Zoo D): product of the components within their shared slice
  inter <- options$interactionD
  if (!is.null(inter) && is.list(inter)) {
    interRows <- if (!is.null(inter$value)) inter$value else inter
    for (row in interRows) {
      comps <- as.character(unlist(row$components %||% list()))
      if (length(comps) < 2) next
      keys <- unique(vapply(comps, function(c) { k <- .resolveSlice(c, datasets)
                                            if (is.null(k)) "-" else k }, character(1)))
      joint <- if (length(keys) == 1 && keys[[1]] != "-") keys[[1]] else NULL
      value <- ""
      if (!is.null(joint)) {
        cols <- lapply(comps, function(c) .columnByToken(c, datasets, joint))
        if (all(vapply(cols, function(x) !is.null(x) && is.numeric(x$values), logical(1))) &&
            length(unique(vapply(cols, function(x) length(x$values), integer(1)))) == 1) {
          prod <- Reduce(`*`, lapply(cols, function(x) x$values))
          value <- sprintf("mean of product %.3f (n=%d)", mean(prod, na.rm = TRUE), sum(!is.na(prod)))
        } else value <- "components not numeric / unequal lengths"
      } else value <- paste("components span slices:", paste(keys, collapse = "/"))
      rows <- addRow2("interaction product",
                      paste0(paste(comps, collapse = " : "), " in ", label(joint)), value)
    }
  }

  # 2. cross-host column product: assignedA's first scale column x assignedDefault's first scale
  #    column (the default-provider list - a bare -1 reference resolves through the analysis
  #    fallback, so the product joins a stamped slice with the fallback slice)
  colA <- .firstAssignedScale(options$assignedA, datasets)
  colB <- .firstAssignedScale(options$assignedDefault, datasets)
  if (!is.null(colA) && !is.null(colB)) {
    value <- if (length(colA$values) != length(colB$values))
      paste0("row lengths differ (", length(colA$values), " vs ", length(colB$values),
             "): no join semantics - whole-column aggregates only")
    else sprintf("mean of product %.3f", mean(colA$values * colB$values, na.rm = TRUE))
    rows <- addRow2("cross-host column product",
                    paste0(colA$column, " of ", label(colA$key), " x ", colB$column, " of ", label(colB$key)),
                    value)
  }

  # 3. tableL multipliers (Zoo L) applied to every slice's first scale column
  tableL <- .tableViewOption(options$tableL)
  if (!is.null(tableL) && ncol(tableL$values) >= 1) {
    mult <- mean(tableL$values[, 1], na.rm = TRUE)
    scaleCol <- .firstScaleColumn(datasets)
    if (!is.null(scaleCol) && is.finite(mult))
      rows <- addRow2("tableview multipliers",
                      paste0("mean(multiplier)=", sprintf("%.2f", mult), " x ", scaleCol$column,
                             " of ", label(scaleCol$key)),
                      sprintf("scaled mean %.3f", mult * mean(scaleCol$values, na.rm = TRUE)))
  }

  # 4. scale factor (Zoo H real field)
  scaleCol <- .firstScaleColumn(datasets)
  doubleH <- .numOption(options$doubleH)
  if (!is.null(scaleCol) && is.finite(doubleH))
    rows <- addRow2("real-field scaling",
                    paste0("doubleH=", doubleH, " x ", scaleCol$column, " of ", label(scaleCol$key)),
                    sprintf("scaled mean %.3f", doubleH * mean(scaleCol$values, na.rm = TRUE)))

  # 5. radio-driven statistic (Zoo H radio group) on the comboA column
  statCol <- .columnByToken(.strOption(options$comboA, ""), datasets)
  if (!is.null(statCol) && is.numeric(statCol$values))
    rows <- addRow2("radio-driven statistic",
                    paste0(.strOption(options$radioH, "mean"), " of ", statCol$column, " of ", label(statCol$key)),
                    .statLabel(.strOption(options$radioH, "mean"), statCol$values))

  if (nrow(rows) == 0)
    rows <- addRow2("(no computation)", "(nothing assigned yet)",
                    "assign columns/lists to see cross-slice computations here")

  table$setData(rows)
}

# ------------------------------------------------------------------ encodeThis applied (c)
# Zoo E's factor/level names (extras roundtrip) APPLIED to a real column: the recode proves the
# names came back decoded AND usable. The factor name arrives extras-encoded (JaspExtraOptions_*,
# decoded on the way out); to USE it R-side it is decoded through the same strict table
# (jaspBase::decodeName) - the sanctioned helper, not a re-implementation of the token grammar.
encodeDemoTable <- function(jaspResults, options, datasets) {
  table <- createJaspTable("encodeThis recode demo (Zoo E levels applied)")
  jaspResults[["encodeDemo"]] <- table

  table$addColumnInfo("factor",  title = "Factor (decoded)")
  table$addColumnInfo("slice",   title = "Column found in slice")
  table$addColumnInfo("oldValue", title = "Original value")
  table$addColumnInfo("newLabel", title = "Recoded to level")
  table$addColumnInfo("n",       title = "n")

  rows <- data.frame(factor = character(), slice = character(), oldValue = character(),
                     newLabel = character(), n = integer(), stringsAsFactors = FALSE)

  .decodeNameSafe <- function(x) tryCatch(jaspBase::decodeName(x), error = function(e) x)

  factors <- options$factorsE
  if (!is.null(factors) && is.list(factors))
    for (f in factors) {
      if (!is.list(f) || is.null(f$name)) next
      fname  <- .decodeNameSafe(as.character(f$name))
      levels <- as.character(unlist(f$levels %||% list()))
      levels <- if (length(levels)) vapply(levels, .decodeNameSafe, character(1)) else levels
      # The slice data.frames carry ENCODED column tokens (that is what R receives, C1) - the
      # decoded factor name must be matched against the DECODED column names, not the raw
      # colnames (the verifier caught the first version matching "Group" against tokens).
      hitKey <- NULL; hitTok <- NULL
      for (k in names(datasets)) {
        toks <- names(datasets[[k]])
        dec  <- vapply(toks, function(t) .decodeNameSafe(t), character(1))
        i    <- match(fname, dec)
        if (!is.na(i)) { hitKey <- k; hitTok <- toks[[i]]; break }
      }
      if (is.null(hitKey)) {
        rows <- rbind(rows, data.frame(factor = fname, slice = "(no column of this name in any slice)",
                                       oldValue = "-", newLabel = "-", n = NA_integer_,
                                       stringsAsFactors = FALSE))
        next
      }
      values <- as.character(stats::na.omit(datasets[[hitKey]][[hitTok]]))
      uniq   <- unique(values)
      recode <- if (length(levels)) levels[pmin(match(values, uniq), length(levels))] else values
      for (u in uniq) {
        n <- sum(values == u)
        rows <- rbind(rows, data.frame(factor = fname, slice = hitKey, oldValue = u,
                                       newLabel = recode[match(u, values)][1], n = n,
                                       stringsAsFactors = FALSE))
      }
    }

  if (nrow(rows) == 0)
    rows <- data.frame(factor = "(no factors)", slice = "-", oldValue = "-", newLabel = "-",
                       n = NA_integer_, stringsAsFactors = FALSE)

  table$setData(rows)
}

# ------------------------------------------------------------------ checkbox-gated sub-result (c)
# Exists ONLY while gateH is open - a gate means absence, not an empty table.
gatedResultTable <- function(jaspResults, options, datasets) {
  threshold <- .numOption(options$gatedH, 0)
  # dependencies = "gateH": the gate family's destruction semantics. jaspBase destroys an object
  # whose dependencies changed before the next run, so flipping gateH off removes the table and
  # the gate being closed means this child is ABSENT - not an empty table. (Without deps the
  # object from the previous run persists forever, which the verifier caught.)
  table <- createJaspTable(paste0("Gated sub-result (threshold ", threshold, ")"), dependencies = "gateH")
  jaspResults[["gatedResult"]] <- table

  table$addColumnInfo("slice",   title = "Slice")
  table$addColumnInfo("column",  title = "First scale column")
  table$addColumnInfo("nAbove",  title = "n above threshold")
  table$addColumnInfo("meanAbove", title = "mean above threshold")

  rows <- data.frame(slice = character(), column = character(), nAbove = integer(),
                     meanAbove = numeric(), stringsAsFactors = FALSE)
  if (!is.null(datasets))
    for (key in names(datasets)) {
      col <- .firstScaleColumn(datasets, key)
      if (is.null(col)) next
      above <- col$values[col$values > threshold & !is.na(col$values)]
      rows <- rbind(rows, data.frame(
        slice = paste0(key, " (", .sliceMeta(key, datasets)$name, ")"), column = col$column,
        nAbove = length(above),
        meanAbove = if (length(above)) mean(above) else NA_real_,
        stringsAsFactors = FALSE))
    }

  table$setData(rows)
}

# ------------------------------------------------------------------ more internals

# a bound tableview option as R receives it: list of columns {name, levels, values} -> matrix
.tableViewOption <- function(tv) {
  if (is.null(tv) || !is.list(tv) || !length(tv)) return(NULL)
  vals <- lapply(tv, function(col) {
    v <- if (is.list(col)) col$values else col
    suppressWarnings(as.numeric(unlist(v)))
  })
  lens  <- vapply(vals, length, integer(1))
  len   <- max(lens)
  if (is.null(len) || is.na(len) || len == 0) return(NULL)
  vals  <- lapply(vals, function(v) { length(v) <- len; v })
  m <- matrix(unlist(vals), nrow = len, ncol = length(vals))
  list(values = m,
       colNames = vapply(tv, function(c) if (is.list(c) && !is.null(c$name)) as.character(c$name) else "-",
                         character(1)))
}

# a column by its (encoded) token, optionally within one slice, with its provenance
.columnByToken <- function(token, datasets, key = NULL) {
  if (!nzchar(token) || is.null(datasets)) return(NULL)
  key <- if (is.null(key)) .resolveSlice(token, datasets) else key
  if (is.null(key)) return(NULL)
  col <- datasets[[key]][[token]]
  if (is.null(col)) return(NULL)
  list(key = key, column = token, values = if (is.factor(col)) as.numeric(col) else col)
}

# the first numeric column of an assigned list, with its slice provenance
.firstAssignedScale <- function(option, datasets) {
  for (token in .dependentValues(option)) {
    col <- .columnByToken(token, datasets)
    if (!is.null(col) && is.numeric(col$values) && sum(!is.na(col$values)) > 1)
      return(col)
  }
  NULL
}
