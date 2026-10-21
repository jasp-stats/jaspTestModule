// mds-plan D6.1/D6.2 - the component zoo under multi-source provenance.
//
// Every control family a real analysis form uses, each exercising per-item provenance:
//  Zoo A  plain lists: an AvailableVariablesList carrying its own dataset/filter selection
//         (the D2.2 list-level pattern) feeding an AssignedVariablesList, plus a DropDown
//         served by the same host (comboboxes stay PLAIN strings - never term objects -
//         while their value still resolves through the host namespace).
//  Zoo B  REMOVED (mds-plan post zoo correction, owner): a bare assigned list - an assigned
//         list with no source at all - is a malformed configuration, not a supported one:
//         every real assigned list sits in a form with a pool. Its two real pins moved: the
//         -1 analysis-fallback resolution is pinned on the default-provider pool's assigned
//         list (Zoo M, verifier run 19), foreign-stamp survival on the anchor runs.
//  Zoo C  TableFields-style ROW-CONTROL list: JASP.TableFields does not exist in this
//         codebase and ComponentsList (its closest named relative) cannot carry a selection,
//         so this is the row family as TableFields actually is it: an AssignedVariablesList
//         with a rowComponent (a keep checkbox and a shift integer), in its own form over a
//         default-provider pool (every assigned list has >= 1 source - owner rule). Same-name
//         twin rows behind DIFFERENT filters (the C9 twins, set by the RPC verifier through
//         the Storage term-object shape) must keep their own children - the D6.1
//         RelatedValuesPerTerm/RowControls re-keying (TermRowKey = value + filterId) is what
//         makes that work; pre-fix the second row silently clobbered the first. The pool's
//         key is -1, so the stamped twins are never swept by a universe reset: each twin
//         follows only its own stamp.
//  Zoo D  interaction terms: a VariablesList in Interaction mode - components of one
//         combination term share the term-level filterId (mds-plan C9 uniform-carry rule).
//  Zoo E  FactorLevelList: encodeThis -> extras-encoder roundtrip (factor/level names encode
//         through the JaspExtraOptions_ namespace and must come back decoded and usable).
//  Zoo F  TextArea with its OWN host: R-code text whose used columns encode through the
//         selected filter's view (host-bound resolution, C13).
//  Zoo G  CROSS-HOST bindTo (D6.2): a list with its own selection whose option is bound
//         (bindTo = the JSON->control applier) to a typed copy generated from Zoo A's list -
//         the copy's terms carry the SOURCE filterId. The destination rule stamps only
//         UNQUALIFIED terms (D5.1 intake guard) and the restamp walk never touches foreign
//         stamps (D3.5 owns-the-stamp), so the value must encode and resolve through the
//         SOURCE's slice even though this list's own dropdown selects another one.
//  Zoo M  THREE pools over the same test dataset (the mds-plan post zoo correction): a
//         hostless pool (no dataSetSelectionOption at all - the default-provider pool whose
//         participation key is -1), Zoo A's pool hosted by the existing filter selection
//         (dataSetA, filter 1), and the EXTRA SOURCE: a new AvailableVariablesList hosted by
//         the THIRD filter of the same test dataset. The third filter does not exist in a
//         fresh RPC workspace (data_load mints one default filter per dataset and the RPC has
//         no filter-creation method), so this form bootstraps it itself - see the guard in
//         Zoo M (module-side test fixture: the test provides its own filters). f3-origin terms
//         carry its stamp, which is what makes the anchor scenario assertable: switching Zoo
//         A's pool from ds1/f1 to ds1/f3 must move the f1-stamped terms (their participation
//         key is the OLD selection id) while an f3-origin term in the same list survives
//         untouched - a dataset-scoped sweep would wrongly have swept it, because both
//         filters sit on the SAME dataset.
//  Zoo N  DERIVED pool: an AvailableVariablesList whose source is TWO assigned lists
//         (assignedA + assignedDefault, mixed provenance). Its terms are references that keep
//         each source term's OWN stamp; the known limitation (the reason the `to` scalar was
//         dropped from the reset signal) is that mixed-source refs do not follow a
//         source-list host switch this pass.
//
// The R echo (R/multiDataSetControls.R) reports for every received value: the (encoded) name
// as received, WHICH slice index it resolved in, and the row children - so provenance is
// assertable from the results through Tools/verifyMultiDataSetRpc.py.
import QtQuick
import JASP
import JASP.Controls
import "./common"

