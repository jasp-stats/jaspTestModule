#!/usr/bin/env Rscript
# Wrapper-path check of the multi-dataset analysis: no jaspTools, no JASP - just
# jaspTestModule::multiDataSetFunc(datasets = <named list>, ...) like an R user would call it.
# Run by Tools/testMultiDataSet.R, but standalone-runnable too.

moduledir <- normalizePath(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]])), ".."))
pkglib    <- Sys.getenv("JASP_TEST_PKGLIB", file.path(moduledir, "ModuleBundleBuildDir", "build_dir", "jaspTestModule"))
toollib   <- Sys.getenv("JASP_MODULE_TOOLLIB", normalizePath(file.path(moduledir, "..", ".toolLib")))
stopifnot(dir.exists(pkglib), dir.exists(toollib))
.libPaths(c(pkglib, toollib, .libPaths()))
Sys.setenv(QT_QPA_PLATFORM = "offscreen")

suppressMessages(library(jaspTestModule))

datasets <- list(
  "11" = read.csv(file.path(moduledir, "Tools/testdata/DataSetA.csv")),
  "12" = read.csv(file.path(moduledir, "Tools/testdata/DataSetB.csv")))
attr(datasets, "dataSetNames") <- c("11" = "DataSetA", "12" = "DataSetB")

res <- jaspTestModule::multiDataSetFunc(datasets = datasets,
                                        dependentA = "Score",                    # in both datasets -> routes to the primary
                                        dependentB = c("Age", "Condition"))     # Condition only exists in DataSetB
raw <- as.character(res$.__enclos_env__$private$getResults())
j   <- jsonlite::fromJSON(raw, simplifyVector = FALSE)$results

# jaspTable json is transposed: data[[j]] = column j (schema order), cells keyed by row id
columnValues <- function(tb, fieldName) {
  idx <- which(vapply(tb$schema$fields, function(f) identical(f$name, fieldName), logical(1)))[1]
  d <- tb$data[[idx]]
  rowKeys <- names(d)[vapply(d, length, integer(1)) > 0L]
  vapply(d[rowKeys], function(v) as.character(v), character(1), USE.NAMES = FALSE)
}

ok <- TRUE
check <- function(cond, label) {
  cat(if (isTRUE(cond)) "PASS :" else "FAIL :", "wrapper -", label, "\n")
  if (!isTRUE(cond)) ok <<- FALSE
}

check(grepl("Aware run", raw, fixed = TRUE), "analysis ran in aware mode (datasets= arrived)")
check(identical(columnValues(j$dataSetOverview, "id"), c("11", "12")), "wrapper overview lists both dataset ids")
check(identical(columnValues(j$dataSetOverview, "title"), c("DataSetA", "DataSetB")), "wrapper overview lists both titles")

sv        <- j$selectedVariables
svCol     <- columnValues(sv, "column")
svN       <- columnValues(sv, "n")
svValues  <- columnValues(sv, "values")
check(any(svCol == "Score") && any(svCol == "Condition"), "Score and Condition resolved to original column names")
check(all(svN == "10"), "both columns computed over 10 rows (scan-all found Condition in DataSetB)")
check(any(grepl("mean", svValues, fixed = TRUE)), "numeric stats computed for Score")

cat(if (ok) "MULTIDATASET-WRAPPER-OK\n" else "MULTIDATASET-WRAPPER-FAILED\n")
quit(status = if (ok) 0L else 1L)
