#!/usr/bin/env Rscript
# Full headless test of the multi-dataset aware analysis (Test Multi-DataSet).
#
# Path 1 (jaspTools::runAnalysis + datasets=, BRIDGE PARITY): plain column names and plain
#   dataframes - jaspTools now runs the real SyntaxInterface bridge (loadDataSets -> QML parse:
#   validation, per-form dataset selection, .meta stamping, per-dataset encoding, filter-keyed
#   slice queue) and decodes the results on the way out, exactly like the engine. What the test
#   asserts plain is what the author typed; the encoding roundtrip happens for real in between.
# Path 2 (wrapper, jaspTestModule::multiDataSetFunc(datasets=...)): plain names too, through
#   runWrappedAnalysis -> the same bridge preparation (subprocess, no jaspTools).
# Path 3 (legacy single-dataset run through jaspTools): plain in, plain out via the bridge's
#   encode -> decode roundtrip; no datasets argument so the analysis takes its old path.
#
# Run with:  Rscript Tools/testMultiDataSet.R   (after Tools/buildBundle.R at least once,
# which installs the patched jaspBase + this module into the build library)
#
# Override locations with JASP_TEST_PKGLIB / JASP_MODULE_TOOLLIB.

moduledir <- normalizePath(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]])), ".."))
pkglib    <- Sys.getenv("JASP_TEST_PKGLIB",  file.path(moduledir, "ModuleBundleBuildDir", "build_dir", "jaspTestModule"))
toollib   <- Sys.getenv("JASP_MODULE_TOOLLIB", normalizePath(file.path(moduledir, "..", ".toolLib")))

stopifnot(dir.exists(pkglib), dir.exists(toollib))
setwd(moduledir)
.libPaths(c(pkglib, toollib, .libPaths()))

Sys.setenv(QT_QPA_PLATFORM = "offscreen")

failures <- 0L
check <- function(ok, label) {
  cat(if (isTRUE(ok)) "PASS :" else "FAIL :", label, "\n")
  if (!isTRUE(ok)) failures <<- failures + 1L
}

