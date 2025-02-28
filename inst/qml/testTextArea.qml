//
// Copyright (C) 2013-2019 University of Amsterdam
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.
//
import QtQuick
import QtQuick.Layouts
import JASP
import JASP.Controls
import "./common"

Form
{
	columns: 1
	ExplanationText
	{
		text:
		"This analysis tests TextArea with Lavaan script. The variables used in the script are detected and can be the source of another control.<br>" +
		"Also this tests the relationships between the controls, when they are crearted dynamically (here in a TabView): the VariablesList and the DropDown " +
		"should get their variables from the right source. For this add several tabs with different lavaan scripts, and check that the Variables List and the Dropdown controls " +
		"get the right variables.<br>" +
		"Duplicate the analysis, and check that the same values are set in each control."
	}

	TextArea
	{
		id			: lavaanScript
		name		: "lavaanScript"
		title		: "Lavaan script"
		textType	: JASP.TextTypeLavaan
	}

	Group
	{
		columns : 2
		VariablesList
		{
			title			: "Used variables"
			Layout.preferredWidth: form.width / 2
			Layout.leftMargin: 10
			implicitHeight	: 100
			name			: "usedVariables"
			source			: "lavaanScript"
			listViewType	: JASP.AssignedVariables
			draggable		: false
			interactionHighOrderCheckBox: "observedVariable"

			rowComponent: CheckBox { name: "observedVariable"; checked: true }
		}

		DropDown
		{
			name			: "dropDown"
			source			: lavaanScript
			label			: "Choose variable"
		}

	}

	TabView
	{
		name:			"tabView"
		maximumItems:	9
		newItemName:	qsTr("Model 1")

		content: Column
		{
			spacing		: 5
			TextArea
			{
				name:		"lavaanCodeInTabView"
				id:			lavaanCodeInTabView
				textType:	JASP.TextTypeLavaan
			}

			Group
			{
				columns: 2
				VariablesList
				{
					title			: "Used variables"
					Layout.preferredWidth: lavaanCodeInTabView.width / 2
					Layout.leftMargin: 10
					implicitHeight	: 100
					name			: "usedVariablesInTabView"
					source			: lavaanCodeInTabView
					listViewType	: JASP.AssignedVariables
					draggable		: false
					interactionHighOrderCheckBox: "observedVariable"

					rowComponent: CheckBox { name: "observedVariable"; checked: true }
				}

				ComponentsList
				{
					Layout.columnSpan: 1
					preferredWidth	: lavaanCodeInTabView.width / 3
					title			: "CheckBox per variable"
					name			: "checkBoxesInTabView"
					source			: "lavaanCodeInTabView"
					rowComponent	: CheckBox { label: rowValue; name: "checkBoxInTabView" }
				}
			}
		}
	}
}
