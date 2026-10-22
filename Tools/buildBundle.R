#!/usr/bin/env Rscript
# Build an installable .JASPModule bundle of jaspTestModule from this checkout.
#
# The jaspBase record in renv.lock is temporarily swapped for a Local record pointing at the
# jasp-desktop checkout (default: ../jasp-desktop/Engine/jaspBase), so whatever is checked out
# there (e.g. branch multiDataSetAware) is compiled and packed into the bundle. Everything is
# built from source into a private renv library under ModuleBundleBuildDir/ - no JASP cellar
# involved, so it works on a rolling-release system (Arch) with the R you have.
#
# Requires a "tool library": a private R library (NOT your user library) holding jaspModuleTools,
# jaspModuleBundleManager, renv and their dependencies - plus jaspSyntax for the build-time QML
# smoke check (optional but recommended). Default location: ../.toolLib, sibling of this checkout;
# override with JASP_MODULE_TOOLLIB. Run this script without one and it prints the exact setup
# commands with your real paths filled in.
#
# Usage (from the jaspTestModule directory, or anywhere):
#   Rscript Tools/buildBundle.R                      # bundle with local jaspBase
#   Rscript Tools/buildBundle.R --update-lockfile    # re-resolve renv.lock first (network)
#   Rscript Tools/buildBundle.R --remote-jaspbase    # use the jaspBase from renv.lock (GitHub)
#   Rscript Tools/buildBundle.R --jasp-version=development
#   Rscript Tools/buildBundle.R --check-only         # pre-flight checks only, no build
#   Rscript Tools/buildBundle.R --no-install-local   # skip the local developer-JASP install
#   Rscript Tools/buildBundle.R --help               # this usage text
#
# Result: bundles_out/jaspTestModule.JASPModule (+ manifest json), installable via
# JASP: + (add modules) menu -> Add module -> From file.

args <- commandArgs(trailingOnly = TRUE)

scriptPath <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]))
moduledir  <- normalizePath(file.path(dirname(scriptPath), ".."))
rootdir    <- normalizePath(file.path(moduledir, ".."))

jaspBaseDir <- Sys.getenv("JASP_BASE_DIR",       file.path(rootdir, "jasp-desktop", "Engine", "jaspBase"))
toolLib     <- Sys.getenv("JASP_MODULE_TOOLLIB", file.path(rootdir, ".toolLib"))
workdir     <- file.path(moduledir, "ModuleBundleBuildDir")
resultdir   <- file.path(moduledir, "bundles_out")

localJaspBase  <- !("--remote-jaspbase" %in% args)
updateLockfile <- "--update-lockfile" %in% args
checkOnly      <- "--check-only" %in% args

jaspVersion <- "development"
for (a in args) if (grepl("^--jasp-version=", a)) jaspVersion <- sub("^--jasp-version=", "", a)

gitBranchOf <- function(dir) {
	branch <- tryCatch(suppressWarnings(system2("git", c("-C", dir, "rev-parse", "--abbrev-ref", "HEAD"),
	                                            stdout = TRUE, stderr = TRUE)),
	                   error = function(e) character(0))
	if (!length(branch) || any(grepl("fatal|not a git", branch))) "unknown" else branch[1]
}

