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
import JASP
import JASP.Controls
import "./common"
import QtQuick.Layouts

Form 
{
	Section
	{
		title: "Components List"

		ExplanationText
		{
			text:
				"This tests the display of the ComponentLists" +
				"<ul>" +
				"<li>A ComponentsList should be displayed on the whole width of the Analysis form. " +
				"Its length is per default as long as its content, but by setting the <b>preferredHeight</b> (via the 'Set fixed height' checkbox), this height can be set: in this case a vertical Scrollbar must appear when necessary.</li>" +
				"<li>The <b>minimumItems</b> property is set here to 4, so this ComponentsList has at least 4 rows. More rows can be added (if the 'Add item manually' checkbox is checked): these rows can be then deleted with the X icon.</li>" +
				"<li>The <b>defaultValues</b> property is set so that the first row gets 'First hypothesis - Second column - Third column' as values for the 'Hypothesis - Col 2 - Col 3' columns, " +
				"and for the second row 'Second hypothesis' for the 'Hypothesis' column. The other cells get the default values as set in the control self, that is: 'Hypothesis <row number>' for the 'Hypothesis' column, and '2' for 'Col 2', '3' for 'Col 3', etc...<br>" +
				"You can add or remove some columns with DropDown 'Columns': check that when the ComponentsList wider is that the Analysis Form, that automatically an horizontal Scrollbar appears.</li>" +
				"<li>The <b>title</b> property sets the title of the ComponentsList: check by toggling the 'Show title' checkbox that the title appears and disappears, and also that the height and the layout of the ComponentsList are correct.</li>" +
				"<li>The <b>headerLabels</b> property sets the headers of the columns. If the value of this property is an array of strings, then the ith string becomes the header of the ith column (if it exists) " +
				"If the value is a mapping of control name/header label, then each label should be set to the corresponding control column header (if this control name exists).<br>" +
				"By setting the dropdown 'Header type to " +
				"<ul><li>Header with array: you set <b>headerLabels</b> property to '[\"Hypothesis\", \"Column 2\", \"Column 3\", \"Column 4\", \"Column 5\", \"Column 6\"]'.</li>" +
				"<li>Header with map: you set <b>headerLabels</b> property to '[\"Hypothesis\", { col6: \"Column 6\", col3: \"Column 3\",  col4: \"Column 4\" }].</li>" +
				"<li>No header: no header should be displayed.</li></ul>" +
				"By changing this setting and the number of columns, check that the headers are displayed as expected, and that the layout of the ComponentsList stays correct.</li>" +
				"<li>You can set the <b>addBorder</b> property with the 'Add border checkbox, and the <b>addItemManually</b> property (this adds the '+' icon) with the 'Add item manually' checkbox. " +
				"Check by toggling these checkboxes whether the layout of the ComponentsList stays correct</li>" +
				"</ul>"
		}

		Group
		{
			columns: 2
			Column
			{
				CheckBox
				{
					id		: showTitleCheck
					label	: "Show title"
					name	: "showTitleCheck"
				}
				CheckBox
				{
					id		: addItemManuallyCheck
					label	: "Add item manually"
					name	: "addItemManuallyCheck"
					checked	: true
				}
				CheckBox
				{
					id		: heightCheck
					label	: "Set fixed height"
					name	: "heightCheck"
				}
				CheckBox
				{
					id		: addBorderCheck
					label	: "Add border"
					name	: "addBorderCheck"
					checked	: true
				}
			}
			Column
			{
				DropDown
				{
					id		: columns
					label	: "Columns"
					name	: "columns"
					values	: ["3", "4", "5", "6"]
				}
				DropDown
				{
					id		: headers
					label	: "Header Type"
					name	: "headers"
					values	: ["No header", "Header with array", "Header with map"]
					value	: "Header with array"
				}
				Text
				{
					color	: "red"
					text	: headers.value == "No header" ? "No header should be displayed" : (headers.value == "Header with array" ? "All headers should be displayed" : "Headers of Column 2 and Column 5 should not be displayed")
				}
			}
		}

		ComponentsList
		{
			id					: componentsListControl
			title				: showTitleCheck.checked ? "Components List" : ""
			headerLabels		: headers.value == "No header" ? "" : (headers.value == "Header with array" ? ["Hypothesis", "Column 2", "Column 3", "Column 4", "Column 5", "Column 6"] : ["Hypothesis", { col6: "Column 6", col3: "Column 3",  col4: "Column 4"}])
			name				: "componentsList"
			defaultValues		: [{hypothesis: "First hypothesis", col2: "Second column", col3: "Third column"}, {hypothesis: "Second hypothesis"}]
			addItemManually		: addItemManuallyCheck.checked
			minimumItems		: 4
			preferredHeight		: heightCheck.checked ? 100 : implicitHeight
			addBorder			: addBorderCheck.checked

			rowComponent: 			RowLayout
			{
				TextField
				{
					name: 				"hypothesis"
					startValue:			qsTr("Hypothesis ") + (rowIndex + 1)
					fieldWidth:			140 * preferencesModel.uiScale
					useExternalBorder:	false
					showBorder:			true
				}
				TextField
				{
					name: 				"col2"
					value:				"col 2"
					fieldWidth:			140 * preferencesModel.uiScale
					useExternalBorder:	false
					showBorder:			true
				}
				TextField
				{
					name:				"col3"
					value:				"col 3"
					fieldWidth:			140 * preferencesModel.uiScale
					useExternalBorder:	false
					showBorder:			true
				}
				TextField
				{
					name:				"col4"
					value:				"col 4"
					fieldWidth:			140 * preferencesModel.uiScale
					useExternalBorder:	false
					showBorder:			true
					visible:			["4", "5", "6"].includes(columns.value)
				}
				TextField
				{
					name:				"col5"
					value:				"col 5"
					fieldWidth:			140 * preferencesModel.uiScale
					useExternalBorder:	false
					showBorder:			true
					visible:			["5", "6"].includes(columns.value)
				}
				TextField
				{
					name:				"col6"
					value:				"col 6"
					fieldWidth:			140 * preferencesModel.uiScale
					useExternalBorder:	false
					showBorder:			true
					visible:			["6"].includes(columns.value)
				}
			}
		}
	}

	Section
	{
		title: "Table View"

		ExplanationText
		{
			text:
				"This tests the display of the Table View with its buttons" +
				"<ul>" +
				"<li>A Table View should be displayed on the whole width of the Analysis form.<br>" +
				"Its length is per default as long as its content, but by setting the <b>preferredHeight</b> (via the 'Set fixed height' checkbox), this height can be set: in this case a vertical Scrollbar must appear when necessary.</li>" +
				"<li>The <b>initialColumnCount</b> property is set here to 2, so this Table View starts with 2 columns. More columns can be added with the Add button. This Table View has also 1 minimum and 10 maximun columns.<br>" +
				"Test when adding and removing columns that the scrollbars appears when necessary, that the \'Add\' and \'Delete\' buttons become disabled accordingly, and that the layout of the Table stays correct.</li>" +
				"<li>The buttons can displayed or hidden via the <b>showButtons</b> property, and the buttons can be displayed either at the top of the Table in a row, or at the leaft of the Table in a column via the <b>buttonsInRow</b> property. Test these properties with the 'Show buttons' and 'Buttons in row' checkboxes, and check that the layout of the buttons with the Table is correct.</li>" +
				"</ul>"
		}

		Row
		{
			spacing: 5
			CheckBox
			{
				id		: tableHeightCheck
				label	: "Set fixed height"
				name	: "tableHeightCheck"
			}

			CheckBox
			{
				id		: showButtonsCheck
				label	: "Show buttons"
				name	: "showButtonsCheck"
				checked	: true
			}

			CheckBox
			{
				id:			buttonsInRowCheck
				name:		"buttonsInRowCheck"
				label:		"Buttons in row"
			}

		}

		Chi2TestTableView
		{
			name				: "tableView"
			preferredHeight		: tableHeightCheck.checked ? 200 : implicitHeight
			initialColumnCount	: 2
			buttonsInRow		: buttonsInRowCheck.checked
			showButtons			: showButtonsCheck.checked
		}


	}


	Section
	{
		title: "Components List with Table View"

		ExplanationText
		{
			text:
				"This tests the display of Table Views as row components of a Components List.<br>" +
				"Typically it uses the ContrastLists widget: all factors that have a \'custom\' as controst value, generate a CustomContrastsTableView inside a Components List.<br>" +
				"Here, just test that the width and heigth of the Table Views are correct, that when adding several contrasts a horizontal scrollbar is displayes when necessary, and that the height of the Components List becomes always big enough to contain all the Tables Views without having to add vertical scrollbar."
		}

		VariablesForm
		{
			AvailableVariablesList	{ name		: "allVariablesList" }
			AssignedVariablesList
			{
				name							: "fixedFactors"
				title							: qsTr("Fixed Factors")
				suggestedColumns				: ["ordinal", "nominal"]
				listViewType					: JASP.Interaction
				addAvailableVariablesToAssigned	: false
			}
		}

		ContrastsList{}
	}

}
