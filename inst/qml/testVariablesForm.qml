import QtQuick
import JASP.Controls
import "./common"

Form
{
	property var suggested: 	["ordinal"]
	property var allowed: 		[]
	
	onSuggestedChanged:	 {console.log("suggested is now " + suggested) }
	onAllowedChanged:	 {console.log("allowed is now " + allowed) }

	columns: 1

	VariablesForm
	{
		id: varForm
		AvailableVariablesList	{ name: "allVariablesList"										}
		AssignedVariablesList	{ name: "varS";			title: qsTr("With suggest")				; id: varS ;	suggestedColumns:	suggested							}
		AssignedVariablesList	{ name: "varA";			title: qsTr("With allowed")				; id: varA ;									allowedColumns: allowed	}
		AssignedVariablesList	{ name: "varSA";		title: qsTr("With suggest and allow")	; id: varSA;	suggestedColumns:	suggested;	allowedColumns:	allowed	}
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
					<li>Make the 'With suggest' and 'With allowed' Variables lists invisible: see that the visible Variables lists keeps their height.</li>
					<li>Toggle the removeInvisibles property (to set is to true): check that the visible Variables lists use all the space left</li>
					<li>Make the Variables lists visible again: see that the Variables lists adjust their heights to use all the space.</li>
				</ul>
				"
		}

		Group
		{
			columns: 2
			Button
			{
				text:		"Toggle visiblility of 'With suggest'"
				onClicked:	varS.visible = !varS.visible
			}
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
		title: "Suggested vs allowed"

		ExplanationText
		{
			text:
			"2 properties set which variable types are allowed in a Variables list: suggested & allowed.<br>
			The allowed property is strict: only the specisifed types are allowed.<br>
			The suggested property is less strict:
			<ul>
				<li>if suggested contains the scale type, then nomincal & ordinal types are then also allowed.</li>
				<li>if suggestedType contains the nomincal type, then nominalText & ordinal types are also allowed.</li>
			</ul>
			For the tests:
			<ul>
				<li>Check whether the Variables list allows the right variables</li>
				<li>Check when a Variables list allowed type changes, that the variables that are not anymore allowed are automatically removed from the list.</li>
			</ul>
			"
		}

		Group
		{
			columns: 2

			Text { text: "<b>Current suggested: " + suggested.toString() + "</b>"}
			Text { text: "<b>Current sllowed: " + allowed.toString() + "</b>" }
			Button
			{
				text: 			"Toggle scale in suggested"
				onClicked:		suggested = toggleColList(suggested, "scale")
			}
			Button
			{
				text: 			"Toggle scale in allowed"
				onClicked:		allowed = toggleColList(allowed, "scale")
			}
			Button
			{
				text: 			"Toggle ordinal in suggested"
				onClicked:		suggested = toggleColList(suggested, "ordinal")
			}
			Button
			{
				text: 			"Toggle ordinal in allowed"
				onClicked:		allowed = toggleColList(allowed, "ordinal")
			}
			Button
			{
				text: 			"Toggle nominal in suggested"
				onClicked:		suggested = toggleColList(suggested, "nominal")
			}
			Button
			{
				text: 			"Toggle nominal in allowed"
				onClicked:		allowed = toggleColList(allowed, "nominal")
			}
			Button
			{
				text: 			"Toggle nominalText in suggested"
				onClicked:		suggested = toggleColList(suggested, "nominalText")
			}

			Button
			{
				text: 			"Toggle nominalText in allowed"
				onClicked:		allowed = toggleColList(allowed, "nominalText")
			}
		}
	}
}
