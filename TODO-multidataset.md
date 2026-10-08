# Multi-dataset aware feature — status (2026-10-08, post FilterSelect refactor)

## Decided design (ground truth, v2 — supersedes the linked-dropdown v1)
- Options and dataset slices share the ENCODED namespace (`JASPColumn_<dsId>_<n>_Encoded`);
  R indexes the slice's columns by option value directly; results/plots are decoded on the way
  out (engine sendString loops every workspace encoder; plotly decode loops referenced datasets).
- **Selection state is per-HOST, not per-analysis.** Any component consuming variable info for
  itself declares `dataSetSelectionOption` (a `HostFilterSelection` member): VariablesFormBase
  and TextAreaBase do so today. The option's value is a **FILTER ID** (a filter implies its
  dataset; ids survive renames), written in BOTH modes by one reusable `FilterSelect.qml`
  (a bound DropDown, `values:` = workspace filter list "DataSet - Filter", created behind
  `Loader { active: selectionAvailable }` so an unnamed bound control can never exist).
- **Provider chain follows the component chain:** each selecting host owns a `VariableInfo`
  whose provider is the selected `Filter` (Filter *is* a VariableInfoProvider: per-dataset
  columns/types/levels, rows filtered, `Filter::columnEncoder()` gives the dataset encoder).
  `JASPControl::effectiveVarInfo()` / `effectiveSelectionFilter()` resolve nearest-selecting-host
  (self included), else `AnalysisForm::varInfo()` (analysis filter / shownFilter — today's
  behavior for everything non-aware). Non-JASPControl pieces (Formula) use the static
  `JASPControl::varInfoForItem()`.
- **Selection code never touches** `analysis->setFilterId` / `workspace->setShownDataSet` —
  those belong to the analysis-GLOBAL FilterMenuButton (the true legacy widget, untouched).
- `.meta` provenance is stamped with the filter the value was selected THROUGH (host's, else
  analysis'), so per-form datasets survive save/restore and reach the engine per control.
- **Slice queue keyed by filter id:** `prepareMultiDataSetRun` collects every distinct
  (dataSetId, filterId) from `.meta`; one slice per pair (two forms on one dataset with
  different filters → two differently-filtered dataframes). R-side `datasets` keys = resolved
  filter id, `attr "dataSetIds"`/`"dataSetNames"` map back; a selection option indexes its own
  slice directly: `datasets[[as.character(options$dataSetA)]]`. jaspTools handouts stay keyed by
  dataset id; `.sliceKeyForDataSet` bridges both.
- **Syntax deviation confined to the wrapper layer:** bridge translates a selection option that
  names a loaded dataset ("haha") into that DataSet's default filter id before binding (unknown
  names fail loudly with the list of loaded datasets; "" too). `datasets = list(haha = df, ...)`
  stays the user-facing API (names become DataSet titles). Forms are mode-blind.
- Single-dataset API on AnalysisBase **refuses** for aware analyses instead of silently answering
  about one arbitrary dataset: `Analysis::dataSet()`, `isColumnFreeOrMine()`,
  `isOwnComputedColumn()`, computed-column request handlers (log + safe default);
  `usesDataSet()` consults `referencedDataSets()` when aware.
- `preloadData` forced true for aware analyses; engine checks multiAware BEFORE preload.
- Vanished filter/dataset while selected: selection falls back to the analysis/current filter
  (same spirit as the analysis-global behavior), never dangles (HostFilterSelection validates on
  dataSetRemoved/filtersCountChanged).

## Review round 2026-10-08 (subagent review + user directives) - RESOLVED
- CRITICAL empty-GUI-tables: module tables were filled row-by-row with `:`-containing keys
  (poisoned DOM ids -> JS showed nothing though the data was there). Fixed: data.frame + setData
  (row-major, no custom ids) per user directive. jasp-desktop 841431fae, jaspBase 73ab.., module.
- CRITICAL save/reload: provenance side table is now per (dataset,filter) PAIR by name, and
  isFilterSelection-marked option VALUES get remapped on load (unit-tested incl. numeric
  collision guard). Real file save/reopen test still open (item 2).
- Mirroring removed (user: mirroring is bad; jaspTools-legacy is the ONLY exception): _encoder()
  duplication hoisted to BoundControlTextArea, dead variableInfoProvider deleted, selection-key
  logic centralized in jaspBase.
- Slices are indexed by FILTER everywhere; dataset-id helper routing ERRORS on multi-slice
  datasets (never silently first); getSliceKey/getSlice/sliceDataSetId/sliceTitle are the
  writer-facing API; encoding stays per dataset (names embed ds id).
- Also: TextAreaBase options now translated by the bridge (optionNames scan), queue dedups
  equal slice keys + exposes "primary" slice (attr primarySliceKey), VariableInfo emits on
  first provider, plot decode no longer trips the aware guard.

