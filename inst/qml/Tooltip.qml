import QtQuick
import JASP
import JASP.Controls
import "./common"

Form
{
	ExplanationText
	{
		text: "Test with your mouse if the tooltip appears for the controls having one"
	}

	CheckBox
	{
		toolTip: "Great tooltip"
		name: "checkBoxWithTooltip"
		label: "CheckBox with tooltip: " + (hovered ? "Hovered" : "")
	}

	CheckBox
	{
		name: "checkBoxWithoutTooltip"
		label: "CheckBox without tooltip: " + (hovered ? "Hovered" : "")
	}


	RadioButtonGroup
	{
		toolTip: "Tooltip for the RadoButton group"
		name: "radioButtonsWithTooltip"
		title: "Radio button group with tooltip"
		RadioButton
		{
			name: "radioWithTooltip"
			label: "RadioButton with tooltip"
			toolTip: "Tooltip for just this RadioButton"
		}

		RadioButton
		{
			name: "radioWithoutTooltip"
			label: "RadioButton without tooltip"
		}
	}

	RadioButtonGroup
	{
		name: "radioButtons"
		title: "Radio button group without tooltip"
		RadioButton
		{
			name: "radioWithTooltip"
			label: "RadioButton with tooltip"
			toolTip: "Tooltip for just this RadioButton"
		}

		RadioButton
		{
			name: "radioWithoutTooltip"
			label: "RadioButton without tooltip"
		}
	}

	IntegerField
	{
		name: "IntegerWithTooltip"
		label: "Field with tooltip"
		toolTip: "Field with tooltip"
	}

	DropDown
	{
		name: "dropdownWithTooltip"
		label: "Dropdown with tooltip"
		values: ["one", "two"]
		toolTip: "Dropdown with tooltip"
	}

}
