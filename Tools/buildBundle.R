#!/usr/bin/env Rscript
# Build an installable .JASPModule bundle of jaspTestModule from this checkout.
#
# The jaspBase record in renv.lock is temporarily swapped for a Local record pointing at the
# jasp-desktop checkout (default: ../jasp-desktop/Engine/jaspBase), so whatever is checked out
# there (e.g. branch multiDataSetAware) is compiled and packed into the bundle. Everything is
# built from source into a private renv library under ModuleBundleBuildDir/ - no JASP cellar
# involved, so it works on a rolling-release system (Arch) with the R you have.
#
# Requires the tool library (jaspModuleTools + jaspModuleBundleManager + renv etc.), by default
# ../.toolLib; see the bottom of this file for how it was created.
#
# Usage (from the jaspTestModule directory, or anywhere):
#   Rscript Tools/buildBundle.R                      # bundle with local jaspBase
#   Rscript Tools/buildBundle.R --update-lockfile    # re-resolve renv.lock first (network)
#   Rscript Tools/buildBundle.R --remote-jaspbase    # use the jaspBase from renv.lock (GitHub)
#   Rscript Tools/buildBundle.R --jasp-version=development
#
# Result: bundles_out/jaspTestModule.JASPModule (+ manifest json), installable via
# JASP: + (add modules) menu -> Add module -> From file.
#
# One-time tool library setup:
#   toolLib=/path/to/.toolLib; mkdir -p $toolLib
#   Rscript -e '.libPaths(c(toolLib, .libPaths()))
#     install.packages(c("renv","fs","pkgdepends","usethis","withr","curl","rjson","stringr",
#                        "archive","openssl","jsonlite","remotes"), lib=toolLib,
#                      repos="https://cloud.r-project.org")
#     remotes::install_local("<jasp-desktop>/Engine/jaspModuleBundleManager", lib=toolLib,
#                            upgrade="never", dependencies=FALSE)
#     remotes::install_local("<jaspModuleTools checkout>", lib=toolLib,
#                            upgrade="never", dependencies=FALSE)'

args <- commandArgs(trailingOnly = TRUE)

scriptPath  <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]))
moduledir   <- normalizePath(file.path(dirname(scriptPath), ".."))
rootdir     <- normalizePath(file.path(moduledir, ".."))

jaspBaseDir <- Sys.getenv("JASP_BASE_DIR",   file.path(rootdir, "jasp-desktop", "Engine", "jaspBase"))
toolLib     <- Sys.getenv("JASP_MODULE_TOOLLIB", file.path(rootdir, ".toolLib"))
workdir     <- file.path(moduledir, "ModuleBundleBuildDir")
resultdir   <- file.path(moduledir, "bundles_out")

localJaspBase  <- !("--remote-jaspbase" %in% args)
updateLockfile <- "--update-lockfile" %in% args

jaspVersion <- "development"
for (a in args) if (grepl("^--jasp-version=", a)) jaspVersion <- sub("^--jasp-version=", "", a)

if (!dir.exists(toolLib))
	stop("Tool library not found at ", toolLib, " - see the setup instructions at the bottom of this script.")

.libPaths(c(toolLib, .libPaths()))
suppressPackageStartupMessages({ library(jsonlite) })
library(jaspModuleTools)

# No renv sandbox: binary R distributions (Arch!) have no R sources to link it against.
Sys.setenv(RENV_CONFIG_SANDBOX_ENABLED = "false")
options(jaspRemoteCellarRedownload = FALSE)

lockPath <- file.path(moduledir, "renv.lock")
lockBackup <- NULL

restoreLock <- function() {
  if (!is.null(lockBackup)) {
    writeLines(lockBackup, lockPath)
    lockBackup <<- NULL
    message("restored original ", lockPath)
  }
}

if (updateLockfile) {
  message("re-resolving ", lockPath, " with pkgdepends ...")
  jaspModuleTools::updateLockfile(moduledir)
  lockBackup <- readLines(lockPath)   # keep the freshly resolved one; never lose it
}

dir.create(workdir, recursive = TRUE, showWarnings = FALSE)

# Binary R distributions (Arch!) have no R sources, so renv's sandbox can't be built - but
# jaspModuleTools copies packages that renv::restore skips because they live in the system
# library (recommended ones like codetools) out of it. Fake it: the sandbox is nothing but a
# symlink farm over the system library, so build exactly that at the path renv resolves
# (RENV_PATHS_SANDBOX plus its linux-arch-rolling/R-4.6/<hash> suffix).
Sys.setenv(RENV_PATHS_SANDBOX = file.path(workdir, "sandbox"))
fakeSandbox <- renv:::renv_paths_sandbox()
dir.create(fakeSandbox, recursive = TRUE, showWarnings = FALSE)
for (lib in unique(c(R.home("library"), .libPaths())))
  for (pkg in list.dirs(lib, recursive = FALSE, full.names = FALSE))
    if (!file.exists(file.path(fakeSandbox, pkg)) && nzchar(pkg) && !grepl("^00LOCK", pkg))
      file.symlink(file.path(lib, pkg), file.path(fakeSandbox, pkg))