# The single source of tool-library setup truth: printed by the header claim above, by the
# missing-directory pre-flight and by the missing-package pre-flight, always with the real
# paths of THIS checkout filled in.
printToolLibSetup <- function() {
	bundleManagerDir <- file.path(rootdir, "jasp-desktop", "Engine", "jaspModuleBundleManager")
	moduleToolsDir   <- file.path(rootdir, "jaspModuleTools")
	jaspSyntaxDir    <- file.path(rootdir, "jaspSyntax")

	cat("\n",
	    "This script builds with a private \"tool library\": a plain R library directory holding\n",
	    "jaspModuleTools, jaspModuleBundleManager, renv and their dependencies - plus jaspSyntax\n",
	    "for the build-time QML smoke check. It never touches your user library.\n\n",
	    "Expected location: ", toolLib, "\n",
	    "(keep it elsewhere? set the JASP_MODULE_TOOLLIB environment variable)\n\n",
	    "One-time setup - paste into a shell (adjust the first line to where you want the library):\n\n",
	    sep = "")
	cat(sprintf("  toolLib=%s\n  mkdir -p \"$toolLib\"\n\n", toolLib))
	cat(paste0(
		"  Rscript -e '.libPaths(c(toolLib, .libPaths()))\n",
		"    install.packages(c(\"renv\",\"fs\",\"pkgdepends\",\"usethis\",\"withr\",\"curl\",\"rjson\",\"stringr\",\n",
		"                       \"archive\",\"openssl\",\"jsonlite\",\"remotes\"), lib=toolLib,\n",
		"                     repos=\"https://cloud.r-project.org\")'\n\n"))
	if (dir.exists(bundleManagerDir))
		cat(paste0(
			"  Rscript -e '.libPaths(c(toolLib, .libPaths()))\n",
			"    remotes::install_local(\"", bundleManagerDir, "\", lib=toolLib,\n",
			"                           upgrade=\"never\", dependencies=FALSE)'\n\n"))
	else
		cat(paste0(
			"  # jaspModuleBundleManager lives in the jasp-desktop checkout (Engine/jaspModuleBundleManager);\n",
			"  # not found at ", bundleManagerDir, " - point the path at your jasp-desktop checkout:\n",
			"  Rscript -e '.libPaths(c(toolLib, .libPaths()))\n",
			"    remotes::install_local(\"<jasp-desktop>/Engine/jaspModuleBundleManager\", lib=toolLib,\n",
			"                           upgrade=\"never\", dependencies=FALSE)'\n\n"))
	if (dir.exists(moduleToolsDir))
		cat(paste0(
			"  Rscript -e '.libPaths(c(toolLib, .libPaths()))\n",
			"    remotes::install_local(\"", moduleToolsDir, "\", lib=toolLib,\n",
			"                           upgrade=\"never\", dependencies=FALSE)'\n\n"))
	else
		cat(paste0(
			"  # jaspModuleTools - no checkout next to this module; clone it first:\n",
			"  #   git clone https://github.com/jasp-stats/jaspModuleTools\n",
			"  Rscript -e '.libPaths(c(toolLib, .libPaths()))\n",
			"    remotes::install_local(\"<jaspModuleTools checkout>\", lib=toolLib,\n",
			"                           upgrade=\"never\", dependencies=FALSE)'\n\n"))
	if (dir.exists(jaspSyntaxDir))
		cat(paste0(
			"  # optional but recommended: jaspSyntax (QML smoke check; the test scripts need it too)\n",
			"  Rscript -e '.libPaths(c(toolLib, .libPaths()))\n",
			"    remotes::install_local(\"", jaspSyntaxDir, "\", lib=toolLib, upgrade=\"never\")'\n"))
	else
		cat(paste0(
			"  # optional but recommended: jaspSyntax (QML smoke check; the test scripts need it too)\n",
			"  #   git clone https://github.com/jasp-stats/jaspSyntax\n",
			"  Rscript -e '.libPaths(c(toolLib, .libPaths()))\n",
			"    remotes::install_local(\"<jaspSyntax checkout>\", lib=toolLib, upgrade=\"never\")'\n"))
	cat(paste0(
		"  #   (its configure fetches a prebuilt libSyntaxInterface from a GitHub Release; to use a local\n",
		"  #    jasp-desktop build instead, prefix the install with:\n",
		"  #    JASPSYNTAX_LIB_PATH=<build>/SyntaxInterface/libSyntaxInterface.so)\n\n"))
}

if ("--help" %in% args || "-h" %in% args) {
	cat("\nUsage: Rscript Tools/buildBundle.R [options]\n\n")
	cat("Builds bundles_out/jaspTestModule.JASPModule from this checkout. By default the renv.lock\n",
	    "jaspBase record is swapped for the local jasp-desktop checkout (--remote-jaspbase keeps the\n",
	    "GitHub record instead). Tool packages come from the tool library (see the header).\n\n", sep = "")
	cat("  --update-lockfile    re-resolve renv.lock with pkgdepends first (needs network)\n")
	cat("  --remote-jaspbase    keep the renv.lock jaspBase record (GitHub) instead of the local checkout\n")
	cat("  --jasp-version=<v>   buildforJaspVersion for jaspModuleTools::compile (default: development)\n")
	cat("  --check-only         run the pre-flight checks and exit without building\n")
	cat("  --no-install-local   skip installing the bundle into the local developer JASP\n")
	cat("  --help               this text\n\n")
	quit(status = 0)
}

# ---- pre-flight: fail early with actionable output, before touching the filesystem ----------

if (!dir.exists(toolLib)) {
	cat("\nTool library not found at ", toolLib, ".\n", sep = "")
	printToolLibSetup()
	quit(status = 1)
}

.libPaths(c(toolLib, .libPaths()))

missingPkgs <- Filter(function(p) !requireNamespace(p, quietly = TRUE),
                      c("renv", "fs", "pkgdepends", "jsonlite", "archive", "jaspModuleTools"))
