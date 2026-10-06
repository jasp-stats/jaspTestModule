#!/usr/bin/env Rscript
# Full headless test of the multi-dataset aware analysis (Test Multi-DataSet).
#
# Path 1 (engine-style, jaspTools::runAnalysis + datasets=): options carry encoded column
#   names with embedded dataset ids; jaspTools queues the slices exactly like the engine does.
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

datasets <- list(
  "11" = read.csv(file.path(moduledir, "Tools/testdata/DataSetA.csv")),
  "12" = read.csv(file.path(moduledir, "Tools/testdata/DataSetB.csv")))
attr(datasets, "dataSetNames") <- c("11" = "DataSetA", "12" = "DataSetB")

# ------------------------------------------------------------------ Path 1: jaspTools queue ----
cat("== Path 1: jaspTools::runAnalysis with queued slices (engine semantics) ==\n")
suppressMessages(library(jaspTools))
suppressMessages(jaspTools::setupJaspTools(
  pathJaspDesktop = normalizePath(file.path(moduledir, "..", "jasp-desktop")),
  installJaspModules = FALSE, installJaspCorePkgs = FALSE, quiet = TRUE, force = TRUE))
jaspTools::setPkgOption("module.dirs", moduledir)
jaspTools::setPkgOption("reinstall.modules", FALSE)

opts1 <- list(dependent = c("JASPColumn_11_0.scale", "JASPColumn_11_2.nominal",
                            "JASPColumn_12_0.scale", "JASPColumn_12_1.scale"),
              showMeta = FALSE, guardDemo = TRUE, plotWidth = 400, plotHeight = 300)
res1  <- jaspTools::runAnalysis("multiDataSetFunc", options = opts1, datasets = datasets, view = FALSE, quiet = TRUE)
r1    <- res1$results

check(identical(res1$status, "complete"), "run 1 completed")
check(length(r1$dataSetOverview$schema$fields) == 5L, "dataset overview has 5 columns (id/title/rows/cols/columnNames)")
check(length(r1$dataSetOverview$data) == 5L, "dataset overview data has exactly the 5 schema columns (no duplicate n/values)")

ovId    <- columnValues(r1$dataSetOverview, "id")
ovTitle <- columnValues(r1$dataSetOverview, "title")
check(identical(unname(ovId), c("11", "12")),                "overview ids 11,12")
check(identical(unname(ovTitle), c("DataSetA", "DataSetB")), "overview titles from dataSetNames attr")

sv       <- r1$selectedVariables
svVar    <- columnValues(sv, "variable")
svId     <- columnValues(sv, "dataSetId")
svName   <- columnValues(sv, "dataSetName")
svCol    <- columnValues(sv, "column")
svType   <- columnValues(sv, "type")
svN      <- columnValues(sv, "n")
# keyed by the row id so assertions do not depend on json row order
byRow <- function(v) v[svVar]
expected <- list(
  "JASPColumn_11_0.scale"   = c(id = "11", name = "DataSetA", column = "Score", type = "scale"),
  "JASPColumn_11_2.nominal" = c(id = "11", name = "DataSetA", column = "Group", type = "nominal"),
  "JASPColumn_12_0.scale"   = c(id = "12", name = "DataSetB", column = "Score", type = "scale"),
  "JASPColumn_12_1.scale"   = c(id = "12", name = "DataSetB", column = "Age",   type = "scale"))
check(all(names(expected) %in% svVar), "all four dependents present in the routing table")
for (v in names(expected)) if (v %in% svVar) {
  i <- which(svVar == v)[1]
  check(svId[i] == expected[[v]]["id"] && svName[i] == expected[[v]]["name"] &&
        svCol[i] == expected[[v]]["column"] && svType[i] == expected[[v]]["type"],
        paste0("routing ", v, " -> ", expected[[v]]["name"], "/", expected[[v]]["column"]))
}
check(all(svN == "10"), "all four columns read 10 rows")

raw1 <- jsonlite::toJSON(res1, auto_unbox = TRUE)
check(grepl("not available in multi-dataset aware analyses", raw1, fixed = TRUE),
      "guard demo: readDataSet() hard-stopped during the aware run")

# ------------------------------------------------------------------ Path 2: wrapper call -------
# The wrapper path is run in a clean Rscript subprocess (no jaspTools runtime in the way),
# which is exactly the RStudio/syntax-mode scenario the wrapper is made for.
cat("\n== Path 2: wrapper (datasets= named list, plain column names; clean subprocess) ==\n")
path2Script <- file.path(moduledir, "Tools", "testMultiDataSet_wrapper.R")
status2 <- system2("Rscript", c(shQuote(path2Script)), stdout = TRUE, stderr = FALSE)
writeLines(status2)
check(any(grepl("MULTIDATASET-WRAPPER-OK", status2, fixed = TRUE)), "wrapper subprocess succeeded")

# ------------------------------------------------------------------ Path 3: legacy still OK ----
cat("\n== Path 3: legacy non-aware run (no datasets) ==\n")
res3 <- jaspTools::runAnalysis("multiDataSetFunc", dataset = datasets[["11"]],
                               options = list(dependent = c("Score"), showMeta = FALSE,
                                              guardDemo = TRUE, plotWidth = 400, plotHeight = 300),
                               view = FALSE, quiet = TRUE)
raw3 <- jsonlite::toJSON(res3, auto_unbox = TRUE)
check(identical(res3$status, "complete"), "legacy run completed")
check(grepl("\\(current\\)", raw3),       "legacy run used the single-dataset path (no multi mode)")
check(!grepl("not available in multi-dataset", raw3, fixed = TRUE),
      "guard demo: readDataSet() works normally outside aware runs")

cat("\n")
if (failures > 0L) stop(failures, " multi-dataset test check(s) failed")
cat("All multi-dataset analysis tests passed\n")
