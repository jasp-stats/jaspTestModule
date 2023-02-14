import QtQuick
import QtQuick.Layouts
import JASP
import JASP.Controls


Rectangle
{
	property alias text			: explanation.text
	property alias textFormat	: explanation.textFormat

	Layout.columnSpan			: (parent && parent.hasOwnProperty('columns')) ? parent.columns : 1

	implicitWidth	: form.width
	implicitHeight	: explanation.height
	border.color	: jaspTheme.blue
	border.width	: 1
	color			: jaspTheme.blueMuchLighter
	Text
	{
		id			: explanation
		padding		: 5
		width		: form.width
		wrapMode	: Text.Wrap
		textFormat	: Text.RichText
	}
}