if (length(missingPkgs)) {
	cat("\nCould not load (tool library ", toolLib, " is first on the path): ",
	    paste(missingPkgs, collapse = ", "), "\n",
	    "Install the missing ones into the tool library (not into your user library):\n", sep = "")
	printToolLibSetup()
	quit(status = 1)
}

if (localJaspBase && !checkOnly && !dir.exists(jaspBaseDir))
	stop("No jaspBase checkout at ", jaspBaseDir, " (set JASP_BASE_DIR or use --remote-jaspbase).")

lockPath <- file.path(moduledir, "renv.lock")
if (!file.exists(lockPath))
	stop("No renv.lock at ", lockPath, " - is ", moduledir, " the jaspTestModule checkout?")

message("Pre-flight:
  module       : ", moduledir, " (branch ", gitBranchOf(moduledir), ")
  jaspBase     : ", if (localJaspBase) paste0(jaspBaseDir, " (branch ", gitBranchOf(jaspBaseDir), ", local swap)") else "from renv.lock (GitHub) via --remote-jaspbase", "
  tool library : ", toolLib, "
  workdir      : ", workdir, "
  bundle output: ", resultdir, "
  jasp version : ", jaspVersion,
  if (checkOnly) "\n  check-only: pre-flight passed, not building.")

if (checkOnly)
	quit(status = 0)

# ---- tool environment ------------------------------------------------------------------------

suppressPackageStartupMessages({ library(jsonlite) })
library(jaspModuleTools)

# No renv sandbox: binary R distributions (Arch!) have no R sources to link it against.
Sys.setenv(RENV_CONFIG_SANDBOX_ENABLED = "false")
options(jaspRemoteCellarRedownload = FALSE)

restoreLock <- function() {
	if (!is.null(lockBackup)) {
		writeLines(lockBackup, lockPath)
		lockBackup <<- NULL
		message("restored original ", lockPath)
	}
}
lockBackup <- NULL

if (updateLockfile) {
	message("re-resolving ", lockPath, " with pkgdepends ...")
	jaspModuleTools::updateLockfile(moduledir)
	lockBackup <- readLines(lockPath)   # keep the freshly resolved one; never lose it
}

# ---- the renv sandbox that renv cannot build here (see the comment) ---------------------------

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

# ---- swap the renv.lock jaspBase record for the local checkout --------------------------------

