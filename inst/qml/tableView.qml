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

import QtQuick 			2.15
import QtQuick.Layouts 	1.3
import JASP				1.0
import JASP.Controls 	1.0
import JASP.Widgets 	1.0


Form
{
	Group
	{

		IntegerField { id: numberOfContinuous; label: qsTr("Number of continuous factors"); name: "numberOfContinuous"; min: 0; defaultValue: 2; max: 20    }

		TableView
		{
			JASPDoubleValidator			{ id: doubleValidator; decimals: 3	}
			RegularExpressionValidator	{ id: stringValidator				}


			id: continuousVariablesTable
			modelType			: JASP.Simple

			width				: 400
			height				: 300

			initialRowCount		: numberOfContinuous.value
			initialColumnCount	: 3

			rowCount			: numberOfContinuous.value
			columnCount			: 3

			name				: "continuousVariables"
			cornerText			: qsTr("Factor")
			columnNames			: [qsTr("Name"), qsTr("Low"), qsTr("High")]
			isFirstColEditable	: JASP.Double
			itemTypePerColumn	: [JASP.String]

			function getRowHeaderText(headerText, rowIndex)				{ return String.fromCharCode(65 + rowIndex);											}
			function getDefaultValue(columnIndex, rowIndex)				{ return columnIndex === 0 ? String.fromCharCode(65 + rowIndex) : 2 * columnIndex - 3; 	}
			function getValidator(columnIndex, rowIndex)				{ return columnIndex === 0 ? stringValidator : doubleValidator							}
		}

		IntegerField { id: numberOfCategorical;		label: qsTr("Number of categorical factors");	name: "numberOfCategorical";	min: 0;	defaultValue: 0;	max: 20	}
		IntegerField { id: numberOfLevels;			label: qsTr("Maximum levels");					name: "categoricalNoLevels";	min: 2;	defaultValue: 2;	max: 10	}

		TableView
		{
			id: categoricalVariables
			modelType			: JASP.Simple

			width				: 400
			height				: 300

			isFirstColEditable	: true

			initialRowCount		: numberOfCategorical.value
			initialColumnCount	: 1 + (numberOfLevels.value ? parseInt(numberOfLevels.value) : 0)

			rowCount			: numberOfCategorical.value
			// if you give a table 0 rows and columns it becomes very ugly, so check if numberOfLevels.value is defined first
			columnCount			: 1 + (numberOfLevels.value ? parseInt(numberOfLevels.value) : 0)
			name				: "categoricalVariables"
			cornerText			: qsTr("Factor")
			itemType			: JASP.String

			function getColHeaderText(headerText, colIndex)				{ return colIndex === 0 ? qsTr("Name") : qsTr("Level %1").arg(colIndex); }
			function getRowHeaderText(headerText, rowIndex)				{ return String.fromCharCode(65 + rowIndex + parseInt(numberOfContinuous.value)); }
			function getDefaultValue(columnIndex, rowIndex)
			{
				return columnIndex === 0 ? String.fromCharCode(65 + rowIndex + parseInt(numberOfContinuous.value))
										 : columnIndex === 1 ? 'a'
															 : columnIndex === 2 ? 'b' : "";
			}
		}
	}
}
