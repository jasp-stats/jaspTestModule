import QtQuick
import JASP.Controls
import "./common"

// Twin of testMultiDataSet.qml for the NON-aware entry (multiDataSetNonAware): same forms and
// checkboxes, but no dataSetSelectionOption - a non-aware analysis has exactly one (shown)
// dataset, in the GUI as well as in syntax mode. The dataSetSelection: true stays to demo that
// the dropdown remains inert when the analysis is not multiDataSetAware.
Form
{
	columns: 1

	ExplanationText
	{
		text:
			"Non-aware twin: identical form, but the analysis entry lacks multiDataSetAware, so " +
			"the Data selections stay inert and data comes in through the classic dataset/readDataSet path."
	}

	Section {
		title: qsTr("Form A - variables from one dataset")

		VariablesForm
		{
			dataSetSelection: true

			AvailableVariablesList	{ name: "allVariablesA" }
			AssignedVariablesList
			{
				name:	"dependentA"
				title:	qsTr("Variables A")
			}
		}
	}

	Section {
		title: qsTr("Form B - variables from another dataset")

		VariablesForm
		{
			dataSetSelection: true

			AvailableVariablesList	{ name: "allVariablesB" }
			AssignedVariablesList
			{
				name:	"dependentB"
				title:	qsTr("Variables B")
			}
		}
	}

	CheckBox
	{
		name:	"showMeta"
		label:	qsTr("Show options .meta (dataSetId/filterId provenance)")
	}

	CheckBox
	{
		name:	"guardDemo"
		label:	qsTr("Call readDataSet() anyway (should not error: non-aware run)")
	}
}
