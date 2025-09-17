import QtQuick
import JASP.Controls
import "./common"

Form
{
	property var allowed: 		[ "scale" ]

	columns: 1

	ExplanationText
	{
		text:
			"Test visiblity of Variables lists inside of a Variables form.<br>
			Some of the Variables list can become invisible (due to some settings in the analysis). In this case, the place occupied of the invisble
			Variables lists can be left empty, or it can be used by the other Variables lists. This depends on the 'removeInvisibles' property.
			<ul>
				<li>Make the 'Toggling Variables lists invisible: see that the visible Variables lists keeps their height.</li>
				<li>Toggle the removeInvisibles property (to set is to true): check that the visible Variables lists use all the space left</li>
				<li>Make the Variables lists visible again: see that the Variables lists adjust their heights to use all the space.</li>
			</ul>
			Add constraints and check that the variables fulfill the constraints or give an error, even if a variable is already in the VariablesList.<br>
			Change the allowed types, and check that the types of variables that are already in the VariablesList get the right type.<br>
			Change the type of the variable directly in the VariablesList: check that only the allowed types are proposed.
			"
	}


	onAllowedChanged:	 {console.log("allowed is now " + allowed) }

	VariablesForm
	{
		id: varForm
		AvailableVariablesList	{ name: "allVariablesList"										}
		AssignedVariablesList
		{
			id: 				varS
			name: 				"varS"
			title: 				qsTr("Variables")
			allowedColumns: 	allowed

			minNumericLevels:	minNumLevel.value
			maxNumericLevels:	maxNumLevel.value
			minLevels:			minLevel.value
			maxLevels:			maxLevel.value
			allowTypeChange:	true

			onLevelsChanged:	messages.log("varS Levels is now: " + levels)
		}

		AssignedVariablesList
		{
			id: 				varToggle
			name: 				"varToggle"
			title: 				qsTr("Toggling Variables List")				;
			minNumericLevels:	minNumLevel.value
			maxNumericLevels:	maxNumLevel.value
			minLevels:			minLevel.value
			maxLevels:			maxLevel.value

		}

	}

	function toggleColList(list, toggleThis)
	{
		console.log("yo!")
		console.log(list)
		console.log(toggleThis)

		if(list.indexOf(toggleThis) > -1) 	list.splice(list.indexOf(toggleThis), 1)
		else								list.push(toggleThis);


		console.log(list)

		return list;
	}



	Group
	{
		columns: 2
		title: "<b>Toggling Variables List: " + (varToggle.visible ? " visible " : ("hidden and " + (varForm.removeInvisibles ? "removed": "not removed"))) + "</b>"
		CheckBox
		{
			name:		"toggleVisibility"
			label:		"Toggle visiblility"
			onClicked:	varToggle.visible = !varToggle.visible
			checked:	varToggle.visible
		}
		CheckBox
		{
			name:		"toggleRemoveInvisibles"
			label:		"Toggle removeInvisibles property"
			onClicked:	varForm.removeInvisibles = !varForm.removeInvisibles
			checked:	varForm.removeInvisibles
		}
	}

	Group
	{
		title: "<b>Constraints</b>"
		columns: 2
		IntegerField
		{
			id:				minNumLevel
			name:			"minNumLevel"
			text: 			"How many numeric level minimum"
			defaultValue:	-1
			min:			-1
		}

		IntegerField
		{
			id:				maxNumLevel
			name:			"maxNumLevel"
			text: 			"How many numeric level maximum"
			defaultValue:	-1
			min:			-1
		}

		IntegerField
		{
			id:				minLevel
			name:			"minLevel"
			text: 			"How many level minimum"
			defaultValue:	-1
			min:			-1
		}

		IntegerField
		{
			id:				maxLevel
			name:			"maxLevel"
			text: 			"How many level maximum"
			defaultValue:	-1
			min:			-1
		}
	}

	Group
	{
		columns: 3

		title: "<b>Allowed types: " + allowed.toString() + "</b>"
		CheckBox
		{
			name:			"scale"
			label: 			"Toggle scale"
			onClicked:		allowed = toggleColList(allowed, "scale")
			checked:		true
		}
		CheckBox
		{
			name:			"ordinal"
			label: 			"Toggle ordinal"
			onClicked:		allowed = toggleColList(allowed, "ordinal")
		}
		CheckBox
		{
			name:			"nominal"
			label: 			"Toggle nominal"
			onClicked:		allowed = toggleColList(allowed, "nominal")
		}
	}

	Section
	{
		title: "Row controls"

		ExplanationText
		{
			text:
			"
			This tests how the row controls can be set visibled and/or enabled.<br>
			Add some variables, and add or remoce a CheckBox or a DropDown per variable.<br>
			Moreover you can set the CheckBox enabled by allowing only variables with some type.
			"
		}

		VariablesForm
		{
			AvailableVariablesList	{ name: "allVariablesList2"	}
			AssignedVariablesList
			{
				id:		variablesWithControls
				name:	"variablesWithControls"
				title:	"Variables With Controls"
				rowComponent:  Row
				{
					CheckBox
					{
						name: "aCheckBox"
						visible: addCheckBox.checked
						enabled: setType.value == -1 ? true : variablesWithControls.getVariableType(rowValue) == setType.value
					}
					DropDown { name: "aDropDown"; visible: addDropDown.checked; values: ["one", "two"] }
				}
			}

		}

		CheckBox
		{
			id: addCheckBox; name: "addCheckBox"; label: "Add CheckBox"
			DropDown
			{
				id: setType
				name: "setType"
				label: "Enable CheckBox only for type: "
				values:
				[
					{label: "all", value: -1},
					{label: "scale", value: columnTypeScale},
					{label: "nominal", value: columnTypeNominal}
				]
			}
		}
		CheckBox { id: addDropDown; name: "addDropDown"; label: "Add DropDown" }


	}


}
