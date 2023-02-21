import QtQuick
import JASP.Controls
import QtQuick.Layouts
import "./common"

Form 
{
	ExplanationText
	{
		text:
			"QML VariablesList and DropDown can have R Sources. An R Source is a R list object created in the analysis (with createJaspQmlSource function), which is transformed in a JSON string.<br>" +
			"A QML Item can refer to ab R Source by invoking its ID, then it gets the top elements of the JSON. Sub-elements can be obtained by calling the R Source with its ID followed by the path to the sub-elements (separated by '.')<br>" +
			"Here the R source looks like this:<br>" +
			"[<br>" +
			"&nbsp;&nbsp;&nbsp;top1: [elt1, elt2]<br>" +
			"&nbsp;&nbsp;&nbsp;top2: [{subTopA: [A, B]}, {subTopB: [C, D, E]}]<br>" +
			"]<br><br>" +
			"The Available list has for sources: the static values 'one' and 'two', the R source with path top2.subTop1 and the R source with path top2.subtop2<br>" +
			"The DropDown has for source the items in the Available list, but the ones in the R source top2.subTopA are discarded<br>" +
			"The ComponentsList has for sources the R source (without path), and as elements another ComponentsList of CheckBoxes. This last ComponentsList has 2 sources: the R source with path the current value, and the Assigned items<br><br>" +
			"Check: " +
			"<ul>" +
			"<li>Available list has for items: 'one', 'two', 'A', 'B', 'C', 'D', 'E', 'F'</li>" +
			"<li>Dropdown has for items: 'one', 'two', 'C', 'D', 'E'</li>" +
			"<li>ComponentsList has 2 items 'top1' & 'top2', and as subitems the checkboxes for 'elt1' & 'elt2', and respectively 'subTopA' & 'subTopB</li>" +
			"<li>Move some items from Available to the Assigned list:" +
			"   <ul>" +
			"	<li>Check that the values of the DropDown changes as expected</li>" +
			"	<li>Check that if the current value of the dropdown is removed from the Available items, then then Dropdown gets a new value</li>" +
			"	<li>In the ComponentsList, check that there are as many CheckBoxes added as the number of items in the Assigned list</li>" +
			"	</uL>" +
			"</ul>"
	}

	columns: 1
	VariablesForm
	{
		AvailableVariablesList
		{
			title: "Available items"
			name: "fromR"
			source:
			[
				{ values: ["one", "two"] },
				{ rSource: ["exampleSourceId.top2.subTopA", "exampleSourceId.top2.subTopB"] }
			]
		}

		AssignedVariablesList
		{
			title: "Assigned items"
			name: "assignMe"
		}
	}

	DropDown
	{
		label	: "Dropdown with value: <b>" + value + "</b>"
		name	: "drop"
		source	: [{ name: "fromR", discard: { rSource: "exampleSourceId.top2.subTopA"} }]
	}


	ComponentsList
	{
		label		: "ComponentsList"
		name		: "ComponentsList"
		rSource		: "exampleSourceId"
		rowComponent: Item
		{
			height	: textLable.height + comp.height
			width	: parent.width
			Text { id: textLable; text: rowValue }
			ComponentsList
			{
				id: comp
				anchors.top	: textLable.bottom
				name		: "subvalues"
				source		:
				[
					{ rSource: {name: "exampleSourceId", use: rowValue } },
					"assignMe"
				]
				rowComponent: CheckBox { name: "check"; label: rowValue }
			}
		}
	}
}

