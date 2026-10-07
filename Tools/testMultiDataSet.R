#!/usr/bin/env Rscript
# Full headless test of the multi-dataset aware analysis (Test Multi-DataSet).
#
# Path 1 (engine-style, jaspTools::runAnalysis + datasets=): options carry encoded column
#   names and the slices are dataframes with THOSE SAME encoded column names - exactly what the
#   engine delivers (both sides encoded by each dataset's ColumnEncoder; see the bridge round-trip
#   in jasp-desktop Tests/R/test_multidataset_rlogic.R). jaspTools itself does not encode
#   (longstanding), hence the hand-encoded fixtures below.
# Path 2 (wrapper, jaspTestModule::multiDataSetFunc(datasets=...)): plain column names plus a
#   named list of datasets, runWrappedAnalysis -> runJaspResults with a direct R-side handout.
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
  j <- which(vapply(tb$schema$fields, function(f) identical(f$name, fieldName), logical(1)))[1]
  d <- tb$data[[j]]
  rowKeys <- names(d)[vapply(d, length, integer(1)) > 0L]
  stats::setNames(vapply(d[rowKeys], function(v) as.character(v), character(1), USE.NAMES = FALSE), rowKeys)
}

# Slices as the engine hands them over: the dataframe columns carry the encoded names
# (JASPColumn_<dataSetId>_<counter>_Encoded - DataSet::setupEncoderPrefix), NOT the csv headers.
encodeSlice <- function(df, dataSetId) {
  names(df) <- sprintf("JASPColumn_%d_%d_Encoded", dataSetId, seq_along(df) - 1L)
  df
}

csvA <- read.csv(file.path(moduledir, "Tools/testdata/DataSetA.csv"))   # Score, Age, Group
csvB <- read.csv(file.path(moduledir, "Tools/testdata/DataSetB.csv"))   # Score, Age, Condition

datasets <- list("11" = encodeSlice(csvA, 11), "12" = encodeSlice(csvB, 12))
attr(datasets, "dataSetNames") <- c("11" = "DataSetA", "12" = "DataSetB")

encA <- stats::setNames(sprintf("JASPColumn_11_%d_Encoded", seq_along(csvA) - 1L), names(csvA))  # Score, Age, Group
encB <- stats::setNames(sprintf("JASPColumn_12_%d_Encoded", seq_along(csvB) - 1L), names(csvB))  # Score, Age, Condition

# ------------------------------------------------------------------ Path 1: jaspTools queue ----
cat("== Path 1: jaspTools::runAnalysis with queued slices (engine semantics, encoded names) ==\n")
suppressMessages(library(jaspTools))
suppressMessages(jaspTools::setupJaspTools(
  pathJaspDesktop = normalizePath(file.path(moduledir, "..", "jasp-desktop")),
  installJaspModules = FALSE, installJaspCorePkgs = FALSE, quiet = TRUE, force = TRUE))
jaspTools::setPkgOption("module.dirs", moduledir)
jaspTools::setPkgOption("reinstall.modules", FALSE)

opts1 <- list(dependentA = c(encA[["Score"]], encA[["Group"]]),
              dependentB = c(encB[["Score"]], encB[["Age"]]),
              showMeta = FALSE, guardDemo = TRUE, plotWidth = 400, plotHeight = 300)
res1  <- jaspTools::runAnalysis("multiDataSetFunc", options = opts1, datasets = datasets, view = FALSE, quiet = TRUE)
r1    <- res1$results

check(identical(res1$status, "complete"), "run 1 completed")
check(length(r1$dataSetOverview$schema$fields) == 5L, "dataset overview has 5 columns (id/title/rows/cols/columnNames)")
check(length(r1$dataSetOverview$data) == 5L, "dataset overview data has exactly the 5 schema columns (no duplicate n/values)")

ovId    <- columnValues(r1$dataSetOverview, "id")
ovTitle <- columnValues(r1$dataSetOverview, "title")
ovCols  <- columnValues(r1$dataSetOverview, "cols")
check(identical(unname(ovId), c("11", "12")),                "overview ids 11,12")
check(identical(unname(ovTitle), c("DataSetA", "DataSetB")), "overview titles from dataSetNames attr")
check(all(ovCols == "3"), "both slices reported 3 columns")

