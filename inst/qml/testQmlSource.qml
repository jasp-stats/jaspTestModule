import QtQuick 			2.8
import JASP.Controls 	1.0

Form 
{
	columns: 1
	VariablesForm
	{
		AvailableVariablesList
		{
			name: "fromR"
			source: [
				{ values: [qsTr("one"), qsTr("two")] },
				{ rSource: ["exampleSourceId.four.sub", "exampleSourceId.four.sub2"] }
			]
		}

		AssignedVariablesList
		{
			name: "assignMe"
		}
	}

	DropDown
	{
		name: "drop"
		source: [{ name: "fromR", discard: { rSource: "exampleSourceId.four.sub"} }]
	}


	ComponentsList
	{
		name: "titles"
		rSource:  "exampleSourceId"
		rowComponent: Item {
			height: textLable.height + comp.height
			width: parent.width
			Text { id: textLable; text: rowValue }
			ComponentsList
			{
				id: comp
				anchors.top: textLable.bottom
				name: "subvalues"
				rSource : [{name: "exampleSourceId", use: rowValue }]
				rowComponent: CheckBox { name: "check"; label: rowValue }
			}
		}
	}
}