# jaspTable json is transposed: data[[j]] holds one table column (schema.fields order), its cells
# keyed by per-row ids ("colN", NOT in insertion order). columnValues returns cells + their row
# keys so assertions can be order-independent.
columnValues <- function(tb, fieldName) {
  if (!is.list(tb) || is.null(tb$data)) return(character(0))
  # row-major (setData(data.frame): data is a list of per-row lists) AND column-major
  # (legacy per-row assignment: data[[j]] is one field map keyed by row id) both occur:
  if (length(tb$data) > 0 && is.list(tb$data[[1]])) {
    cells <- vapply(tb$data, function(row) as.character(row[[fieldName]] %||% NA_character_), character(1))
    return(stats::setNames(cells, paste0("row", seq_along(cells))))
  }
  j <- which(vapply(tb$schema$fields, function(f) identical(f$name, fieldName), logical(1)))[1]
  if (is.na(j) || length(tb$data) < j) return(character(0))
  d <- tb$data[[j]]
  rowKeys <- names(d)[vapply(d, length, integer(1)) > 0L]
  stats::setNames(vapply(d[rowKeys], function(v) as.character(v), character(1), USE.NAMES = FALSE), rowKeys)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

csvA <- read.csv(file.path(moduledir, "Tools/testdata/DataSetA.csv"))   # Score, Age, Group
csvB <- read.csv(file.path(moduledir, "Tools/testdata/DataSetB.csv"))   # Score, Age, Condition

# ------------------------------------------------------------------ Path 1: jaspTools bridge ----
cat("== Path 1: jaspTools::runAnalysis through the bridge (engine semantics, plain names) ==\n")
suppressMessages(library(jaspTools))
suppressMessages(jaspTools::setupJaspTools(
  pathJaspDesktop = normalizePath(file.path(moduledir, "..", "jasp-desktop")),
  installJaspModules = FALSE, installJaspCorePkgs = FALSE, quiet = TRUE, force = TRUE))
jaspTools::setPkgOption("module.dirs", moduledir)
jaspTools::setPkgOption("reinstall.modules", FALSE)

# exactly what a syntax-mode user writes: datasets named, each variables form says which
# dataset it draws from (dataSetA/dataSetB), columns by their plain header names.
opts1 <- list(dependentA = c("Score", "Group"),
              dependentB = c("Score", "Age"),
              dataSetA = "DataSetA", dataSetB = "DataSetB",
              showMeta = FALSE, guardDemo = TRUE, plotWidth = 400, plotHeight = 300)
res1  <- jaspTools::runAnalysis("multiDataSetFunc", options = opts1,
                                datasets = list(DataSetA = csvA, DataSetB = csvB),
                                view = FALSE, quiet = TRUE)
r1    <- res1$results

check(identical(res1$status, "complete"), "run 1 completed")
check(length(r1$dataSetOverview$schema$fields) == 5L, "dataset overview has 5 columns (id/title/rows/cols/columnNames)")

ovId    <- columnValues(r1$dataSetOverview, "id")
ovTitle <- columnValues(r1$dataSetOverview, "title")
ovCols  <- columnValues(r1$dataSetOverview, "cols")
check(length(ovId) == 2L && all(grepl("^[0-9]+$", unname(ovId))), "overview ids are real (bridge) dataset ids")
check(setequal(unname(ovTitle), c("DataSetA", "DataSetB")), "overview titles are the names from the datasets list")
# the queue hands slices trimmed to the columns the options reference (wanted-cols), exactly
# as the engine's prepareMultiDataSetRun does - not the full csv.
check(all(ovCols == "2"), "slices arrive trimmed to the referenced columns (engine wanted-cols)")

# the overview shows DECODED names: the analysis saw JASPColumn_* tokens, jaspTools decoded
# the whole results json on the way out (engine sendString equivalent).
ovNames <- columnValues(r1$dataSetOverview, "columnNames")
check(all(c("Group, Score", "Age, Score") %in% unname(ovNames)),
      "overview column names came back decoded (encode -> decode roundtrip is real)")

sv       <- r1$selectedVariables
svSrc    <- columnValues(sv, "source")
svVar    <- columnValues(sv, "variable")
svId     <- columnValues(sv, "dataSetId")
svName   <- columnValues(sv, "dataSetName")
svN      <- columnValues(sv, "n")
svValues <- columnValues(sv, "values")
check(all(unname(svVar) %in% c("Score", "Group", "Age", "Condition")), "routing table variables are plain names")

rowFor <- function(src, var, dsTitle) which(svSrc == src & svVar == var & svName == dsTitle)
iA   <- rowFor("A", "Score", "DataSetA")
iAg  <- rowFor("A", "Group", "DataSetA")
iB   <- rowFor("B", "Score", "DataSetB")
iBag <- rowFor("B", "Age",   "DataSetB")
check(length(iA) == 1L && length(iAg) == 1L && length(iB) == 1L && length(iBag) == 1L,
      "four rows routed by (form, variable, dataset) - per-form selection honoured")
check(length(c(iA, iAg, iB, iBag)) == 4L && all(svN[c(iA, iAg, iB, iBag)] == "10"), "every column computed over 10 rows")
check(length(iA) == 1L && grepl(sprintf("mean %.2f", mean(csvA$Score)), svValues[[iA]], fixed = TRUE),
      "form A Score = DataSetA's Score (mean matches csv)")
check(length(iB) == 1L && grepl(sprintf("mean %.2f", mean(csvB$Score)), svValues[[iB]], fixed = TRUE),
      "form B Score = DataSetB's Score (identically named column, no cross-slice mixup)")
check(any(grepl(paste(utils::head(unique(as.character(csvA$Group)), 5), collapse = ", "), svValues[iAg], fixed = TRUE)),
      "form A Group found in DataSetA")
check(any(grepl(paste(utils::head(unique(as.character(csvB$Age)), 5), collapse = ", "), svValues[iBag], fixed = TRUE)),
      "form B Age = DataSetB's Age (DataSetA's Age would show different levels)")
check(all(unname(svId) %in% unname(ovId)), "routing dataSetIds agree with the overview ids")

raw1 <- jsonlite::toJSON(res1, auto_unbox = TRUE)
check(!grepl("JASPColumn_", raw1), "no encoded tokens anywhere in the returned results (decoded on exit)")
check(grepl("not available in multi-dataset aware analyses", raw1, fixed = TRUE),
      "guard demo: readDataSet() hard-stopped during the aware run")

# ------------------------------------------------------------------ Bridge ids (Track C) ----
cat("\n== Bridge boundary: loadDataSets returns dataset ids; selections accept them ==\n")
# Titles stay the outer-surface sugar; INSIDE the wrapper everything keys on integer ids. The
# loaders hand back the real database ids so a syntax script can refer to datasets by the
# invariant instead of a title the user could rename mid-session.
ids <- jaspSyntax::loadDataSets(list(DataSetA = csvA, DataSetB = csvB))
check(is.integer(ids) && length(ids) == 2L && identical(names(ids), c("DataSetA", "DataSetB")) && all(ids > 0),
      "loadDataSets returns the named integer dataset ids")

qmlFile <- file.path(find.package("jaspTestModule"), "qml", "testMultiDataSet.qml")
parseSelection <- function(selA, selB) {
  opts <- list(dependentA = c("Score", "Group"), dependentB = c("Score", "Age"),
               dataSetA = selA, dataSetB = selB,
               showMeta = FALSE, guardDemo = FALSE, plotWidth = 400, plotHeight = 300)
  jaspSyntax::loadQmlAndParseOptionsStatus("jaspTestModule", "multiDataSetFunc", qmlFile,
      as.character(jsonlite::toJSON(opts, auto_unbox = TRUE, digits = NA, null = "null")), "1", TRUE)
}

stId <- tryCatch(parseSelection(as.integer(ids[[1]]), as.integer(ids[[2]])), error = function(e) e)
check(!inherits(stId, "error") && nzchar(stId$options), "integer DATASET-id selections parse through the bridge")
parsed <- jsonlite::fromJSON(stId$options, simplifyVector = FALSE)
keyA <- as.character(utils::tail(unlist(parsed$dataSetA), 1L))
keyB <- as.character(utils::tail(unlist(parsed$dataSetB), 1L))
msj  <- jsonlite::fromJSON(stId$multiDataSetJson)
check(all(c(keyA, keyB) %in% as.character(msj$ids)) && keyA != keyB,
      "id selections resolved to two distinct queued slice keys (filter-id key space)")
check(identical(as.character(msj$dataSetIds[[keyA]]), as.character(ids[[1]])),
      "the slice an id selected belongs to exactly that dataset")

errBadTitle <- tryCatch({ parseSelection("NoSuchDataSet", as.integer(ids[[2]])); "" }, error = function(e) conditionMessage(e))
check(grepl("neither the title nor the id", errBadTitle),
      "an unknown title is rejected loudly (error lists what is loaded)")
errBadId <- tryCatch({ parseSelection(999L, 998L); "" }, error = function(e) conditionMessage(e))
check(grepl("neither the title nor the id", errBadId),
      "an unknown integer is rejected too - no filter-id guessing (1 is not both a dataset and a filter)")

# ------------------------------------------------------------------ Path 2: wrapper call -------
# The wrapper path is run in a clean Rscript subprocess (no jaspTools runtime in the way):
cat("\n== Path 2: wrapper (datasets= named list + dataset selection options) ==\n")
path2Script <- file.path(moduledir, "Tools", "testMultiDataSet_wrapper.R")
status2 <- system2("Rscript", c(shQuote(path2Script)), stdout = TRUE, stderr = FALSE)
writeLines(status2)
check(any(grepl("MULTIDATASET-WRAPPER-OK", status2, fixed = TRUE)), "wrapper subprocess succeeded")

# ------------------------------------------------------------------ Path 3: legacy still OK ----
cat("\n== Path 3: legacy non-aware run (single dataset, plain names) ==\n")
# The aware analysis ALWAYS gets the bridge slice queue now (engine semantics: multiDataSetJson
# is produced whenever the Description says aware), so the legacy dataset/readDataSet path is
# exercised through the module's non-aware counterpart - its qml has no dataset selection.
res3 <- jaspTools::runAnalysis("multiDataSetNonAware", dataset = csvA,
                               options = list(dependentA = "Score", dependentB = "Age",
                                              showMeta = FALSE, guardDemo = TRUE,
                                              plotWidth = 400, plotHeight = 300),
                               view = FALSE, quiet = TRUE)
raw3 <- jsonlite::toJSON(res3, auto_unbox = TRUE)
check(identical(res3$status, "complete"), "legacy run completed")
check(grepl("\\(current\\)", raw3),       "legacy run used the single-dataset path (no multi mode)")
check(grepl(sprintf("mean %.2f", mean(csvA$Score)), raw3, fixed = TRUE),
      "legacy run computed DataSetA's Score mean through the bridge roundtrip")
check(!grepl("JASPColumn_", raw3), "legacy results decoded too")
check(!grepl("not available in multi-dataset", raw3, fixed = TRUE),
      "guard demo: readDataSet() works normally outside aware runs")

cat("\n")
if (failures > 0L) stop(failures, " multi-dataset test check(s) failed")
cat("All multi-dataset analysis tests passed\n")