# the overview shows the ENCODED names (headless run: no engine sendString decode in between)
ovNames <- columnValues(r1$dataSetOverview, "columnNames")
check(all(c(paste(encA, collapse = ", "), paste(encB, collapse = ", ")) %in% unname(ovNames)),
      "overview column names are the encoded names the analysis received")

sv       <- r1$selectedVariables
svSrc    <- columnValues(sv, "source")
svVar    <- columnValues(sv, "variable")
svId     <- columnValues(sv, "dataSetId")
svName   <- columnValues(sv, "dataSetName")
svN      <- columnValues(sv, "n")
svValues <- columnValues(sv, "values")
check(all(c(encA[["Score"]], encA[["Group"]], encB[["Score"]], encB[["Age"]]) %in% svVar),
      "all four encoded dependents present in the routing table")
for (v in c(encA[["Score"]], encA[["Group"]], encB[["Score"]], encB[["Age"]])) if (v %in% svVar) {
  i <- which(svVar == v)[1]
  expId <- if (v %in% encA) "11" else "12"
  expNm <- if (v %in% encA) "DataSetA" else "DataSetB"
  check(svId[i] == expId && svName[i] == expNm && svN[i] == "10" && nzchar(svValues[i]),
        paste0("routing ", v, " -> ", expNm, ", 10 rows, values computed (", svValues[i], ")"))
}

# numeric stats must correspond to the right slice: A/Score mean vs csv
iScoreA <- which(svVar == encA[["Score"]])[1]
check(grepl(sprintf("mean %.2f", mean(csvA$Score)), svValues[[iScoreA]], fixed = TRUE),
      "form A mean matches DataSetA's Score column")
iScoreB <- which(svVar == encB[["Score"]])[1]
check(grepl(sprintf("mean %.2f", mean(csvB$Score)), svValues[[iScoreB]], fixed = TRUE),
      "form B mean matches DataSetB's Score column (no cross-slice mixup)")

raw1 <- jsonlite::toJSON(res1, auto_unbox = TRUE)
check(grepl("not available in multi-dataset aware analyses", raw1, fixed = TRUE),
      "guard demo: readDataSet() hard-stopped during the aware run")

# ------------------------------------------------------------------ Path 2: wrapper call -------
# The syntax-mode wrapper flow (loadQmlAndParseOptions) still encodes option values against the
# bridge's single dataset view while the handed-over list keeps plain names: the dataset-selection
# design (TODO-multidataset.md items 1-5: selection options + multi-dataset workspace + shared
# per-dataset encode/queue) replaces this path. Tools/testMultiDataSet_wrapper.R stays ready to
# assert the new semantics once that lands.
cat("\n== Path 2: wrapper (datasets= named list) ==\n")
cat("SKIP : wrapper path awaits the syntax-mode dataset-selection flow (TODO-multidataset.md #1-#5)\n")

# ------------------------------------------------------------------ Path 3: legacy still OK ----
cat("\n== Path 3: legacy non-aware run (no datasets) ==\n")
res3 <- jaspTools::runAnalysis("multiDataSetFunc", dataset = datasets[["11"]],
                               options = list(dependentA = encA[c("Score")], dependentB = encA[c("Age")],
                                              showMeta = FALSE, guardDemo = TRUE, plotWidth = 400, plotHeight = 300),
                               view = FALSE, quiet = TRUE)
raw3 <- jsonlite::toJSON(res3, auto_unbox = TRUE)
check(identical(res3$status, "complete"), "legacy run completed")
check(grepl("\\(current\\)", raw3),       "legacy run used the single-dataset path (no multi mode)")
check(!grepl("not available in multi-dataset", raw3, fixed = TRUE),
      "guard demo: readDataSet() works normally outside aware runs")

cat("\n")
if (failures > 0L) stop(failures, " multi-dataset test check(s) failed")
cat("All multi-dataset analysis tests passed\n")
