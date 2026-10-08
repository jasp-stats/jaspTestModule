# Multi-dataset aware feature — open work (2026-10-07, post syntax-mode-selection)

## Decided design (ground truth from user)
- Options and dataset slices share the ENCODED namespace (`JASPColumn_<dsId>_<n>_Encoded`);
  R indexes `datasets[[id]][[encodedValue]]` directly; results/plots are decoded on the way out
  (engine sendString loops every encoder the analysis references).
- `preloadData` forced true for aware analyses (Modules::AnalysisEntry + EntryBase getters);
  the engine checks multiAware BEFORE the preload flag.
- Syntax mode: `datasets = list(name = df, ...)` loads each df into the bridge Workspace/DataSet
  (title = list name, real ids + encoders). Each VariablesForm has a dataset-selection OPTION
  (dataSetSelectionOption names it; NO_DESKTOP_MODE-gated bound DropDown); the user fills the
  dataset NAME there; JASPControl::_setInitialized re-applies the owning form's selection before
  every child binds (order-proof), QML validates + stamps .meta, the bridge then encodes
  per-dataset and queues slices via the SHARED DataBridge::prepareMultiDataSetRun (same code as
  Engine::runAnalysis). Empty/missing selection options fail with a clear R error (bridge
  pre-check; ComboBoxBase coerces "" to first entry). No filters in syntax mode (pre-filtered
  data); default filter queued per slice. Names are user-convenience only (DataSet title).

## TODO
1. [DONE jasp-desktop d8ed73558] Desktop plot gap: `Analysis::loadPlotlyJsonInResults` decodes plotly JSON against the
   analysis' OWN dataset encoder only — aware analyses plotting other datasets stay encoded.
   Same multi-encoder treatment as `Engine::sendString` `_analysisDataSetEncoders`.
2. [DONE jasp-desktop 0bf83f920] `_analysisDataSetEncoders` stored raw `ColumnEncoder*` — dataset deleted mid-run
   dangles (only the CURRENT pointer is guarded in ~DataSet). Re-resolve by id at send time.
3. [verify] GUI end-to-end after bundle rebuild: dropdown fills tables (aware + twin), guard
   demo, per-form dataset switching in the GUI, and saved-file reload of an aware analysis
   (`restoreProvenanceFromBoundValues` / `remapSavedProvenance` still lack an end-to-end test).
4. [DONE] Bundle + local install: `Tools/buildBundle.R` now ends by installing the bundle into
   the local dev JASP automatically (Tools/installModuleLocal.sh: jaspModuleBundleManager
   install + manifest version normalization + developerMode/modulesRemembered prefs).
   Skip with `--no-install-local` / SKIP_MODULE_LOCAL_INSTALL=1; JASP must not be running.
5. [upstream] JASP bug candidate: bundle tooling writes manifest `"version":[[0,96,2]]` but
   `InstalledModules::parseModuleInfo` (installedmodules.cpp:28) throws on arrays via
   `version.isMember("Version")` → "Could not parse module manifest" → module silently skipped
   at every restart after a perfectly fine GUI install. Fix belongs in jasp-desktop
   (accept arrays) and/or jaspModuleBundleManager (write strings). installModuleLocal.sh
   works around it by rewriting the manifest field.
6. [note] Syntax-mode side effects to watch: readRequestedDataset() after an aware parse consumes
   queue slices; jaspSyntax result decoding (columnEncoderContext) is per current dataset —
   multi-dataset result decoding in pure syntax output may need the same multi-encoder care.
6. [ops] jaspSyntax installs MUST pass `JASPSYNTAX_LIB_PATH=<local libSyntaxInterface.so>`
   (configure otherwise downloads release binaries needing mysql/pq/icu74, absent here);
   after each SyntaxInterface rebuild copy the .so to BOTH `jaspSyntax/src/` and
   `.toolLib/jaspSyntax/libs/`.

## Done (this session)
- jasp-desktop `515c1f241` (dropdown visibility: syncMultiDataSetAwareness push, EntryBase notify,
  VariablesFormBase::setUp bootstrap — static controls never get formIsKnown — + render probe).
- jasp-desktop `a8cd23e5d` dead dataset-aware decode plumbing removed (C++ dataSetIdFromEncoded
  mirror, .decodeColNamesForDataSet callback chain), encode->decode->encode cycle test on real
  encoders (pins the `_Encoded` format).
