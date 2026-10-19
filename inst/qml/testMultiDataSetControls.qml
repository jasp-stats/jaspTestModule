// mds-plan D6.1/D6.2 - the component zoo under multi-source provenance.
//
// Every control family a real analysis form uses, each exercising per-item provenance:
//  Zoo A  plain lists: an AvailableVariablesList carrying its own dataset/filter selection
//         (the D2.2 list-level pattern) feeding an AssignedVariablesList, plus a DropDown
//         served by the same host (comboboxes stay PLAIN strings - never term objects -
//         while their value still resolves through the host namespace).
//  Zoo B  ASSIGNED list as its own host: an AssignedVariablesList with its own
//         dataSetSelectionOption (C10 says any VariablesListBase can host; this is the
//         second-source case the design must support).
//  Zoo C  TableFields-style ROW-CONTROL list: JASP.TableFields does not exist in this
//         codebase and ComponentsList (its closest named relative) cannot carry a selection,
//         so this is the row family as TableFields actually is it: an AssignedVariablesList
//         with a rowComponent (a keep checkbox and a shift integer) plus its own selection.
//         Same-name twin rows behind DIFFERENT filters (the C9 twins, set by the RPC verifier
//         through the Storage term-object shape) must keep their own children - the D6.1
//         RelatedValuesPerTerm/RowControls re-keying (TermRowKey = value + filterId) is what
//         makes that work; pre-fix the second row silently clobbered the first.
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
			"<li>Zoo B: an ASSIGNED list hosts a selection of its own.</li>" +
			"<li>Zoo C: row-control list (row-bearing variables list, the TableFields shape): same-name twin rows " +
			"from two filters keep their OWN row values.</li>" +
			"<li>Zoo D: interaction terms share one filterId over all components.</li>" +
			"<li>Zoo E: factor/level names roundtrip through the extras encoder.</li>" +
			"<li>Zoo F: the R-code textarea encodes its tokens through its own host.</li>" +
			"<li>Zoo G: a typed copy bound across differently-selected hosts keeps the SOURCE filterId.</li>" +
			"<li>Zoo H: scalar families (text / integer / real / slider / radio / checkbox-gated field) echo " +
			"as plain values AND drive results: the integer sets the preview row count, the radio picks the " +
			"flow statistic, the checkbox gates a sub-result.</li>" +
			"<li>Zoo I: a DEPENDENT dropdown - its option list is driven by Zoo A's assigned list.</li>" +
			"<li>Zoo J: a paired variables list (own selection); the pair is one term over two columns.</li>" +
			"<li>Zoo K: a FactorsForm (the FactorsList family) fed by an assigned list with its own selection.</li>" +
			"<li>Zoo L: a bound TableView whose row count follows Zoo H's integer field.</li>" +
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

	// ---- Zoo B: the ASSIGNED list is its own host ------------------------------------------------
	Section {
		title: qsTr("Zoo B - assigned list as second source (own selection)")

		AssignedVariablesList
		{
			name:					"assignedB"
			title:					qsTr("Assigned B (own Data selection)")
			dataSetSelectionOption:	"dataSetB"
		}
	}

	// ---- Zoo C: TableFields-style row controls --------------------------------------------------
	// JASP.TableFields does not exist in this codebase; ComponentsList is its closest NAMED
	// relative but is not a VariablesListBase (no dataSetSelectionOption possible, and without a
	// source relation its values never encode). The row machinery RowControls/TermRowKey is shared
	// with the row-bearing variables list, which is also what TableFields actually is (term rows +
	// per-row controls) - so the zoo exercises the row family through an AssignedVariablesList
	// with a rowComponent and its own selection host.
	Section {
		title: qsTr("Zoo C - row controls: per-row term + per-row values (own selection)")

		AssignedVariablesList
		{
			name:					"rowsC"
			title:					qsTr("Rows (term + keep + shift)")
			dataSetSelectionOption:	"dataSetC"
			optionKey:				"variable"

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
	Section {
		title: qsTr("Zoo G - typed copy bound from Zoo A keeps the SOURCE filter")

		AssignedVariablesList
		{
			name:					"boundG"
			title:					qsTr("Bound from assignedA (typed copy)")
			dataSetSelectionOption:	"dataSetG"
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
	// [["Score","Age"]]). Own selection host, so the pair's components stamp together under that
	// host's filter (C9 uniform-carry); the R side echoes each pair and computes per pair.
	Section {
		title: qsTr("Zoo J - paired variables list (own selection)")

		AssignedPairsVariablesList
		{
			name:					"pairsJ"
			title:					qsTr("Pairs (own Data selection)")
			dataSetSelectionOption:	"dataSetJ"
		}
	}

	// ---- Zoo K: factors form (the FactorsList family) ------------------------------------------------
	// FactorsList is one panel of a FactorsForm; the serialized shape is the form's: per factor
	// {name, title, indicators}. Two findings (pinned by the verifier):
	// 1. The form's inner panels are NOT hosts and do not inherit the source list's filter stamp -
	//    their unqualified terms encode through the ANALYSIS-level namespace (the D3.2 NOTE in
	//    factorsformbase.cpp leaves nested per-factor provenance to the repeated-measures exercise).
	// 2. A factor term must be a member of the form's SOURCE list (assignedK): a term outside it is
	//    silently dropped by the form's model sync, and a term the form keeps is RE-TYPED by the
	//    form (Age arrived ordinal here although sent scale, so the engine slice receives it as an
	//    R factor). A term whose column the analysis-level namespace lacks (e.g. nominal Group
	//    while DataSet 2 is shown) used to FATAL the run - the mds-plan post existence guard in
	//    Common/columnencoder.cpp now refuses to queue columns a namespace does not have, and the
	//    verifier pins the honest unresolved row (run 18) instead of a fatal.
	Section {
		title: qsTr("Zoo K - factors form (FactorsList panels over an assigned source)")

		AssignedVariablesList
		{
			name:					"assignedK"
			title:					qsTr("Assigned K (factor source, own Data selection)")
			dataSetSelectionOption:	"dataSetK"
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
