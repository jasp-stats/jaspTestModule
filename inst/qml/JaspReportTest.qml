import JASP.Controls 	1.0
import JASP.Widgets 	1.0

Form 
{
	columns:	1
	VariablesForm
	{
		AvailableVariablesList	{ name: "allVariablesList"								}
		AssignedVariablesList	{ name: "selectedVariable";			title: qsTr("Report on this");		singleVariable: true; }
	}

    Text
    {
        text:   "'column' is available in the below formula and when the formula returns true anywhere it will \"report\" it."
    }

    TextField
    {
        name:   "reportMe"
        label:  "A formula:"
    }
}