import QtQuick
import JASP.Controls
import "./common"

Form
{
	columns: 1

	ExplanationText
	{
		text: "Change the Text Format, and the lable field, and check that all control labels are changed appropriately"
	}

	DropDown
	{
		id: textFormat
		name: "textFormat"
		label: "Text Format"
		values: [
			{"label": "Auto",		"value": Text.AutoText		},
			{"label": "Plain",		"value": Text.PlainText		},
			{"label": "Rich",		"value": Text.RichText		},
			{"label": "Styled",		"value": Text.StyledText	},
			{"label": "Markdown",	"value": Text.MarkdownText	}
		]
	}

	TextField
	{
		id: labelText
		name: "labelText"
		label: "Label"
		value: "<b>Test</b> H\u2080! T<sub>test</sub>"
	}

	CheckBox
	{
		id:					checkbox
		name:				"checkbox"
		label:				labelText.value
		textFormat:			textFormat.currentValue
	}

	DropDown
	{
		id: 				dropdown
		name: 				"dropDown"
		label: 				labelText.value
		textFormat:			textFormat.currentValue
		values: 					[
			{ label: qsTr("High"),		value: "high"	},
			{ label: qsTr("Medium"), 	value: "medium"	},
			{ label: qsTr("Low"), 		value: "low"	},
			{ label: qsTr("Manual"), 	value: "custom"	}
		]
	}

	RadioButtonGroup
	{
		name:			"radiobuttongroup"
		title:			labelText.value
		textFormat:		textFormat.currentValue

		RadioButton	{	label:	"text button uno";			name: "rButton1"	}
		RadioButton	{	label:	labelText.value;				name: "rButton2"; textFormat:		textFormat.currentValue	}
	}

	Section
	{
		title:			labelText.value
		textFormat:		textFormat.currentValue

		Group
		{
			title:			labelText.value
			textFormat:		textFormat.currentValue

			DoubleField
			{
				name:			"doubleFieldWithAfterLabel"
				label:			labelText.value
				afterLabel:		labelText.value
				textFormat:		textFormat.currentValue

			}

			IntegerField
			{
				name:			"integerFieldWithAfterLabel"
				label:			labelText.value
				afterLabel:		labelText.value
				textFormat:		textFormat.currentValue
			}
		}
	}

	VariablesForm
	{
		AvailableVariablesList			{ name: "allVariablesList"	}
		AssignedVariablesList			{ name: "assigned"; title: labelText.value; textFormat:	textFormat.currentValue	}
	}
}
