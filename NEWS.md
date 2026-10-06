# jaspTestModule Changelog

> **HOW TO READ AND UPDATE THIS CHANGELOG:**
> 
> This document follows a modified [Keep a Changelog](https://keepachangelog.com/) format adapted for the R/JASP ecosystem. Releases are listed in reverse chronological order (newest first).
> As an example see [jaspModuleTemplate](https://github.com/jasp-stats/jaspModuleTemplate/blob/master/NEWS.md)
> * **Adding New Changes (For Contributors):** All new commits should be logged at the very top of the file under the `# jaspModuleTemplate (development version)` header. Place your bullet point under the appropriate category (`## Added`, `## Fixed`, etc.). 
> * **Issue References:** Please reference the relevant GitHub Issue (if any) at the end of your line (e.g., `([Issue #19](https://github.com/jasp-stats/jaspModuleTemplate/issues/19)`). 
> * **Format Categories:** >   * **Added:** New template features, QML examples, or build tools.
>   * **Changed:** Updates to default configurations, boilerplate code, or dependencies. 
>   * **Fixed:** Bug fixes in the build pipeline, R wrappers, or QML layouts.
>   * **Deprecated / Removed:** Outdated template components or legacy code.


---

# jaspTestModule (development version)
## Added
* "Test Multi-DataSet": analysis + form to exercise multi-dataset aware analyses
  (`multiDataSetAware` Description entries, the VariablesForm dataset/filter selection,
  the `datasets` handout and encoded-name routing of jaspBase, the readDataSet() guard,
  the `.meta` dataSetId/filterId provenance and the non-aware counterpart as controls).
  The aware analysis is wrapped (`hasWrapper: true`): body in `multiDataSetFuncInternal`,
  generated `multiDataSetFunc(datasets = ...)` wrapper for R syntax use.
* `Tools/buildBundle.R`: builds an installable `bundles_out/jaspTestModule.JASPModule`
  from this checkout with the local `jasp-desktop/Engine/jaspBase` (or any checkout via
  `JASP_BASE_DIR`) packed into the bundle; no JASP cellar needed.
* `Tools/testMultiDataSet.R` (+ `_wrapper.R`): full headless test of the analysis over
  engine-style queued slices, the wrapper in a clean session and a legacy non-aware run.
* `Tools/testdata/DataSetA.csv` / `DataSetB.csv`: two datasets with deliberately colliding
  column names for the per-dataset routing test.

## Changed
* `renv.lock` re-resolved for R 4.6.1 (current CRAN, jaspBase/jaspGraphs from GitHub HEAD).



---

# jaspModuleTemplate 0.2.0
## Added
* Added NEWS.md
* Added workflow to remind users to update their `NEWS.md`.
* Added workflow to auto-bump version when user does not do so.

---

# jaspModuleTemplate 0.1.0

## Added
* Initial examples to showcase JASP module development

## Changed
* Use best practices for checking input ([Issue #19](https://github.com/jasp-stats/jaspModuleTemplate/issues/19)).
* The main results table now defaults to displaying 95% Confidence Intervals for effect sizes.

## Fixed
* Remove deprecated dependencies from qml files ([Issue #14](https://github.com/jasp-stats/jaspModuleTemplate/issues/14)).
