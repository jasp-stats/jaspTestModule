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
			"<ul><li>Check also Radio Buttons outside a form: in Preferences/Interface, click the Dark Theme/Light Theme to check whether it stll works.</li></ul>"
	}

	Section
	{
		title: "Dynamic created Radio Buttons (needs dataset)"
		enabled: available.count > 0 || assigned.count > 0.
		VariablesForm
		{
			AvailableVariablesList { id: available; name: "available" }
			AssignedVariablesList { id: assigned; name: "assigned"; }
		}

		ExplanationText
		{
			text:
				"Dynamic created Radio Buttons: a ComponentsList creates a RadioButtonGrouo per available variable.<br>" +
				"Each RadioButtonGroup has a single 'Static RadioButton' and dynamicly created RadioButtons created by sub ComponentsList: one RadioButton is created per assigned variable" +
				"<ul>" +
				"<li>Check that a RadioButtonGroup is created per available variable, and that a RadioButton is created per assigned variable</li>" +
				"<li>Check that by clicking on the RadioButtons, the RadioButtonGroup gets the right value</li>"  +
				"<li>Duplicate the analysis: check that the same radio buttons are displayed, and the same ones are checked</li>" +
				"</ul>"
		}

		ComponentsList
		{
			name: "dynamic"
			source: "available"

			rowComponent: RadioButtonGroup
			{
				name: "group"
				title: "RadioButtonGroup for " + rowValue + ", Value: " + value

				RadioButton
				{
					name: "Static RadioButton"
					label: name
				}

				ComponentsList
				{
					id					: itemCustomContrasts
					name				: "customContrasts"
					anchors.topMargin	: jaspTheme.rowSpacing
					source				: "assigned"
					width				: form.width
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
		title: "Test Prgramatically click and checked"


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
		Button
		{
			label: "Use click() to set 'one'"
			onClicked: one.click()
		}
		Button
		{
			label: "Use checked to set 'two'"
			onClicked: two.checked = true
		}

		RadioButtonGroup
		{
			id: test
			title: "First Group: " + value
			name: "firstGroup"

			RadioButton { name: "one"; label: "one"; id: one }
			RadioButton { name: "two"; label: "two"; id: two }
			RadioButton { name: "three"; label: "three"; id: three }
		}

		RadioButtonGroup
		{
			title: "Second Group: " + value
			name: "secondGroup"

			RadioButton { name: "one"; label: "one"; checked: one.checked }
			RadioButton { name: "two"; label: "two"; checked: two.checked }
			RadioButton { name: "three"; label: "three"; checked: three.checked }
		}
	}

}