Form
{
	columns: 1

	ExplanationText
	{
		text:
			"Component-zoo provenance test (multiDataSetAware). Open two datasets, then check the " +
			"'Controls provenance' table: every control family lists the values it received, the " +
			"slice each value resolved in and its row children.<br>" +
			"<ul>" +
			"<li>Zoo A: selection on the available list drives the assigned list and the combobox.</li>" +
			"<li>Zoo B: removed - a bare assigned list (no source) is malformed; its pins live on the " +
			"default-provider pool's list (Zoo M).</li>" +
			"<li>Zoo C: row-control list (row-bearing variables list, the TableFields shape), sourced " +
			"from the default-provider pool: same-name twin rows " +
			"from two filters keep their OWN row values.</li>" +
			"<li>Zoo D: interaction terms share one filterId over all components.</li>" +
			"<li>Zoo E: factor/level names roundtrip through the extras encoder.</li>" +
			"<li>Zoo F: the R-code textarea encodes its tokens through its own host.</li>" +
			"<li>Zoo G: a typed copy bound across differently-selected hosts keeps the SOURCE filterId.</li>" +
			"<li>Zoo H: scalar families (text / integer / real / slider / radio / checkbox-gated field) echo " +
			"as plain values AND drive results: the integer sets the preview row count, the radio picks the " +
			"flow statistic, the checkbox gates a sub-result.</li>" +
			"<li>Zoo I: a DEPENDENT dropdown - its option list is driven by Zoo A's assigned list.</li>" +
			"<li>Zoo J: a paired variables list over the pool on dataSetJ; the pair is one term over two columns.</li>" +
			"<li>Zoo K: a FactorsForm (the FactorsList family) fed by an assigned list over the pool on dataSetK.</li>" +
			"<li>Zoo L: a bound TableView whose row count follows Zoo H's integer field.</li>" +
			"<li>Zoo M: three pools over DataSet 1 - hostless (-1), Zoo A's pool on filter 1, and the extra source on the third filter; switching Zoo A from f1 to f3 must not sweep an f3-origin term.</li>" +
			"<li>Zoo N: a derived pool whose options come from Zoo A's and the default pool's assigned lists (mixed provenance).</li>" +
			"</ul>" +
			"The results panel shows the LOADED DATA per slice (head of every column, row count = Zoo H's " +
			"integer), the per-family provenance echo, the scalar echoes, the flow demonstrations and the " +
			"cross-slice computations." +
			"'Show options .meta' adds the PROVENANCE_AUDIT (R must never see provenance: C8/C11)."
	}

	// ---- Zoo A: list-level selection (D2.2 pattern) + combobox ----------------------------------
	Section {
		title: qsTr("Zoo A - plain lists, own selection")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:					"zooVarsA"
				dataSetSelectionOption:	"dataSetA"
			}
			AssignedVariablesList
			{
				name:		"assignedA"
				title:		qsTr("Assigned A")
				depends:	"dataSetA"
			}
			// a combobox served by the same host: values stay PLAIN strings (never term objects)
			// while the selection resolves through the host namespace (landmine: no
			// term-objectification of combos). NB: the source must be the STRING NAME of the
			// control - a bare `source: zooVarsA` is a QML ReferenceError (the id does not exist;
			// found via the runtime log: "ReferenceError: zooVarsA is not defined") and the
			// dropdown silently ran with an empty option list until fixed.
			DropDown
			{
				name:			"comboA"
				label:			qsTr("Column combo (options from the available list)")
				source:			"zooVarsA"
				addEmptyValue:	true
			}
		}
	}

	// ---- Zoo C: TableFields-style row controls --------------------------------------------------
	// JASP.TableFields does not exist in this codebase; ComponentsList is its closest NAMED
	// relative but is not a VariablesListBase. The row machinery RowControls/TermRowKey is shared
	// with the row-bearing variables list, which is also what TableFields actually is (term rows +
	// per-row controls) - so the zoo exercises the row family through an AssignedVariablesList
	// with a rowComponent, in its own form over a default-provider pool (every assigned list has
	// >= 1 source - owner rule; the bare standalone form died with Zoo B). Its pool's key is -1,
	// so the stamped twin rows below are never swept by any reset - each twin follows only its
	// own stamp, which is exactly the C9 case.
	Section {
		title: qsTr("Zoo C - row controls: per-row term + per-row values (default-provider source)")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:	"zooPoolC"		// default-provider pool: no selection, participation key -1
			}
			AssignedVariablesList
			{
				name:		"rowsC"
				title:		qsTr("Rows (term + keep + shift)")
				optionKey:	"variable"

				rowComponent: Row
				{
					CheckBox
					{
						name:	"keep"
					}
					IntegerField
					{
						name:	"shift"
						min:	-999
						max:	999
					}
				}
			}
		}
	}

	// ---- Zoo D: interaction terms ----------------------------------------------------------------
	Section {
		title: qsTr("Zoo D - interaction terms (components share one filterId)")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:					"zooVarsD"
				dataSetSelectionOption:	"dataSetD"
			}
			VariablesList
			{
				name:			"interactionD"
				title:			qsTr("Model terms")
				listViewType:	JASP.Interaction
				depends:		"dataSetD"
			}
			// (no CrossButton/AssignButton chrome needed for the test: the verifier drives
			// interactionD through its option; the buttons are pure UI in this codebase)
		}
	}

	// ---- Zoo E: factor/level names (encodeThis -> extras) ---------------------------------------
	Section {
		title: qsTr("Zoo E - factor levels (extras roundtrip)")

		FactorLevelList
		{
			name:		"factorsE"
			minFactors:	0
			minLevels:	0
			factorName:	"Fac"
			levelName:	"Lev"
		}
	}

	// ---- Zoo F: textarea with its own host -------------------------------------------------------
	Section {
		title: qsTr("Zoo F - R-code textarea, own host")

		TextArea
		{
			name:					"codeF"
			dataSetSelectionOption:	"dataSetF"
			depends:				"dataSetF"	// the host binds first: the bind-time encodeRScript resolves THIS filter, not the analysis fallback
			textType:				JASP.TextTypeRcode
		}
	}

	// ---- Zoo G: cross-host bindTo (D6.2) ---------------------------------------------------------
	// The selection lives on the POOL now (the per-list dataSetSelectionOption crutch is gone,
	// same correction as B/C): boundG sits in a form over the pool hosted by dataSetG's filter,
	// so every assigned list has its source. The cross-host pin is unchanged: the verifier binds
	// a typed copy of a filter-1 term into boundG while the pool selects filter 2 - the copy
	// keeps the SOURCE filterId and encodes through the SOURCE's slice (D6.2), origin
	// -authoritative: a stamp is born at Storage/bindTo and is not requalified by a destination.
	Section {
		title: qsTr("Zoo G - typed copy bound from Zoo A keeps the SOURCE filter")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:					"zooPoolG"
				dataSetSelectionOption:	"dataSetG"
			}
			AssignedVariablesList
			{
				name:		"boundG"
				title:		qsTr("Bound from assignedA (typed copy)")
				depends:	"dataSetG"
			}
		}
	}

	// ---- Zoo H: scalar control families -----------------------------------------------------------
	// Every scalar family a real form binds, each with an R-side consumer that actually USES the
	// value (not just echoes it): the integer drives the data-preview row count and Zoo L's row
	// count, the radio picks the flow statistic, the checkbox gates a whole sub-result, the real
	// and the gated field enter the cross-slice computations. Slider is echo-only (a fraction has
	// no sensible computation here - documented in R/multiDataSetControls.R, not faked).
	Section {
		title: qsTr("Zoo H - scalar controls (text / integer / real / slider / radio / gated)")

		columns: 2

		TextField
		{
			name:			"textH"
			label:			qsTr("Text field (echoed verbatim)")
			placeholderText: qsTr("echo me")
		}
		IntegerField
		{
			id:				rowsH
			name:			"rowsH"
			label:			qsTr("Preview rows (drives data previews + Zoo L)")
			defaultValue:	5
			min:			1
			max:			10
		}
		DoubleField
		{
			name:			"doubleH"
			label:			qsTr("Scale factor (real number)")
			defaultValue:	1.5
			min:			0
			max:			100
			decimals:		2
		}
		Slider
		{
			name:			"sliderH"
			label:			qsTr("Slider fraction (echo only)")
			value:			0.5			// Slider has no defaultValue property: the initial bound value IS `value`
			min:			0
			max:			1
			stepSize:		0.1
		}
		RadioButtonGroup
		{
			name:	"radioH"
			title:	qsTr("Flow statistic")

			RadioButton { value: "mean"; label: qsTr("Mean"); checked: true }
			RadioButton { value: "sum";  label: qsTr("Sum") }
		}
		CheckBox
		{
			name:	"gateH"
			label:	qsTr("Gate: produce the gated sub-result")

			DoubleField
			{
				name:			"gatedH"
				label:			qsTr("Gated threshold")
				defaultValue:	10.0
				min:			0
				max:			100
				decimals:		1
			}
		}
	}

	// ---- Zoo I: dependent dropdown -----------------------------------------------------------------
	// The option LIST of this dropdown is driven by another control's value: source is Zoo A's
	// assigned list, so its choices are exactly the terms currently in assignedA (and follow every
	// change of that list - the RPC verifier flips assignedA and asserts the effective selection
	// follows). Value stays a PLAIN string (never term-objectified, landmine 4).
	Section {
		title: qsTr("Zoo I - dependent dropdown (options driven by Zoo A's assigned list)")

		DropDown
		{
			name:			"comboI"
			label:			qsTr("Pick a column from Assigned A")
			source:			"assignedA"
			addEmptyValue:	true
		}
	}

	// ---- Zoo J: paired variables list ---------------------------------------------------------------
	// The paired-list family: AssignedPairsVariablesList is a VariablesList preset (2 columns,
	// drop-replace) whose model PAIRS its columns into 2-component terms (bound value
	// [["Score","Age"]]). Served by the pool hosted on dataSetJ's filter, so the pair's
	// components stamp together under that pool's filter (C9 uniform-carry); the R side echoes
	// each pair and computes per pair.
	Section {
		title: qsTr("Zoo J - paired variables list (pool on dataSetJ)")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:					"zooPoolJ"
				dataSetSelectionOption:	"dataSetJ"
			}
			AssignedPairsVariablesList
			{
				name:		"pairsJ"
				title:		qsTr("Pairs (pool on dataSetJ)")
				depends:	"dataSetJ"
			}
		}
	}

	// ---- Zoo K: factors form (the FactorsList family) ------------------------------------------------
	// FactorsList is one panel of a FactorsForm; the serialized shape is the form's: per factor
	// {name, title, indicators}. Findings (pinned by the verifier):
	// 1. The form's inner panels are NOT hosts, but the per-factor sidecar
	//    (FactorsFormBase::createFilterIds, mds-plan post) transports each term's OWN filterId
	//    per factor and per term: a term keeps the stamp its source list synced onto it
	//    (assignedK -> filter 1) and encodes through THAT filter's view - resolved slice by
	//    slice, no analysis-level fallback (the D3.2 hostless-panel deferral is CLOSED).
	// 2. A factor term must be a member of the form's SOURCE list (assignedK): a term outside it is
	//    silently dropped by the form's model sync, and a term the form keeps is RE-TYPED by the
	//    form (Age arrived ordinal here although sent scale, so the engine slice receives it as an
	//    R factor). A term whose column the resolved namespace lacks used to FATAL the run - the
	//    mds-plan post existence guard in Common/columnencoder.cpp refuses to queue columns a
	//    namespace does not have; with the per-factor sidecar the term resolves in its OWN
	//    namespace instead (verifier run 18 pins the resolved row + clean audit).
	Section {
		title: qsTr("Zoo K - factors form (FactorsList panels over an assigned source)")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:					"zooPoolK"
				dataSetSelectionOption:	"dataSetK"
			}
			AssignedVariablesList
			{
				name:		"assignedK"
				title:		qsTr("Assigned K (factor source)")
				depends:	"dataSetK"
			}
		}
		FactorsForm
		{
			name:				"factorsK"
			initNumberFactors:	1
			baseName:			"Fac"
			baseTitle:			"Factor"
			allowedColumns:		["scale", "ordinal", "nominal"]
			availableVariablesList.source: "assignedK"
		}
	}

	// ---- Zoo L: bound table view ---------------------------------------------------------------------
	// The BoundControlTableView family: a bound SimpleTableView whose ROW COUNT is driven by Zoo
	// H's integer field (initialRowCount + tableView.rowCount follow rowsH, exactly the
	// testTableView.qml pattern). Its cells are plain values (no provenance - a tableview option
	// is not a Terms option) and the R side USES them: the multiplier column rescales the assigned
	// columns of every slice in the cross-slice computation.
	Section {
		title: qsTr("Zoo L - bound table view (row count driven by Zoo H's integer field)")

		SimpleTableView
		{
			name:				"tableL"
			cornerText:			qsTr("Par")
			initialRowCount:	rowsH.value
			tableView.rowCount:	rowsH.value
			initialColumnCount:	2
			columnNames:		[qsTr("Multiplier"), qsTr("Offset")]
			itemTypePerColumn:	[JASP.Double, JASP.Double]

			function getDefaultValue(columnIndex, rowIndex)
			{
				return columnIndex === 0 ? 1.0 + rowIndex : 0.5 * (rowIndex + 1);
			}
		}
	}

	// ---- Zoo M: three pools over one dataset (hostless / f1 / f3) --------------------------------
	// The mds-plan post zoo correction. The EXTRA SOURCE is zooPoolThree: an AvailableVariablesList
	// whose host selection is the THIRD filter of the same test dataset. A fresh RPC workspace has
	// only the two default filters (data_load mints one per dataset; the RPC has no filter-creation
	// method), so the form bootstraps the third filter itself, once, guarded: only when the
	// workspace is exactly the zoo fixture shape (a dataset with id 1 that has no "Filter 0" yet).
	// filterModel/workspace are root-context properties and module QML loads under the root
	// context, so both are visible here. filterModel.addFilter(1) is the same invokable the filter
	// editor uses (DataSet::addFilter -> named "Filter 0", default all-rows rFilter, its own
	// data-table column and its own encoder namespace JASPColumn_D1_F3_).
	//
	// The three pools and their participation keys:
	//   zooPoolHostless  no dataSetSelectionOption  -> key -1 (default provider)
	//   zooVarsA (Zoo A) dataSetA                   -> key = whatever dataSetA holds (f1 -> f3 anchor)
	//   zooPoolThree     dataSetM3                  -> key 3 (the f3-origin namespace)
	Component.onCompleted: {
		// Zoo fixture bootstrap (test-only): ensure the third filter exists on the existing test
		// dataset. No-op in any other workspace shape; no-op once it exists (verifier re-runs).
		// NB: the 'workspace' ROOT CONTEXT PROPERTY is only set from onWorkspaceChanged() and was
		// observed UNDEFINED at form load in an RPC session - route through dataSetPackage's
		// workspace Q_PROPERTY instead, which loadQML() always installs.
		var ws = (typeof dataSetPackage !== "undefined" && dataSetPackage) ? dataSetPackage.workspace : null
		if (typeof filterModel !== "undefined" && ws && ws.filterIdByName(1, "Filter 0") < 0)
			console.log("ZOO BOOTSTRAP: creating the third filter on dataset 1 -> id " +
						(function(){ filterModel.addFilter(1); return ws.filterIdByName(1, "Filter 0"); })())
	}

	Section {
		title: qsTr("Zoo M - the extra source: pool on the third filter (+ the hostless pool)")

		VariablesForm
		{
			// the default-provider pool: NO host selection, participation key -1
			AvailableVariablesList
			{
				name:	"zooPoolHostless"
			}
			AssignedVariablesList
			{
				name:	"assignedDefault"
				title:	qsTr("Assigned (default-provider pool)")
			}
		}
		VariablesForm
		{
			// THE EXTRA SOURCE: hosted by the third filter of the same test dataset; its universe
			// terms carry the f3 stamp (JASPColumn_D1_F3_ namespace)
			AvailableVariablesList
			{
				name:					"zooPoolThree"
				dataSetSelectionOption:	"dataSetM3"
			}
			AssignedVariablesList
			{
				name:	"assignedThree"
				title:	qsTr("Assigned (third-filter pool)")
			}
		}
	}

	// ---- Zoo N: derived pool (mixed sources) ------------------------------------------------------
	// An AvailableVariablesList whose source is TWO assigned lists: its listed terms are
	// references carrying each source term's OWN stamp (mixed provenance). Known limitation
	// (documented in the mds-plan post): mixed-source refs do not follow a source-list host
	// switch this pass - that is exactly why the reset signal carries the participation key
	// instead of a `to` scalar.
	Section {
		title: qsTr("Zoo N - derived pool (source: assignedA + assignedDefault)")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:	"zooPoolDerived"
				source:	["assignedA", "assignedDefault"]
			}
			AssignedVariablesList
			{
				name:	"assignedDerived"
				title:	qsTr("Assigned (derived pool)")
			}
		}
	}

	// ---- scalars (M5 contract: never provenanced, never term-objectified) ------------------------
	Section {
		title: qsTr("Scalars")

		columns: 2

		CheckBox
		{
			name:	"showMeta"
			label:	qsTr("Show options .meta (PROVENANCE_AUDIT)")
		}
		CheckBox
		{
			name:	"plainSwitch"
			label:	qsTr("Plain switch")
		}
		DropDown
		{
			name:	"comboG"
			label:	qsTr("Plain combo")
			values:	["first", "second", "third"]
		}
	}
}