if (localJaspBase && !("--check-only" %in% args)) {
  if (!dir.exists(jaspBaseDir))
    stop("No jaspBase checkout at ", jaspBaseDir, " (set JASP_BASE_DIR or use --remote-jaspbase).")

  baseDesc <- read.dcf(file.path(jaspBaseDir, "DESCRIPTION"))[1, ]
  message("swapping jaspBase in renv.lock for local checkout: ", jaspBaseDir,
          " (v", baseDesc[["Version"]], ", ",
          system2("git", c("-C", jaspBaseDir, "rev-parse", "--abbrev-ref", "HEAD"), stdout = TRUE), ")")

  lockBackup <- readLines(lockPath)
  lock <- jsonlite::fromJSON(lockPath, simplifyVector = FALSE)

  depsFields <- baseDesc[c("Depends", "Imports")]
  depsFields <- depsFields[!is.na(depsFields)]
  requires <- unique(trimws(unlist(strsplit(paste(depsFields, collapse = ","), ","))))
  requires <- gsub("\\s*\\(.*", "", requires)                   # "Rcpp (>= 0.12.14)" -> "Rcpp"
  requires <- setdiff(requires, c("", "R"))

  # Same local-record shape jaspModuleTools uses for the module itself (createLocalRecord).
  lock$Packages$jaspBase <- list(
    Package      = "jaspBase",
    Version      = baseDesc[["Version"]],
    Source       = "Local",
    Requirements = requires,
    RemoteType   = "local",
    RemoteUrl    = normalizePath(jaspBaseDir),
    Cacheable    = TRUE,
    Hash         = unname(rlang::hash(rlang::hash_file(fs::dir_ls(jaspBaseDir, type = "file", recurse = TRUE))))
  )

  writeLines(jsonlite::toJSON(lock, auto_unbox = TRUE, pretty = 2), lockPath)
}

dir.create(resultdir, showWarnings = FALSE)

# renv::restore skips same-version records, so a changed local jaspBase checkout would silently
# NOT be rebuilt into the pkglib (the version stays 0.20.4). When bundling against the local
# checkout: drop the installed jaspBase first so it is always rebuilt from source.
if (localJaspBase && !("--check-only" %in% args)) {
  pkglib <- file.path(workdir, "build_dir", basename(moduledir))
  installedBase <- file.path(pkglib, "jaspBase")
  if (dir.exists(installedBase)) {
    message("removing stale jaspBase from ", pkglib, " (will rebuild from the local checkout)")
    unlink(installedBase, recursive = TRUE)
  }
}

message("compiling + bundling (log is chatty, first run compiles all of jaspBase's deps) ...")
if (!("--check-only" %in% args)) tryCatch(jaspModuleTools::compile(
  moduledir           = moduledir,
  workdir             = file.path(workdir, "build_dir"),
  resultdir           = resultdir,
  createBundle        = TRUE,
  bundleAll           = TRUE,
  buildforJaspVersion = jaspVersion,
  useJASPRemoteCellar = FALSE,
  localizeJASPModules = "identicalToLockfile"   # our lockfile (incl. the swapped jaspBase) is what we want
), error = function(e) {
  message("compile() failed: ", conditionMessage(e))
  calls <- sys.calls()
  for (i in seq_along(calls)) message(sprintf("  #%02d %s", i, substr(paste(deparse(calls[[i]]), collapse = " "), 1, 160)))
  stop(e)
}, finally = restoreLock())

# Load the module Description and the multi-dataset form through the native SyntaxInterface
# (jaspSyntax, in the tool library): catches QML errors like missing imports or unknown types
# at build time, without firing up JASP. Skipped when jaspSyntax isn't installed.
Sys.setenv(QT_QPA_PLATFORM = "offscreen")
if (requireNamespace("jaspSyntax", quietly = TRUE)) {
  message("checking module Description + QML forms via jaspSyntax ...")
  suppressPackageStartupMessages(library(jaspSyntax))
  desc <- readModuleDescription(moduledir)
  stopifnot(!is.null(desc))
  for (check in list(
      list(func = "multiDataSetFunc",     qml = "testMultiDataSet.qml",         aware = TRUE),
      list(func = "multiDataSetNonAware", qml = "testMultiDataSetNonAware.qml", aware = FALSE))) {
    qmlFile <- file.path(moduledir, "inst", "qml", check$qml)
    stopifnot(file.exists(qmlFile))
    parseOptions <- NULL
    if (check$aware) {
      # The aware forms declare dataSetSelectionOptions; the bridge (rightly) demands every one
      # of them names a loaded dataset - give the smoke check one dummy to point them all at.
      jaspSyntax::loadDataSets(list(bundleCheck = data.frame(ok = 1)))
      hits  <- Filter(function(h) length(h) == 2L,
                      regmatches(readLines(qmlFile, warn = FALSE),
                                 regexec('dataSetSelectionOption[[:space:]]*:[[:space:]]*"([^"]+)"',
                                         readLines(qmlFile, warn = FALSE))))
      sels  <- vapply(hits, function(h) h[[2]], character(1))
      stopifnot(length(sels) > 0L)
      parseOptions <- stats::setNames(as.list(rep("bundleCheck", length(sels))), sels)
    }
    parsed <- jaspSyntax::parseQmlOptions(qmlFile, options = parseOptions, moduleName = "jaspTestModule",
                                          analysisName = check$func, isolated = FALSE)
    stopifnot(!is.null(parsed))
    message("  ", check$func, " -> ", check$qml, " loads OK")
  }
} else {
  message("NOTE: jaspSyntax not installed (see github.com/jasp-stats/jaspSyntax) - QML not checked.")
}

