import QtQuick
import JASP.Controls
import JASP.Widgets

Form
{
	property var suggested: 	["scale"]
	property var allowed: 		["ordinal"]
	
	onSuggestedChanged:	 {console.log("suggested is now " + suggested) }
	onAllowedChanged:	 {console.log("allowed is now " + allowed) }

	columns: 1
	VariablesForm
	{
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

	Button
	{
		text: 			"toggle scale in suggested"
		onClicked:		suggested = toggleColList(suggested, "scale")
	}
	Button
	{
		text: 			"toggle ordinal in suggested"
		onClicked:		suggested = toggleColList(suggested, "ordinal")
	}
	Button
	{
		text: 			"toggle nominal in suggested"
		onClicked:		suggested = toggleColList(suggested, "nominal")
	}
	Button
	{
		text: 			"toggle nominalText in suggested"
		onClicked:		suggested = toggleColList(suggested, "nominalText")
	}

	Button
	{
		text: 			"toggle scale in allowed"
		onClicked:		allowed = toggleColList(allowed, "scale")
	}
	Button
	{
		text: 			"toggle ordinal in allowed"
		onClicked:		allowed = toggleColList(allowed, "ordinal")
	}
	Button
	{
		text: 			"toggle nominal in allowed"
		onClicked:		allowed = toggleColList(allowed, "nominal")
	}
	Button
	{
		text: 			"toggle nominalText in allowed"
		onClicked:		allowed = toggleColList(allowed, "nominalText")
	}

}