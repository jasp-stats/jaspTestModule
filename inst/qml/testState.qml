import QtQuick 			2.8
import QtQuick.Layouts 	1.3
import JASP.Controls 	1.0
import JASP.Widgets 	1.0

Form
{
	TextField
	{
		label:			"Save me!"
		name:			"saveMe"
		value:			"Blablabla"
	}

	CheckBox
	{
		label:		"A checkbox!"
		name: 		"checkbox_0"
		checked: 	false
	}

	CheckBox
	{
		label:		"Another checkbox!"
		name: 		"checkbox_1"
		checked: 	false
	}


	VariablesForm
	{
		AvailableVariablesList	{ name: "allVariablesList1"													}
		AssignedVariablesList	{ name: "variables";		title: "All Variables in data";					}
	}

	VariablesForm
	{
		AvailableVariablesList	{ name: "allVariablesList2";												}
		AssignedVariablesList	{ name: "variablesForState"; title: "State must contain"					}
	}

	TabView
	{
		name:				"tabview"
		maximumItems:		10
		newItemName:		qsTr("Tab 1")
		optionKey:			"tabviewOptions"

		content: Group
		{
			CheckBox
			{
				label:		"Another checkbox!"
				name: 		"checkbox_2"
				checked: 	false
			}

			VariablesForm
			{
				AvailableVariablesList	{ name: "allVariablesListTab1"													}
				AssignedVariablesList	{ name: "variablesTab1";		title: "All Variables in data";					}
			}

			VariablesForm
			{
				AvailableVariablesList	{ name: "allVariablesListTab2";												}
				AssignedVariablesList	{ name: "variablesForStateTab2"; title: "State must contain"					}
			}
		}
	}
}
