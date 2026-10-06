import QtQuick
import JASP.Controls
import "./common"

Form
{
	columns: 1

	ExplanationText
	{
		text:
			"Test the multi-dataset awareness of VariablesForm: the dataset/filter selection at the top " +
			"(only live for multiDataSetAware analyses) plus the per-dataset routing in the results.<br>" +
			"<ul>" +
			"<li>Open a second dataset (e.g. add another CSV) so the selection has something to choose from.</li>" +
			"<li>Drag variables from <i>different</i> datasets into the list: the results table should route " +
			"each one to its own dataset (id, title, column).</li>" +
			"<li>Pick another dataset/filter in the selection: only columns of that dataset should remain " +
			"selectable for new drags and the run should recompute.</li>" +
			"<li>show .meta: the provenance stamps (dataSetId/filterId) on the bound options.</li>" +
			"<li>guard demo: readDataSet() must hard-stop inside an aware run.</li>" +
			"<li>Save the analysis to a .jasp and reopen it: the dataset routing must survive the round trip.</li>" +
			"</ul>"
	}

	VariablesForm
	{
		dataSetSelection: true

		AvailableVariablesList	{ name: "allVariables" }
		AssignedVariablesList
		{
			name:	"dependent"
			title:	qsTr("Variables (from any dataset)")
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
