import QtQuick
import QtQuick.Layouts
import JASP
import JASP.Controls

Form
{
	columns: 1

	VariablesForm
	{
		AvailableVariablesList { name: "available" }
		AssignedVariablesList { name: "assigned" }
	}

	ComponentsList
	{
		id					: itemCustomContrasts
		name				: "customContrasts"
		anchors.topMargin	: jaspTheme.rowSpacing
		source				: "assigned"

		rowComponent: RadioButton
		{
			name: "test"
			label: "test" + rowValue
		}

	}


	RadioButtonGroup
	{
		name: "staticRadioButtons"
		title: "Static Radio Buttons"

		RadioButton
		{
			name: "one"
			label: "One"
		}
		RadioButton
		{
			name: "two"
			label: "Two"
		}

		Group
		{
			RadioButton
			{
				name: "three"
				label: "Three"
			}
		}
	}
}
