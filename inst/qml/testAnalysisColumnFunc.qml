import QtQuick
import JASP
import JASP.Controls
import QtQuick.Layouts
import "./common"

Form 
{
    columns:        1

    AddColumnField
    {
        name: "AddColumnField"
        text: "Add column from analysis: "
    }

    ComputedColumnField
    {
        name: "ComputedColumnField"
        text: "Add computed column from analysis: "
    }

    RowLayout
    {
        TextField
        {
            name:   			"AddColumnsPattern"
            text:   			"Add columns from analysis: "
			Layout.fillWidth:   true
        }

        IntegerField
        {
            name:   "AddThisManyColumns"
            value:  3
            min:    1
            max:    100
        }
    }
}