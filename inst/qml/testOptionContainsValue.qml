import QtQuick
import JASP.Controls


Form
{
	columns: 1
	CheckBox
	{
		name:			"irrelevantCheckBox"
		label:			qsTr("This option is irrelevant")
	}

	TabView
	{
		name:				"restrictedModels"
		newItemName:		qsTr("Model 1")
		optionKey:			"modelName"

		content: Group{
				CheckBox{name: "something"; label: rowIndex === 0 ? qsTr("This option should reset the state") : qsTr("This option should not reset the state")}
		}
	}
}
