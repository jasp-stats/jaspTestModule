import QtQuick
import JASP.Controls

Form 
{
	columns: 1
	VariablesForm
	{
		AvailableVariablesList	{ name: "available" }
		AssignedVariablesList	{ name: "assignedVariables"; id: assignedVariables	}
	}

	DropDown
	{
		name: "drop"
		values: ["none", "one", "two", "three"]
		value: radio.value
	}

	CheckBox
	{
		id:	check
		name: "check"
		label: "check"
		checked: assignedVariables.count > 0
	}

	RadioButtonGroup
	{
		id: radio
		name: "radio"
		title: "radio"

		RadioButton { name: "one"; label: "one"; checked: !check.checked }
		RadioButton { name: "two"; label: "two"; checked: check.checked }
		RadioButton { name: "three"; label: "three" }
	}
}