# ---------------------------------------------------------------------------------------------
# Verify: the bundle manifest must list jaspBase, and the packed jaspBase must be OUR checkout
# (guard against silently packing a cached GitHub build instead).
bundle <- file.path(resultdir, "jaspTestModule.JASPModule")
if (!file.exists(bundle)) stop("compile() did not produce ", bundle)

checkdir <- file.path(tempdir(), "bundleCheck")
unlink(checkdir, recursive = TRUE); dir.create(checkdir, recursive = TRUE)
archive::archive_extract(bundle, dir = checkdir)

manifest <- jsonlite::fromJSON(file.path(checkdir, "jaspTestModule_manifest.json"))
jaspBaseHash <- sub(" .*", "", grep("=> jaspBase_", manifest$mapping, value = TRUE))
if (length(jaspBaseHash) != 1) stop("jaspBase not in the bundle manifest (mapping: ", paste(manifest$mapping, collapse=", "), ")")

pkgdir <- file.path(checkdir, "lib", "jaspBase")
dir.create(pkgdir, recursive = TRUE, showWarnings = FALSE)
archive::archive_extract(file.path(checkdir, jaspBaseHash), dir = pkgdir)

# The L0 tars are *installed* package trees: load the bundled jaspBase and look at what is
# actually in it. That proves OUR build (not some cached GitHub one) is in the bundle.
.libPaths(c(file.path(checkdir, "lib"), file.path(workdir, "build_dir", "jaspTestModule"), .libPaths()))
suppressPackageStartupMessages(library(jaspBase, lib.loc = file.path(checkdir, "lib")))

if (localJaspBase) {
  expected  <- c("dataSetIdFromEncoded", "dataSetNameFromEncoded", "getDataSetFor",
                 "storeDataSets")
  markers   <- stats::setNames(expected %in% getNamespaceExports("jaspBase"), expected)
  runBody   <- any(grepl("multiDataSet", deparse(body(jaspBase::runJaspResults))))
  if (!all(markers) || !runBody)
    stop("bundled jaspBase is MISSING the local multiDataSetAware code (missing exports: ",
         paste(names(markers)[!markers], collapse = ", "), if (runBody) "" else " + runJaspResults body", ")")
  message("VERIFIED: bundled jaspBase loads and carries the local multiDataSetAware code.")
} else {
  message("bundle jaspBase version: ", as.character(utils::packageVersion("jaspBase", lib.loc = file.path(checkdir, "lib"))))
}

message("Bundle: ", bundle, "  (size: ", format(file.size(bundle) / 2^20, digits = 1), " MiB)")

# ---------------------------------------------------------------------------------------------
# Install into the local developer JASP so the module is simply THERE after every build
# (same result as "Add module -> From file", through JASP's own installer - see
# Tools/installModuleLocal.sh for the mechanism). Skipped with --check-only,
# --no-install-local or SKIP_MODULE_LOCAL_INSTALL=1; a failure here is a warning only:
# the bundle itself is fine (most often JASP is still running).
if (!("--check-only" %in% args) && !("--no-install-local" %in% args) && !nzchar(Sys.getenv("SKIP_MODULE_LOCAL_INSTALL"))) {
  installer <- file.path(moduledir, "Tools", "installModuleLocal.sh")
  status <- system2(installer, shQuote(bundle))
  if (identical(as.integer(status), 0L))
    message("installed into the local JASP (module_libs + manifest + dev prefs) - restart ./build/Desktop/JASP to pick it up.")
  else
    warning("bundle built OK, but the local install failed (is JASP running?) - run Tools/installModuleLocal.sh manually.")
} else {
  message("Install in JASP: + menu -> Add module -> From file, pick that .JASPModule (or run Tools/installModuleLocal.sh).")
}
