import QtQuick
import QtQuick.Layouts
import JASP
import JASP.Controls
import "./common"

Form
{
	ExplanationText
	{
		text:
			"This analysis check Radio Buttons inside a form." +
			"<ul><li>Check also Radio Buttons outside a form: in Preferences/Interface, click the Dark Theme/Light Theme to check whether it still works. Check if theme sticks upon closing the menu.</li></ul>"
	}

	Section
	{
		title	: "Dynamic created Radio Buttons"
		columns	: 1

		ExplanationText
		{
			text:
				"Radio Button group can be created statically or dynamically, as their Radio Buttons can be also created statically and dynamically<br>" +
				"For each case, check:" +
				"<ul>" +
				"<li>The group should have one Radio Button checked. If there is a default Radio Button, this one should be checked</li>" +
				"<li>The value of the group should get the value of the Button checked.</li>" +
				"<li>Change the checked Radio Button, and check that the value of the group change also</li>" +
				"<li>Duplicate the analysis, and check that the same RadioButtons are checked, and that the groups have the same value</li>" +
				"</ul>"
		}

		RadioButtonGroup
		{
			name	: "staticGroupWithDynamicButtons"
			title	: "Static group with only dynamic buttons. <b>Value: " + value + "</b>"

			ComponentsList
			{
				name		: "buttons1"
				values		: ["button1", "button2"]
				preferredWidth: form.width - jaspTheme.groupContentPadding
				newItemValue : "Added Button "
				rowComponent: RadioButton { name: label; label: "Dynamic " + rowValue }
			}
		}

		RadioButtonGroup
		{
			name	: "staticGroupWithStaticAndDynamicButtons"
			title	: "Static group with static & dynamic buttons. <b>Value: " + value + "</b>"

			ComponentsList
			{
				name			: "buttons2"
				values			: ["button1", "button2"]
				addItemManually	: false
				addBorder		: false
				preferredWidth	: form.width - jaspTheme.groupContentPadding
				rowComponent	: RadioButton { value: label; label: "Dynamic " + rowValue }
			}

			RadioButton { value: label; label: "Static button" }
		}

		ComponentsList
		{
			name			: "dynamicGroupWithStaticButtons"
			title			: "Dynamic group with static buttons"
			values			: ["grouo1", "group2"]
			addItemManually	: false
			rowComponent	: RadioButtonGroup
			{
				property int index: rowIndex
				name		: "Dynamic " + rowValue
				title		: name + ". <b>Value: " + value + "</b>"

				RadioButton { value: label; label: group.name + " Button1 " + (group.index == 0 ? "(default)" : ""); checked: group.index == 0 }
				RadioButton { value: label; label: group.name + " Button2 " + (group.index == 1 ? "(default)" : ""); checked: group.index == 1 }
			}
		}

		ComponentsList
		{
			name			: "dynamicGroupWithDynamicButtons"
			title			: "Dynamic group with dynamic buttons"
			values			: ["grouo1", "group2"]
			addItemManually	: false
			rowComponent	:  RadioButtonGroup
			{
				name	: "Dynamic " + rowValue
				title	: name + ". <b>Value: " + value + "</b>"

				ComponentsList
				{
					values			: ["button1", "button2"]
					name			: "dynamicbuttons " + rowValue
					preferredWidth	: form.width - jaspTheme.groupContentPadding
					addItemManually	: false
					addBorder		: false
					rowComponent	: RadioButton { name: rowValue; label: group.name + " " + rowValue }
				}
			}
		}
	}

	Section
	{
		title	: "Dynamic created Radio Buttons from dataset"
		enabled	: available.count > 0 || assigned.count > 0.
		VariablesForm
		{
			AvailableVariablesList { id: available; name: "available" }
			AssignedVariablesList { id: assigned; name: "assigned"; }
		}

		ExplanationText
		{
			text:
				"Here a ComponentsList creates a RadioButtonGrouo per available variable.<br>" +
				"Each RadioButtonGroup has a single 'Static RadioButton' and dynamicly created RadioButtons (via a sub ComponentsList) for each assigned variable" +
				"<ul>" +
				"<li>Check that a RadioButtonGroup is created per available variable, and that a RadioButton is created per assigned variable</li>" +
				"<li>Check that each RadioButtonGroup has a checked RadioButton and that the RadioButtonGroup gets the right value</li>" +
				"<li>Check that by clicking on the RadioButtons, the RadioButtonGroup gets the right value</li>"  +
				"<li>If Radio Buttons can be removed, remove the checked one, and check that another becomes checked.</li>" +
				"<li>Add the removed button again (by adding again the column to the assigned variables list), and check that this Radio Button is checked again (and that the other Radio Buttons are unchecked).</li>" +
				"<li>Duplicate the analysis: check that the same radio buttons are displayed, and the same ones are checked</li>" +
				"</ul>"
		}

		ComponentsList
		{
			name	: "dynamic"
			source	: "available"

			rowComponent: RadioButtonGroup
			{
				name	: "group"
				title	: "RadioButtonGroup for " + rowValue + ", Value: " + value

				RadioButton
				{
					name	: "Static RadioButton"
					label	: name
				}

				ComponentsList
				{
					id					: itemCustomContrasts
					name				: "customContrasts"
					anchors.topMargin	: jaspTheme.rowSpacing
					source				: "assigned"
					preferredWidth		: form.width
					addBorder			: false

					rowComponent:
					RadioButton
					{
						name: "Dynamic RadioButton " + rowValue
						label: name
					}
				}
			}
		}

	}

	Section
	{
		title: "Test Programatically click and checked"


		ExplanationText
		{
			text:
				"RadioButtons can be set directly via JavaScript: either by calling the click() function, or by setting the checked property<br>" +
				"Hier the buttons set the value of the 'First Group', either with click() or with the 'checked' property.<br>" +
				"The 'Second Group' gets its value by binding the checked property to the corresponding one in the 'First Group.<br>" +
				"Remark: Radio Buttons have here the same names (in different group). That should not lead to an error" +
				"<ul>" +
				"<li>Click on both buttons below: check in the 'First Group' that the right Radio Button is checked, and that the right value is set." +
				"Check also in the 'Second Group' that the corresponding Radio Button is checked and that the group gets the right value</li>" +
				"<li>Click on a 'Second Group' Radio Button: check that the 'First Group' is not updated, but that the Second Group gets a new value</li>" +
				"<li>Click on a 'First Group' Radio Button: check in the 'Second Group' that the corresponding Radio Button is checked. Check also that the values of both groups are updated</li>" +
				"<li>Click on a 'Second Group' Radio Button so that both groups have different values. Duplicate the analysis: check that the right buttons are checked, and the groups have the right values</li>" +
				"</ul>"
		}

		Column
		{
			Layout.columnSpan: 2
			Button
			{
				label		: "Use click() to set 'one'"
				onClicked	: one.click()
			}
			Button
			{
				label		: "Use checked to set 'two'"
				onClicked	: two.checked = true
			}
		}

		RadioButtonGroup
		{
			id			: test
			title		: "First Group: " + value
			name		: "firstGroup"

			RadioButton { name: "one"; label: "one"; id: one }
			RadioButton { name: "two"; label: "two"; id: two }
			RadioButton { name: "three"; label: "three"; id: three }
		}

		RadioButtonGroup
		{
			title		: "Second Group: " + value
			name		: "secondGroup"

			RadioButton { name: "one"; label: "one"; checked: one.checked }
			RadioButton { name: "two"; label: "two"; checked: two.checked }
			RadioButton { name: "three"; label: "three"; checked: three.checked }
		}
	}

}