if (localJaspBase) {
	baseDesc <- read.dcf(file.path(jaspBaseDir, "DESCRIPTION"))[1, ]
	message("swapping jaspBase in renv.lock for local checkout: ", jaspBaseDir,
	        " (v", baseDesc[["Version"]], ", branch ", gitBranchOf(jaspBaseDir), ")")

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
if (localJaspBase) {
	pkglib <- file.path(workdir, "build_dir", basename(moduledir))
	installedBase <- file.path(pkglib, "jaspBase")
	if (dir.exists(installedBase)) {
		message("removing stale jaspBase from ", pkglib, " (will rebuild from the local checkout)")
		unlink(installedBase, recursive = TRUE)
	}
}

# ---- compile + pack the bundle ----------------------------------------------------------------

message("compiling + bundling (log is chatty, first run compiles all of jaspBase's deps) ...")
tryCatch(jaspModuleTools::compile(
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

# ---- build-time QML smoke check through the native SyntaxInterface ----------------------------
# Load the module Description and the multi-dataset form through jaspSyntax (in the tool
# library): catches QML errors like missing imports or unknown types at build time, without
# firing up JASP. Skipped when jaspSyntax isn't installed.
Sys.setenv(QT_QPA_PLATFORM = "offscreen")
if (requireNamespace("jaspSyntax", quietly = TRUE)) {
	message("checking module Description + QML forms via jaspSyntax ...")
	suppressPackageStartupMessages(library(jaspSyntax))
	desc <- readModuleDescription(moduledir)
	stopifnot(!is.null(desc))
	for (check in list(
			list(func = "multiDataSetFunc",     qml = "testMultiDataSet.qml",         aware = TRUE))) {
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

# ---- verify: our jaspBase is in the bundle, not some cached GitHub build ----------------------
bundle <- file.path(resultdir, "jaspTestModule.JASPModule")
if (!file.exists(bundle)) stop("compile() did not produce ", bundle)

checkdir <- file.path(tempdir(), "bundleCheck")
unlink(checkdir, recursive = TRUE); dir.create(checkdir, recursive = TRUE)
archive::archive_extract(bundle, dir = checkdir)

manifest <- jsonlite::fromJSON(file.path(checkdir, "jaspTestModule_manifest.json"))
jaspBaseHash <- sub(" .*", "", grep("=> jaspBase_", manifest$mapping, value = TRUE))
if (length(jaspBaseHash) != 1) stop("jaspBase not in the bundle manifest (mapping: ", paste(manifest$mapping, collapse = ", "), ")")

pkgdir <- file.path(checkdir, "lib", "jaspBase")
dir.create(pkgdir, recursive = TRUE, showWarnings = FALSE)
archive::archive_extract(file.path(checkdir, jaspBaseHash), dir = pkgdir)

# The L0 tars are *installed* package trees: load the bundled jaspBase and look at what is
# actually in it. That proves OUR build (not some cached GitHub one) is in the bundle.
.libPaths(c(file.path(checkdir, "lib"), file.path(workdir, "build_dir", "jaspTestModule"), .libPaths()))
suppressPackageStartupMessages(library(jaspBase, lib.loc = file.path(checkdir, "lib")))

if (localJaspBase) {
	# Zero-export contract (CTO 2026-10-09): the multi-dataset machinery ships NO accessor
	# exports - analyses index datasets[[filter-id-key]] directly. Any reappearance fails here.
	forbidden <- c("getSliceKey", "getSlice", "sliceDataSetId", "sliceTitle", "getDataSetFor",
	               "getDataSetColumn", "dataSetIdFromEncoded", "dataSetNameFromEncoded", "storeDataSets")
	leaked    <- intersect(forbidden, getNamespaceExports("jaspBase"))
	runBody   <- any(grepl("multiDataSetJson", deparse(body(jaspBase::runJaspResults))))
	if (length(leaked) || !runBody)
		stop("bundled jaspBase violates the zero-export contract (leaked exports: ",
		     paste(leaked, collapse = ", "), if (runBody) "" else " + runJaspResults has no multiDataSetJson flow", ")")
	message("VERIFIED: bundled jaspBase loads, queue flow present, zero leaked accessor exports.")
} else {
	message("bundle jaspBase version: ", as.character(utils::packageVersion("jaspBase", lib.loc = file.path(checkdir, "lib"))))
}

# ---- wrapper-body gate: every jaspBase:: reference must be exported by the bundled jaspBase ----
# The generator once emitted the @noRd-internal jaspBase::storeDataSets into aware wrappers - a
# regenerated wrapper then died in plain R with "'storeDataSets' is not an exported object". The
# forbidden-exports check above only guards the jaspBase side; nothing caught a broken
# *reference* on the wrapper side. parse() first so comments mentioning symbols (deparse drops
# them) can never false-positive.
wrapperFiles <- list.files(file.path(moduledir, "R"), pattern = "[.]R$", full.names = TRUE)
codeNoComments <- unlist(lapply(wrapperFiles, function(f) deparse(parse(f, keep.source = FALSE))), use.names = FALSE)
refs    <- unique(unlist(regmatches(codeNoComments,
                gregexpr("jaspBase::(?!:)`?([A-Za-z._][A-Za-z0-9._]*)", codeNoComments, perl = TRUE)), use.names = FALSE))
refNames <- sub("^jaspBase::`?", "", refs)
unknown  <- setdiff(refNames, getNamespaceExports("jaspBase"))
if (length(unknown))
	stop("wrapper bodies reference jaspBase symbols the installed jaspBase does not export: ",
	     paste(unknown, collapse = ", "), " (generated by an outdated generator? regenerate the wrappers)")
message("VERIFIED: wrapper bodies reference only exported jaspBase symbols (",
        length(refNames), " distinct).")

message("Bundle: ", bundle, "  (size: ", format(file.size(bundle) / 2^20, digits = 1), " MiB)")

# ---- install into the local developer JASP ----------------------------------------------------
# So the module is simply THERE after every build (same result as "Add module -> From file",
# through JASP's own installer - see Tools/installModuleLocal.sh for the mechanism). A failure
# here is a warning only: the bundle itself is fine (most often JASP is still running).
if (!("--no-install-local" %in% args) && !nzchar(Sys.getenv("SKIP_MODULE_LOCAL_INSTALL"))) {
	installer <- file.path(moduledir, "Tools", "installModuleLocal.sh")
	status <- system2(installer, shQuote(bundle))
	if (identical(as.integer(status), 0L))
		message("installed into the local JASP (module_libs + manifest + dev prefs) - restart ./build/Desktop/JASP to pick it up.")
	else
		warning("bundle built OK, but the local install failed (is JASP running?) - run Tools/installModuleLocal.sh manually.")
} else {
	message("Install in JASP: + menu -> Add module -> From file, pick that .JASPModule (or run Tools/installModuleLocal.sh).")
}
