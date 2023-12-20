//
// Copyright (C) 2013-2023 University of Amsterdam
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
import JASP.Controls
import JASP.Widgets


Form
{
	VariablesForm 
	{ 
		id: 				variablesFormPlanning
		implicitHeight: 	110
		AvailableVariablesList 	{ name: "variablesFormPlanning" }
		AssignedVariablesList 	{ name: "recordNumberVariable"; title: qsTr("Record numbers"); id: recordNumberVariable }

	}

    TableView
    {
        id:         table
        name:       "filteredData"
        modelType:  "FilteredDataEntryModel"
        filter:     filterID.value
        source:     "recordNumberVariable"
        colName:    "auditResult"
    }

    TextField
    {
        id:     filterID
        name:   "aFilter"
        value:  table.filter

    }
}
