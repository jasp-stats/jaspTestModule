#!/usr/bin/env Rscript
# Wrapper-path check of the multi-dataset analysis: no jaspTools, no JASP - just
# jaspTestModule::multiDataSetFunc(datasets = <named list>, ...) like an R user would call it,
# with the dataset-selection options naming which dataset each variables-form uses.
# Run by Tools/testMultiDataSet.R, but standalone-runnable too.
#
# Flow under test: loadDataSets -> workspace (titles, ids, encoders) -> QML binds the selection
# options first (depends), switching each form; column options then encode per dataset and the
# bridge queues one slice per dataset; runJaspResults hands the analysis encoded options +
# encoded slices keyed by (bridge) dataset id, with the user names as titles.

moduledir <- normalizePath(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]])), ".."))
pkglib    <- Sys.getenv("JASP_TEST_PKGLIB", file.path(moduledir, "ModuleBundleBuildDir", "build_dir", "jaspTestModule"))
toollib   <- Sys.getenv("JASP_MODULE_TOOLLIB", normalizePath(file.path(moduledir, "..", ".toolLib")))
stopifnot(dir.exists(pkglib), dir.exists(toollib))
.libPaths(c(pkglib, toollib, .libPaths()))
Sys.setenv(QT_QPA_PLATFORM = "offscreen")

suppressMessages(library(jaspTestModule))

csvA <- read.csv(file.path(moduledir, "Tools/testdata/DataSetA.csv"))   # Score, Age, Group
csvB <- read.csv(file.path(moduledir, "Tools/testdata/DataSetB.csv"))   # Score, Age, Condition

res <- jaspTestModule::multiDataSetFunc(
        datasets = list(haha = csvA, godverdomme = csvB),
        dataSetA = "haha",
        dataSetB = "godverdomme",
        dependentA = "Score",                          # Score exists in both: form A picked haha
        dependentB = c("Age", "Condition"))            # Condition only in godverdomme
raw <- as.character(res$.__enclos_env__$private$getResults())
j   <- jsonlite::fromJSON(raw, simplifyVector = FALSE)$results

columnValues <- function(tb, fieldName) {
  idx <- which(vapply(tb$schema$fields, function(f) identical(f$name, fieldName), logical(1)))[1]
  d <- tb$data[[idx]]
  rowKeys <- names(d)[vapply(d, length, integer(1)) > 0L]
  stats::setNames(vapply(d[rowKeys], function(v) paste(as.character(v), collapse = ", "), character(1), USE.NAMES = FALSE), rowKeys)
}

ok <- TRUE
check <- function(cond, label) {
  cat(if (isTRUE(cond)) "PASS :" else "FAIL :", "wrapper -", label, "\n")
  if (!isTRUE(cond)) ok <<- FALSE
}

check(grepl("Aware run", raw, fixed = TRUE), "analysis ran in aware mode")

ovTitle <- unname(columnValues(j$dataSetOverview, "title"))
ovId    <- unname(columnValues(j$dataSetOverview, "id"))
ovNames <- unname(columnValues(j$dataSetOverview, "columnNames"))
check(setequal(ovTitle, c("haha", "godverdomme")), "both datasets handed over, user names as titles")
check(length(ovId) == 2L && all(grepl("^[0-9]+$", ovId)), "datasets keyed by (bridge) numeric dataset ids")
check(all(grepl("JASPColumn_", ovNames)), "slices arrive with encoded column names")

# the bridge dataset ids behind each title, so routing can be asserted exactly
idByTitle <- stats::setNames(ovId, ovTitle)

sv       <- j$selectedVariables
svSrc    <- columnValues(sv, "source")
svVar    <- columnValues(sv, "variable")
svId     <- columnValues(sv, "dataSetId")
svN      <- columnValues(sv, "n")
svValues <- columnValues(sv, "values")

check(all(grepl("^JASPColumn_[0-9]+_[0-9]+_Encoded$", svVar)),
      "option values arrive in the encoded namespace (not the plain user names)")

rowFor <- function(src, dsTitle) {
  which(svSrc == src & svId == idByTitle[[dsTitle]])
}

iA <- rowFor("A", "haha"); iB1 <- rowFor("B", "godverdomme")
check(length(iA) == 1L && length(iB1) == 2L, "three rows routed: A->haha once, B->godverdomme twice")
check(all(svN == "10"), "every column computed over 10 rows (encoded names indexed directly)")
check(grepl(sprintf("mean %.2f", mean(csvA$Score)), svValues[[iA]], fixed = TRUE),
      "form A Score = haha's Score (per-form dataset selection)")
# integer columns arrive from the syntax bridge as ordinal -> the demo shows first levels, not mean;
# the level list itself proves it is GODVERDOMME'S Age (31/45/28... would be haha's)
ageLevelsB <- paste(utils::head(unique(as.character(csvB$Age)), 5), collapse = ", ")
check(any(grepl(ageLevelsB, svValues[iB1], fixed = TRUE)),
      "form B Age = godverdomme's Age (identically named column, different dataset)")
check(any(grepl("X, Y, Z", svValues[iB1], fixed = TRUE)),
      "form B Condition found in godverdomme (only exists there)")

cat(if (ok) "MULTIDATASET-WRAPPER-OK\n" else "MULTIDATASET-WRAPPER-FAILED\n")
quit(status = if (ok) 0L else 1L)
