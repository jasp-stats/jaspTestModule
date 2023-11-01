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

Form
{
	columns: 1

	ExplanationText
	{
		text:
		"
		Simple Table with 3 columns and no buttons: with strings, integers and doubles. Their default values is set per column, their type is set also per column.
		The number of rows depend on an Integer field<br>
		Test:
		<ol>
			<li>The number of rows depends on the Integer field</li>
			<li>The default values of the String column are the alphabetical letters, the Integer column is 2, and Double column is 4</li>
			<li>The values can be updated according to the type of the columm: no letter in Interger and Double, no point or comma in Integer</li>
			<li>The values of the table are the same in the Test types table in the results</li>
		</ol>
		"
	}

	IntegerField { id: numberOfRows; label: qsTr("Number of rows"); name: "numberOfRows"; min: 0; defaultValue: 2; max: 20    }

	SimpleTableView
	{
		JASPDoubleValidator			{ id: doubleValidator; decimals: 3	}
		JASPDoubleValidator			{ id: integerValidator; decimals: 0	}
		RegularExpressionValidator	{ id: stringValidator				}

		id: continuousVariablesTable
		showButtons			: false

		initialRowCount		: numberOfRows.value
		initialColumnCount	: 3

		tableView.rowCount	: numberOfRows.value

		name				: "testTypes"
		cornerText			: qsTr("Types")
		columnNames			: [qsTr("String"), qsTr("Integer"), qsTr("Double")]
		itemTypePerColumn	: [JASP.String, JASP.Ingeter, JASP.Double]

		function getRowHeaderText(headerText, rowIndex)				{ return String.fromCharCode(65 + rowIndex);											}
		function getDefaultValue(columnIndex, rowIndex)				{ return columnIndex === 0 ? String.fromCharCode(65 + rowIndex) : 2 * columnIndex;		}
		function getValidator(columnIndex, rowIndex)				{ return columnIndex === 0 ? stringValidator : (columnIndex === 1 ? integerValidator : doubleValidator)	}
	}

	ExplanationText
	{
		text:
		"
		Simple Table with buttons: the number of rows depend on an Integer field, the number of columns depend on the buttons.<br>
		Test:
		<ol>
			<li>The number of rows depends on the Integer field</li>
			<li>The number of columns starts with the minimum number of levels + 1. You can then add columns.</li>
			<li> If the number of columns is bigger than minumum number of levels + 1, then the Delete Column button is enabled, and you can delete a column. If not, the 'Delete Column' & 'Reset' buttons are disabled</li>
			<li>The values of the table are the same in the Test buttons table in the results</li>
		</ol>
		"
	}

	Group
	{
		columns: 2

		IntegerField { id: numberOfRows2;		label: qsTr("Number of rows");	name: "numberOfRows2";	min: 0;	defaultValue: 1;	max: 20	}
		IntegerField { id: minimumLevels;		label: qsTr("Minimum levels");	name: "minimumLevels";	min: 2;	defaultValue: 2;	max: 10	}
	}

	SimpleTableView
	{
		id: testButtons

		initialRowCount		: numberOfRows2.value
		initialColumnCount	: parseInt(minimumLevels.value) + 1

		tableView.rowCount	: numberOfRows2.value
		name				: "testButtons"
		cornerText			: qsTr("Buttons")
		itemType			: JASP.String

		function getColHeaderText(headerText, colIndex)				{ return colIndex === 0 ? qsTr("Name") : qsTr("Level %1").arg(colIndex); }
		function getRowHeaderText(headerText, rowIndex)				{ return String.fromCharCode(65 + rowIndex); }
		function getDefaultValue(columnIndex, rowIndex)
		{
			return columnIndex === 0 ? String.fromCharCode(65 + rowIndex)
									 : String.fromCharCode(97 + rowIndex)
		}
	}

	ExplanationText
	{
		text:
		"
		Diagonal table: each time a column is added or removed, a row is added or removed. Moreover only the cells above the diagonal are editable.<br>
		Test:
		<ol>
			<li>Each time you add a column, a row is added.</li>
			<li>Each time you delete a column, a row is deleted</li>
			<li>The default value for the diagonal cells must be 1 and are editable</li>
			<li>The default value above the diagonal cells must be 0 and are editable</li>
			<li>The default value below the diagonal cells must be nan and are not editable</li>
		</ol>
		"
	}

	SimpleTableView
	{
		id: diagonalTable
		preferredHeight: 300 * jaspTheme.uiScale

		initialColumnCount	: 1

		name				: "diagonalTable"
		cornerText			: qsTr("Diagonal")
		tableView.rowCount	: tableView.columnCount

		function getColHeaderText(defaultName, colIndex)	{ return String.fromCharCode(65 + colIndex); }
		function getDefaultValue(columnIndex, rowIndex)		{ return columnIndex < rowIndex ? NaN : (columnIndex === rowIndex ? 1 : 0)	}
		function getEditable(columnIndex, rowIndex)			{ return columnIndex >= rowIndex	}
	}
}