## TODO
1. [verify-manual] GUI smoke test (last resort, everything else is scripted): two CSVs, open
   Test Multi-DataSet, flip BOTH "Data" dropdowns independently, watch tables stay filled and
   unlinked; R/JAGS text areas with an option show their own dropdown.
2. [open] Saved-file reload of an aware analysis end-to-end: per-form filter-id selections
   restored through `bindTo` (+ `restoreProvenanceFromBoundValues`), vanished filter → fallback.
   No automated test yet (needs RPC save/open or a crafted .jasp fixture).
3. [open] Same-dataset-two-filters desktop GUI demo: the module analysis routes per form's
   selection slice; a test data pair where BOTH forms use dataset 1 with different filters would
   exercise the C8 two-slice path in the GUI (covered in rlogic unit, not e2e).
4. [upstream] JASP bug candidate: bundle tooling writes manifest `"version":[[0,96,2]]` but
   `InstalledModules::parseModuleInfo` throws on arrays → module silently skipped at restart.
   installModuleLocal.sh works around it (rewrites to string).
5. [KNOWN PRE-EXISTING FAILURE — user-confirmed, NOT from the FilterSelect refactor]
   `ctest testDbMigration` aborts: "Trying to load ':memory:' but it doesn't exist!" — broken
   since the earlier multi-dataset work (workspace/database lifecycle). Investigate separately.
6. [note] Syntax-mode side effects to watch: readRequestedDataset() after an aware parse consumes
   queue slices; jaspSyntax result decoding is per current dataset — multi-dataset result decoding
   in pure syntax output may need the same multi-encoder care.
7. [ops] jaspSyntax installs MUST pass `JASPSYNTAX_LIB_PATH=<local libSyntaxInterface.so>`;
   after each SyntaxInterface rebuild copy the .so to BOTH `jaspSyntax/src/` and
   `.toolLib/jaspSyntax/libs/`.
8. [later] FormulaBase as host in its own right (its own FilterSelect + option): today a Formula
   only follows the VariablesForm it lives in (varInfoForItem). Top-level Formulas keep the
   analysis-wide fallback.

## Done (FilterSelect refactor, 2026-10-08) — plan file: /home/virtuoos/.opencode/plan/multidataset-filterselect.md
- jasp-desktop `8636529f5` RED contract tests first (two forms two filters simultaneously,
  bogus-id rejection, per-form list contents; fixture dataset "Second" w/ overlapping TestInts).
- jasp-desktop `557f089d1` the core: HostFilterSelection (filter-id, per-host state, C10
  validation), JASPControl::effectiveVarInfo/effectiveSelectionFilter + all consumers rerouted
  (lists, SourceItem, textareas, custom contrasts, filteredDataEntry, R/JAGS textareas),
  FilterSelect.qml, createMeta stamps host filter, Filter::columnEncoder, single-dataset guards,
  usesDataSet-referencedDataSets; DELETED: dataSetSelection bool + both old dropdowns,
  selectDataSetByName/applyDataSetSelection, _setInitialized re-apply hook, name-based
  selection, analysis-filter mirroring.
- jasp-desktop `3bbafd477` + jaspBase `69ec48c` filter-keyed slice queue (pair collector,
  per-pair slices, `.sliceKeyForDataSet`, rlogic + unit tests for the contract).
- jasp-desktop `e8a4db4e5` bridge name→default-filter-id translation (C7), errors list datasets.
- jasp-desktop `46c4603c3` TextAreaBase host (FilterSelect in TextArea.qml, JAGS highlighter
  follows host) + Formula follows its form's host.
- module `c2d59eb` qmls use only dataSetSelectionOption (+depends, now resolvable in both modes);
  R routes via the form's own selection slice with legacy fallback; wrapper regenerates.
- module RPC verifier now drives the dropdown contract itself (options carry filter ids, NO
  analysis_setFilter anywhere): independent simultaneous selections, A:Score mean 12.50 vs
  B:Score mean 17.73 (same name, different datasets — the "compare with itself" trap made
  impossible), per-form .meta stamps (1/1 vs 2/2), n=10 everywhere, zero raw JASPColumn_*.
- Suites green: JASPTest 110, JASPQuickTest 96 (T1-T3c/T9/T12), JASPTestColumnEncoderContext 10,
  rlogic incl. bridge round-trip, module paths 1-3, RPC desktop e2e ALL CHECKS PASSED.
  (ctest except testDbMigration — see item 5, pre-existing.)

## Crash 2026-10-08 (fixed, historical)
SEGV opening Test Multi-DataSet: `depends: "dataSetA"` targeted the syntax-only dropdown that was
deliberately unnamed on desktop → `_addExplicitDependency` inserted nullptr → `sortControls`
deref'd it. Interim fix `785afe486` (skip unresolved deps — kept as defense). The FilterSelect
refactor removed the ROOT cause: the dropdown is now named and registered in both modes, and
`Loader { active: selectionAvailable }` makes an unnamed bound control structurally impossible.
