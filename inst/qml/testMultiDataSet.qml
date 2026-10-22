import QtQuick
import JASP.Controls
import "./common"

Form
{
	columns: 1

	ExplanationText
	{
		text:
			"Test the multi-dataset awareness of the variable lists: each selecting list owns its " +
			"dataset/filter selection (only live for multiDataSetAware analyses) and the results " +
			"show per-variable routing to the dataset it came from.<br>" +
			"<ul>" +
			"<li>Open a second dataset (e.g. add another CSV) so the selections have something to choose from.</li>" +
			"<li>Set section A's Data selection (on its available list) to one dataset and section B's " +
			"to the other: the run should then load <i>both</i> datasets (see the 'Datasets in this " +
			"run' table), and the assigned lists inherit their available list's namespace.</li>" +
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
			AvailableVariablesList
			{
				name:	"allVariablesA"
				//List-level dataset selection: an option carrying the dataset name
				//to select for this list (jaspSyntax gates the bound dropdown on it; desktop never
				//sees it). The assigned lists below inherit this list's namespace.
				dataSetSelectionOption: "dataSetA"
			}
			AssignedVariablesList
			{
				name:	"dependentA"
				title:	qsTr("Variables A")
				depends: "dataSetA"   //bind the dataset selection first, then the columns
			}
		}
	}

	Section {
		title: qsTr("Form B - variables from (hopefully) another dataset")

		VariablesForm
		{
			AvailableVariablesList
			{
				name:	"allVariablesB"
				dataSetSelectionOption: "dataSetB"
			}
			AssignedVariablesList
			{
				name:	"dependentB"
				title:	qsTr("Variables B")
				depends: "dataSetB"
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
