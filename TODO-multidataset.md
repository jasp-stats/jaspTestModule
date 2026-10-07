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
1. [fix] Desktop plot gap: `Analysis::loadPlotlyJsonInResults` decodes plotly JSON against the
   analysis' OWN dataset encoder only — aware analyses plotting other datasets stay encoded.
   Same multi-encoder treatment as `Engine::sendString` `_analysisDataSetEncoders`.
2. [harden] `_analysisDataSetEncoders` stores raw `ColumnEncoder*` — dataset deleted mid-run
   dangles (only the CURRENT pointer is guarded in ~DataSet). Re-resolve by id at send time.
3. [verify] GUI end-to-end after bundle rebuild: dropdown fills tables (aware + twin), guard
   demo, per-form dataset switching in the GUI, and saved-file reload of an aware analysis
   (`restoreProvenanceFromBoundValues` / `remapSavedProvenance` still lack an end-to-end test).
4. [rebuild] Bundle via `Tools/buildBundle.R` (new jaspBase + module + qmls); user reinstalls.
5. [note] Syntax-mode side effects to watch: readRequestedDataset() after an aware parse consumes
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
- UNCOMMITTED (all suites green: JASPTest 109, QuickTest 93, rlogic incl bridge, jaspBase 46,
  module 29 incl wrapper): syntax-mode dataset selection across jasp-desktop (workspace
  dataSetByTitle, DataSetProvider titled loads + firstLoadedDataSetId + named loads skip reset,
  VariablesFormBase dataSetSelectionOption/dataSetTitleValues/selectDataSetByName/
  applyDataSetSelection, JASPControl _setInitialized apply-hook, AnalysisForm
  dataSetSelectionOptionNames, syntaxbridge pre-check + aware prepare branch + shared
  DataBridge::prepareMultiDataSetRun extraction), jaspSyntax (loadDataSets,
  loadQmlAndParseOptionsStatus, importer name), jaspBase (storeDataSets -> loadDataSets,
  runWrappedAnalysis aware flow with string parts), jaspTestModule (selection options + depends
  in testMultiDataSet.qml, twin's own qml, wrapper test rewritten, buildBundle check fixed).
- Known NOT-a-bug: jaspTools doesn't encode (longstanding, user-confirmed, out of scope).
