import QtQuick
import JASP.Controls
import "./common"

Form
{
	columns: 1

	ExplanationText
	{
		text:
			"Test the multi-dataset awareness of VariablesForm: each form has its own " +
			"dataset/filter selection (only live for multiDataSetAware analyses) and the results " +
			"show per-variable routing to the dataset it came from.<br>" +
			"<ul>" +
			"<li>Open a second dataset (e.g. add another CSV) so the selections have something to choose from.</li>" +
			"<li>Set form A's Data selection to one dataset and form B's to the other: the run should then " +
			"load <i>both</i> datasets (see the 'Datasets in this run' table).</li>" +
			"<li>Drag variables (try the identically named 'Score'!) into both lists: the routing table " +
			"must attribute each one to its own dataset, filter and column.</li>" +
			"<li>show .meta: the provenance stamps (dataSetId/filterId) on the bound options.</li>" +
			"<li>guard demo: readDataSet() must hard-stop inside an aware run.</li>" +
			"<li>Save the analysis to a .jasp and reopen it: the dataset routing must survive the round trip.</li>" +
			"</ul>" +
			"If no Data selection shows up, the results table will say 'Non-aware run': the analysis was " +
			"not recognised as multiDataSetAware (old JASP binary or stale module install)."
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
		title: qsTr("Form B - variables from (hopefully) another dataset")

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
		label:	qsTr("Call readDataSet() anyway (should error in aware runs)")
	}
}