- jasp-desktop `b87a8bbbe` empty-cells fix (primaryDataSetId for unfiltered analyses; aware
  checked before preload; cols always collected; rlogic bridge round-trip through jaspSyntax
  proving the index-directly invariant against real encoder output) + submodule bumps.
- jaspBase `edc73fe` helpers operate in the encoded namespace (dataSetColumnFromEncoded +
  dataSetEncodedNames snapshot deleted; real `_Encoded` parsing; direct indexing; faithful fixtures).
- jaspTools `0d621f3` dead stub + maps removed.
- jaspTestModule `6f6cec1` demo indexes directly; path-1 fixtures carry real encoded names.
- COMMITTED `2bc37b8`+jasp-desktop `3e09b7b31` etc. (all suites green: JASPTest 109, QuickTest 93, rlogic incl bridge, jaspBase 46,
X dataset selection across jasp-desktop (workspace
  dataSetByTitle, DataSetProvider titled loads + firstLoadedDataSetId + named loads skip reset,
  VariablesFormBase dataSetSelectionOption/dataSetTitleValues/selectDataSetByName/
  applyDataSetSelection, JASPControl _setInitialized apply-hook, AnalysisForm
  dataSetSelectionOptionNames, syntaxbridge pre-check + aware prepare branch + shared
  DataBridge::prepareMultiDataSetRun extraction), jaspSyntax (loadDataSets,
  loadQmlAndParseOptionsStatus, importer name), jaspBase (storeDataSets -> loadDataSets,
  runWrappedAnalysis aware flow with string parts), jaspTestModule (selection options + depends
  in testMultiDataSet.qml, twin's own qml, wrapper test rewritten, buildBundle check fixed).
- Known NOT-a-bug: jaspTools doesn't encode (longstanding, user-confirmed, out of scope).

## Crash 2026-10-08
SEGV opening Test Multi-DataSet on desktop with two CSVs loaded: log ended at
`AnalysisForm::setAnalysisUp() for 0x...` and JASP died.

**Root cause** (jasp-desktop): `testMultiDataSet.qml` carries `depends: "dataSetA"` /
`depends: "dataSetB"` on the AssignedVariablesLists (bind the syntax-mode dataset-selection
option before the lists, 3e09b7b31/5b983c9). On desktop that option's bound DropDown is
deliberately unnamed (`name: syntaxMode ? variablesForm.dataSetSelectionOption : ""`) so it is
never registered in `AnalysisForm::_controls`; `JASPControl::_addExplicitDependency` resolved
the name to `nullptr` and inserted it into `_depends` unconditionally. `AnalysisForm::sortControls`
then dereferenced it (`depend->depends()` at this=0x20). Backtrace: setAnalysisUp -> _setUpControls
-> _setUp -> sortControls -> std::set<JASPControl*>::begin(this=0x20).

**Fix** jasp-desktop `785afe486`: _addExplicitDependency only inserts resolved, non-self controls
(an unresolvable `depends` name imposes no binding order; desktop stays 100% functional, the
syntax-mode DropDown stays inert there); sortControls skips nulls defensively. No module changes.

**Repro + verify recipe (scripted, no GUI):**
1. `rpcServerEnabled=true` in ~/.config/JASP/JASP.conf; nothing else running.
2. `cd <jasp-desktop>/build && QT_QPA_PLATFORM=offscreen gdb -batch -ex run -ex bt --args ./Desktop/JASP > /tmp/jasp_run.log 2>&1 &`
3. `python3 Tools/verifyMultiDataSetRpc.py` — loads DataSetA+DataSetB via RPC (two datasets in
   one workspace), creates the analysis (this is where the pre-fix build SEGVs), binds
   dependentA=Score@ds1 and dependentB=Score+Condition@ds2 (Score exists in both; mixed
   provenance via analysis_setFilter + the unchanged-value early return in
   BoundControlBase::setBoundValue), runs and asserts the results: 'Datasets in this run' has
   both datasets (titles, 10 rows each), 'Selected variables' routes each value to its own
   dataset with n=10 and mean/levels (A:Score mean 12.50 -> DataSet 1, B:Score mean 17.73 +
   B:Condition X,Y,Z -> DataSet 2), all decoded (no JASPColumn_* left).
Pre-fix the script dies at analysis_create with the backtrace above; post-fix ALL CHECKS PASSED.
Suites green with the fix: JASPTest 109 PASS, JASPQuickTest 93 PASS.
Note: RPC `analysis_create` cannot carry options, and per-control drops are not exposed; the
script works around that with setFilter-then-run (unchanged values keep their .meta), so no
new RPC surface was needed.
