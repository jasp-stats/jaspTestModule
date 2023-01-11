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



	RadioButtonGroup
	{
		name: "group"
		title: "Dynamic Radio Buttons"

		RadioButton
		{
			name: "direct"
			visible: true
			label: name
		}

		RadioButton
		{
			name: "direct2"
			visible: true
			label: name
		}

		Rectangle
		{
			width: 200
		}

		ComponentsList
		{
			id					: itemCustomContrasts
			name				: "customContrasts"
			anchors.topMargin	: jaspTheme.rowSpacing
			source				: "available"

			rowComponent:
			RadioButton
			{
				name: "indirect " + rowValue
				visible: true
				label: name
			}
		}
	}

	RadioButtonGroup
	{
		name: "group2"
		title: "Dynamic Radio Buttons"

		Rectangle
		{
			width: 200
		}

		ComponentsList
		{
			name				: "aaaa"
			anchors.topMargin	: jaspTheme.rowSpacing
			source				: "assigned"

			rowComponent:
			RadioButton
			{
				name: "indirect2 " + rowValue
				visible: true
				label: name
			}
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
			checked: true
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


	RadioButtonGroup
	{
		name: "nameChangeRadioButtons"
		title: "Name Change Radio Buttons"

		RadioButton
		{
			name: nameField.value + "1"
			label: nameField.value + "1"
		}
		RadioButton
		{
			name: nameField.value + "2"
			label: nameField.value + "2"
		}

		Group
		{
			RadioButton
			{
				name: nameField.value + "3"
				label: nameField.value + "3"
			}
		}
	}

	TextField
	{
		id: nameField
	}
}
