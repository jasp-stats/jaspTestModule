import QtQuick
import QtQuick.Layouts
import JASP
import JASP.Controls
import "./common"

Form
{
	columns: 1
	ExplanationText
	{
		text: "Test with your mouse if the tooltip appears for the controls having one"
	}

	Group
	{
		title: "<b>CheckBoxes</b>"
		columns: 2

		CheckBox
		{
			toolTip: "Great tooltip"
			name: "checkBoxWithTooltip"
			label: "CheckBox with tooltip: " + (hovered ? "Hovered" : "")
		}

		CheckBox
		{
			info: "Great info"
			name: "checkBoxWithInfo"
			label: "CheckBox with info: " + (hovered ? "Hovered" : "")
		}

		CheckBox
		{
			info: "Great info"
			toolTip: "Great tooltip"
			name: "checkBoxWithInfoAndTooltip"
			label: "CheckBox with info and tooltip: tooltip should overwrite info"
		}


		CheckBox
		{
			name: "checkBoxWithoutTootip"
			label: "CheckBox without tooltip: " + (hovered ? "Hovered" : "")
		}

		CheckBox
		{
			Layout.columnSpan: 2
			name: "checkBoxWithSubCheckBox"
			label: "CheckBox with sub CheckBox"
			info: "Info for checkbox with sub checkboxes"

			CheckBox
			{
				name: "subCheckBoxWithInfo"
				label: "Sub CheckBox with info"
				info: "Info for Sub CheckBox"
			}

			CheckBox
			{
				name: "subCheckBoxWithoutInfo"
				label: "Sub CheckBox without info"
			}
		}
	}

	Group
	{
		title: "<b>Radio Buttons</b>"
		columns: 2

		RadioButtonGroup
		{
			info: "Info for the RadioButton group"
			name: "radioButtonsWithInfo"
			title: "Radio button group with info"
			RadioButton
			{
				name: "radioWithInfo"
				label: "RadioButton with info"
				info: "Info just for this RadioButton"
			}

			RadioButton
			{
				name: "radioWithoutInfo"
				label: "RadioButton without info"
			}
		}

		RadioButtonGroup
		{
			name: "radioButtons"
			title: "Radio button group without info"
			RadioButton
			{
				name: "radioWithInfo"
				label: "RadioButton with info"
				info: "Info just for this RadioButton"
			}

			RadioButton
			{
				name: "radioWithoutInfo"
				label: "RadioButton without info"
			}
		}

		RadioButtonGroup
		{
			Layout.columnSpan: 2
			info: "Info for the Row RadioButton group"
			name: "rowRadioButtonsWithInfo"
			title: "Radio buttons in a row with info: "
			radioButtonsOnSameRow: true

			RadioButton
			{
				name: "radioWithInfo"
				label: "RadioButton with info"
				info: "Info just for this RadioButton"
			}

			RadioButton
			{
				name: "radioWithoutInfo"
				label: "RadioButton without info"
			}
		}

		RadioButtonGroup
		{
			Layout.columnSpan: 2
			name: "rowRadioButtons"
			title: "Radio buttons in a row without info: "
			radioButtonsOnSameRow: true

			RadioButton
			{
				name: "radioWithInfo"
				label: "RadioButton with info"
				info: "Info just for this RadioButton"
			}

			RadioButton
			{
				name: "radioWithoutInfo"
				label: "RadioButton without info"
			}
		}


		Group
		{
			Layout.columnSpan: 2

			title: "RadioButtonGroup without label but with info"

			RadioButtonGroup
			{
				name: "rowRadioButtonsWithoutLabelWithInfo"
				radioButtonsOnSameRow: true
				info: "No label but an info"

				RadioButton
				{
					name: "one"
					label: "RadioButton One without info"
				}

				RadioButton
				{
					name: "two"
					label: "RadioButton Two without info"
				}
			}
		}

		Group
		{
			Layout.columnSpan: 2

			title: "RadioButtonGroup without label and without info"

			RadioButtonGroup
			{
				name: "rowRadioButtonsWithoutLabelWithoutInfo"
				radioButtonsOnSameRow: true

				RadioButton
				{
					name: "one"
					label: "RadioButton One with info"
					info: label
				}

				RadioButton
				{
					name: "two"
					label: "RadioButton Two without info"
				}
			}
		}

		Group
		{
			title: "RadioButtons coupled to RadioButtonGroup using the `group` property"
			Layout.columnSpan: 2
			columns: 2

			RadioButtonGroup
			{
				id: radioButtonGroup1
				name: "RadioButtonGroup1"
			}
			RadioButtonGroup
			{
				id: radioButtonGroup2
				name: "RadioButtonGroup2"
			}

			RadioButton
			{
				group: radioButtonGroup1
				name: "group1RadioButton1"
				label: "RadioButton1 for Group1 with info"
				info: label
			}
			RadioButton
			{
				group: radioButtonGroup1
				name: "group1RadioButton2"
				label: "RadioButton2 for Group1"
			}
			RadioButton
			{
				group: radioButtonGroup2
				name: "group2RadioButton1"
				label: "RadioButton1 for Group2"
			}
			RadioButton
			{
				group: radioButtonGroup2
				name: "group2RadioButton2"
				label: "RadioButton2 for Group2 with info"
				info: label
			}


		}
	}

	Group
	{
		title: "<b>Integer fields</b>"
		columns: 2

		IntegerField
		{
			name: "IntegerWithInfo"
			label: "Field with info"
			info: "Field with info"
		}

		IntegerField
		{
			name: "IntegerWithTooLongValue"
			label: "Field without info and too long value"
			value: 1234567
		}

		IntegerField
		{
			name: "IntegerWithTooLongValueAndInfo"
			label: "Field with info and too long value"
			value: 1234567
			info: "Field with info and too long value"
		}
	}

	Group
	{
		title: "<b>DropDowns</b>"

		DropDown
		{
			name: "dropdownWithInfo"
			label: "Dropdown with info"
			values: ["one", "two", "three"]
			info: "Dropdown with info"
		}

		DropDown
		{
			name: "dropdownWithExtraInfo"
			label: "Dropdown with info and extra info for value 'One' and 'Two'"
			values:
			[
				{label: "One", info: "This is one", value: "one"},
				{label: "Two", value: "two"},
				{label: "Three", info: "This is three"}
			]
			info: "Dropdown with info"
		}

		DropDown
		{
			name: "dropDownLabelAbove"
			setLabelAbove: true
			label: "Dropdown with info and label above"
			values: ["one", "two", "three"]
			info: label
		}

		DropDown
		{
			name: "dropDownLabelAboveWithExtraInfo"
			setLabelAbove: true
			label: "Dropdown with extra info for value 'Two' and label above"
			info: label
			values:
			[
				{label: "One", value: "one"},
				{label: "Two", value: "two", info: "Extra info for Two"},
				{label: "Three", value: "three"}
			]
		}

	}

}
