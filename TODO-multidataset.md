# Multi-dataset aware feature — open work (2026-10-07)

## Decided design (ground truth from user, this session)
- Options and dataset slices live in the SAME encoded namespace everywhere (`JASPColumn_<dsId>_<n>_Encoded`);
  R indexes `datasets[[id]][[encodedValue]]` directly; results/plots are decoded on the way out (engine sendString).
- `preloadData` is forced true for aware analyses (done at `Modules::AnalysisEntry::preloadData()` + EntryBase),
  and the engine checks `_analysisMultiDataSet` *before* the preload flag.
- Syntax mode must encode like the engine (verified: it does for single-dataset). No scans, no decode-hacks.
- Syntax-mode multi-dataset (user's design, TO BUILD):
  `datasets = list(haha = df1, godverdomme = df2)` loads each df into the bridge **Workspace/DataSet**
  (title = the user's name; names are user-convenience only). **The VariablesForms' dataset selections are
  specific options** that must not be empty (check!); the user fills e.g. `"haha"` there as soon as the data
  is loaded; selecting it switches the form's dataset context, QMLComponents then validate/encode the
  column-name options against that dataset (they know their sources, stamp `.meta` dataSetId), and the
  encoder (now existing via DataSet) encodes per datasetId. This cascades through the options.

## TODO
1. [done: subagent design] Option-backed VariablesForm dataset selection for syntax mode. Agreed plan:
   - CommonData/workspace: `dataSetByTitle(QString)` exact-match lookup (mirror dataSetByName).
   - VariablesFormBase: `dataSetSelectionOption` Q_PROPERTY (option name for this form's dataset selection);
     setter also self-declares awareness (`analysisObj()->setMultiDataSetAware(true)` — bridge dummy analysis
     otherwise never gets it); `dataSetTitleValues()` (workspace titles); `selectDataSetByName(name)`:
     empty/unknown -> addControlError, match -> analysis->setFilterId(ds->defaultFilter()->id()) +
     Workspace::setShownDataSet(ds) (filterId semantics = default, syntax users pre-filter).
   - VariablesForm.qml: a second, BOUND DropDown (name: dataSetSelectionOption, values: titles) gated by
     NO_DESKTOP_MODE (typeof-guard) -> desktop stays 100% inert; wrapper generation picks the option up.
     AssignedVariablesList gets `depends: "<selectionOption>"` so bindTo applies the selection FIRST
     (setInitialized defers; meta then stamps the right dataSetId via createMeta).
   - AnalysisForm: `dataSetSelectionOptionNames()` (findChildren<VariablesFormBase*>).
   - syntaxbridge loadQmlAndParseOptionsStatus: PRE-CHECK raw options JSON for those names (empty check,
     because ComboBoxBase coerces "" to first entry); after parse + when analysisObj aware:
     mirror Engine::runAnalysis aware block -> encodeColumnNamesinOptionsPerDataSet + setMultiDataSetQueue
     + status["multiDataSetJson"] = {ids, names-by-title} (additive JSON key, no ABI change).
   - DataSetProvider::loadDataSet overload with title; SyntaxBridgeDataSet.name finally used
     (dataframeimporter sets it; loadDataSets R export validates: named list, unique non-empty names);
     provider tracks first-loaded id as primary. createDataSet's empty-reuse quirk handled.
   - jaspBase: storeDataSets -> jaspSyntax::loadDataSets; runWrappedAnalysis aware path uses
     loadQmlAndParseOptionsStatus + runJaspResults(multiDataSetJson=...) -> engine-parity queued slices
     (encoded names + real ids; the user's plain list is NOT handed over anymore on this path).
     jaspTools keeps using the direct datasets= handout branch.
2. [impl] SyntaxInterface + jaspSyntax: multi-dataset named loading into bridge workspace (plan items above).
3. [impl] Extract the Engine::runAnalysis aware encode/queue block to shared code (DataBridge method or
   similar) so engine + syntaxbridge use ONE implementation (no duplication!).
4. [impl] jaspBase runWrappedAnalysis aware flow per plan (incl. empty-selection pre-check surfacing via
   Rcpp::stop channel).
5. [test] Module wrapper test rewrite for the new flow: `dataSetA = "haha"` style options + `depends` in
   testMultiDataSet.qml; overview keyed by bridge ids with user names as titles; direct indexing.
   (Current path-2 FAIL is the known gap this closes; mark accordingly until done.)
6. [fix] Desktop plot gap: `Analysis::loadPlotlyJsonInResults` decodes plotly JSON against the analysis'
   OWN dataset encoder only — aware analyses plotting other datasets stay encoded. Same multi-encoder
   treatment as `Engine::sendString` `_analysisDataSetEncoders`.
7. [harden] `_analysisDataSetEncoders` stores raw `ColumnEncoder*` — dataset deleted mid-run dangles
   (only the CURRENT pointer is guarded in ~DataSet). Re-resolve by id (or QPointer-style) at send time.
8. [verify] GUI end-to-end after rebuild: dropdown fills tables (aware + twin), guard demo, per-form dataset
   switching, saved-file reload of an aware analysis (provenance remap path `restoreProvenanceFromBoundValues`
   / `remapSavedProvenance` has no end-to-end test yet).
9. [rebuild] Bundle via `Tools/buildBundle.R` (new jaspBase + module), user reinstalls in dev JASP.
10. [commit] Everything across: jasp-desktop (incl. submodule bump), jaspBase branch multiDataSetAware,
    jaspTools branch multiDataSetAware, jaspTestModule.
11. [note] Side effects to document/verify once syntax flow lands: readRequestedDataset() after an aware
    parse consumes queue slices; syntax-mode result decoding (columnEncoderContext) per dataset.

## Done this session (committed unless noted)
- jasp-desktop `515c1f241`: dropdown visibility fixes (syncMultiDataSetAwareness push instead of computed
  getter; EntryBase multiDataSetAwareChanged→somethingChanged; VariablesFormBase::setUp bootstrap — static
  controls never get formIsKnown!) + render probe (93 QuickTest incl. probe).
- UNCOMMITTED (working tree, all tests green): real-format `_Encoded` regex (C++ mirror later removed per
  user), removed `.decodeColNamesForDataSet` callback chain (jasprcpp/interface/rbridge/jaspTools stub),
  preloadData forced for aware (EntryBase + AnalysisEntry), engine checks multiAware before preload +
  primaryDataSetId fallback (fresh unfiltered analyses sent dataSetId -1 → empty slice queue = the
  "empty cells" root cause), encode-per-dataset always collects cols for aware, testall encode→decode→
  encode→decode cycle test on real encoders, rlogic bridge round-trip via jaspSyntax (real encoder output,
  index-directly invariant proven through the bridge), jaspBase helpers rewritten to encoded-namespace
  direct indexing (dataSetColumnFromEncoded + dataSetEncodedNames snapshot deleted), module rewritten for
  direct indexing, module test path-1 faithful (encoded slice names) green.
- Known NOT-a-bug: jaspTools doesn't encode (longstanding, user-confirmed, out of scope).
