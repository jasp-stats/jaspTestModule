import QtQuick
import JASP.Controls
import "./common"

Form
{
	property var allowed: 		[ "ordinal" ]

	
	onAllowedChanged:	 {console.log("allowed is now " + allowed) }

	columns: 1

	VariablesForm
	{
		id: varForm
		AvailableVariablesList	{ name: "allVariablesList"										}
		AssignedVariablesList	
		{ 
			id: 				varS
			name: 				"varS"
			title: 				qsTr("With min max levels")

		
		}

		AssignedVariablesList	
		{
			id: 				varA
			name: 				"varA"
			title: 				qsTr("With allowed and min/max(num)levels")				; 
			allowedColumns: 	allowed	
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

	Section
	{
		title: "Visiblity of the Variables lists"

		ExplanationText
		{
			text:
				"Test visiblity of Variables lists inside of a Variables form.<br>
				Some of the Variables list can become invisible (due to some settings in the analysis). In this case, the place occupied of the invisble
				Variables lists can be left empty, or it can be used by the other Variables lists. This depends on the 'removeInvisibles' property.
				<ul>
					<li>Make the 'With allowed' Variables lists invisible: see that the visible Variables lists keeps their height.</li>
					<li>Toggle the removeInvisibles property (to set is to true): check that the visible Variables lists use all the space left</li>
					<li>Make the Variables lists visible again: see that the Variables lists adjust their heights to use all the space.</li>
				</ul>
				"
		}

		Group
		{
			columns: 1
			Button
			{
				text:		"Toggle visiblility of 'With allowed'"
				onClicked:	varA.visible = !varA.visible
			}
			Button
			{
				text: "Toggle removeInvisibles property"
				onClicked: varForm.removeInvisibles = !varForm.removeInvisibles
			}
			Text { text: "<b>Current removeInvisibles: " + (varForm.removeInvisibles ? "true" : "false") + "</b>" }
		}
	}

	Section
	{
		title: "Allowed"

		ExplanationText
		{
			text:	"This has been modified and this explanation could probably be more informative than this"
		}

		Group
		{
			columns: 2
			Group
			{
				columns: 1
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
				columns: 1

				Text { text: "<b>Current allowed: " + allowed.toString() + "</b>" }
				Button
				{
					text: 			"Toggle scale in allowed"
					onClicked:		allowed = toggleColList(allowed, "scale")
				}
				Button
				{
					text: 			"Toggle ordinal in allowed"
					onClicked:		allowed = toggleColList(allowed, "ordinal")
				}
				Button
				{
					text: 			"Toggle nominal in allowed"
					onClicked:		allowed = toggleColList(allowed, "nominal")
				}
			}
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
