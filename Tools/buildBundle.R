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
on.exit({
  if (!is.null(lockBackup)) {
    writeLines(lockBackup, lockPath)
    message("restored original ", lockPath)
  }
})

if (updateLockfile) {
  message("re-resolving ", lockPath, " with pkgdepends ...")
  jaspModuleTools::updateLockfile(moduledir)
}

if (localJaspBase) {
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

dir.create(workdir, recursive = TRUE, showWarnings = FALSE)
dir.create(resultdir, showWarnings = FALSE)

message("compiling + bundling (log is chatty, first run compiles all of jaspBase's deps) ...")
jaspModuleTools::compile(
  moduledir           = moduledir,
  workdir             = file.path(workdir, "build_dir"),
  resultdir           = resultdir,
  createBundle        = TRUE,
  bundleAll           = TRUE,
  buildforJaspVersion = jaspVersion,
  useJASPRemoteCellar = FALSE,
  localizeJASPModules = "identicalToLockfile"   # our lockfile (incl. the swapped jaspBase) is what we want
)

# restore the pristine lockfile before verifying so an interrupted run can't leak the local record
if (!is.null(lockBackup)) { writeLines(lockBackup, lockPath); lockBackup <- NULL }

# ---------------------------------------------------------------------------------------------
# Verify: the bundle manifest must list jaspBase, and the packed jaspBase must be OUR checkout
# (guard against silently packing a cached GitHub build instead).
bundle <- file.path(resultdir, "jaspTestModule.JASPModule")
if (!file.exists(bundle)) stop("compile() did not produce ", bundle)

checkdir <- file.path(tempdir(), "bundleCheck")
unlink(checkdir, recursive = TRUE); dir.create(checkdir, recursive = TRUE)
archive::archive_extract(bundle, dir = checkdir)

manifest <- jsonlite::fromJSON(file.path(checkdir, "jaspTestModule_manifest.json"))
jaspBaseHash <- sub(" .*", "", grep("^jaspBase ", manifest$mapping, value = TRUE))
if (length(jaspBaseHash) != 1) stop("jaspBase not in the bundle manifest (mapping: ", manifest$mapping, ")")

pkgdir <- file.path(checkdir, "jaspBase")
archive::archive_extract(file.path(checkdir, jaspBaseHash), dir = pkgdir)

commonR <- file.path(pkgdir, "jaspBase", "R", "common.R")
if (!file.exists(commonR)) commonR <- file.path(pkgdir, "common.R")   # L0 tar may sit one level deeper
packed <- paste(readLines(commonR), collapse = "\n")
if (localJaspBase) {
  stopifnot(grepl("\\.multiDataSetMode", packed), grepl("dataSetColumnFromEncoded", packed))
  message("VERIFIED: bundled jaspBase contains the multiDataSetAware code (.multiDataSetMode + dataSetColumnFromEncoded).")
}

message("Bundle: ", bundle, "  (size: ", format(file.size(bundle) / 2^20, digits = 1), " MiB)")
message("Install in JASP: + menu -> Add module -> From file, pick that .JASPModule.")
