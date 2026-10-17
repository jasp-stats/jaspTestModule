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
			"</ul>" +
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
			// term-objectification of combos).
			DropDown
			{
				name:			"comboA"
				label:			qsTr("Column combo")
				source:			zooVarsA
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
