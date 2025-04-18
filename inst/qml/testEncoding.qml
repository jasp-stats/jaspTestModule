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
import JASP.Controls
import JASP
import "./common"

Form
{
	Section
	{
		title: "Simple Variables forms"
		ExplanationText
		{
			text: "
			To avoid problems with not accepted characters in R, the variable names are encoded before sent to R, and decoded when dispayed in the results.<br>
			The type of the column is also added in the encoded name, so that when the data is read, JASP knows how the variable should be read (as scale, nominal or as ordinal)<br>
			<ul>
			<li>Add some variables in the selected VariablesList, and check that the 'selected' option show the right variables, and the 'selected.types' show the right types. Change the type of the variables and check the change is reflected in the selected.types.
			Check also that the data is read in the 'Selected Data' table.</li>
			<li>Add a filter like '<10' in the 'Filter to selected' input. Check in the Data & encoded table that the variables are correctly filtered.</li>
			<li>Select a variable in the dropdown, and check that the dropdown and dropdown.type give the right result.</li>
			<li>Add some variables with interactions in the 'Variables with Interactions' VariablesList and change their types: check that the variablesWithInteraction and variablesWithInteraction.types gives the right values. Check also that the table give the right values</li>
			</ul>
			"
		}

		VariablesForm
		{
			AvailableVariablesList
			{
				name: "allVariablesList"
			}

			AssignedVariablesList
			{
				id:				selected
				name: 			"selected"
				title: 			qsTr("Selected")
				allowedColumns:	["scale", "nominal"]
				allowTypeChange: true
			}
			AssignedVariablesList
			{
				id: 				singleVariable
				name: 				"singleVariable"
				title: 				qsTr("Single Variable")
				singleVariable:		true
				allowedColumns:		"nominal"
			}
		}

		TextField
		{
			name: "genericFilter"
			label: "Filter to selected"
		}

		DropDown
		{
			name: "dropdown"
			label: "Dropdown"
			source: selected
		}

		VariablesForm
		{
			AvailableVariablesList	{ name: "allVariablesList2"	}
			AssignedVariablesList
			{
				id: variables2
				name: "variablesWithInteractions"
				title: 				qsTr("Variables with interactions")
				allowTypeChange:	true
				allowedColumns:		["scale", "nominal"]
				listViewType: JASP.Interaction
				addAvailableVariablesToAssigned: false
			}
		}
	}

	Section
	{
		title: "VariablesList in ComponentsList"

		ExplanationText
		{
			text: "
			Same thing as in the previous section, but this time the VariablesLists are inside a Components List or a VariablesList is the source of a Components List
			<ul>
			<li>Add some rows in the components list by clicking on the + button. Check that the componentList option gets the right value</li>
			<li>Add some values in the 'Variables for components list': check that the ComponentsList get the right values. Also check that the options get the right values and types by changing the types of the variables.</li>
			</ul>
			"
		}

		ComponentsList
		{
			name: "componentsListWithVariables"
			title: "Components List with VariablesList"

			minimumItems: 1

			rowComponent: Column
			{
				property alias selectedVariables: variablesInComponentsList
				Text {text: "Row: " + rowValue}

				VariablesForm
				{
					AvailableVariablesList	{ name: "allVariablesListInComponentsList"										}
					AssignedVariablesList
					{
						id:					variablesInComponentsList
						name: 				"variablesInComponentsList"
						title: 				qsTr("Variables")
						allowedColumns:		["scale", "nominal"]
						allowTypeChange:	true
					}

					AssignedVariablesList
					{
						id:					singleVariableAA
						name: 				"singleVariable"
						title: 				qsTr("Single Variable")
						singleVariable:		true
					}
				}

				DropDown { name: "levelsOfSingleVariable"; label: "Levels of Single Variable"; values: singleVariableAA.levels}

			}

		}

		Text {text: "Variables List as source of a ComponentsList"}
		VariablesForm
		{
			AvailableVariablesList	{ name: "anotherVariablesList"	}
			AssignedVariablesList
			{
				name: 				"variablesForComponentsList"
				title: 				qsTr("Variables for components list")
				allowedColumns:		["scale", "nominal"]
				allowTypeChange:	true
				listViewType:		JASP.Interaction
				addAvailableVariablesToAssigned: false

			}
		}

		ComponentsList
		{
			name: "componentsListFromVariablesList"
			title: "ComponentsList with source a VariablesList"
			source: "variablesForComponentsList"

			rowComponent: Row
			{
				spacing: 10
				Text {text: "Row: " + rowValue}
			}
		}

	}

	Section
	{
		title: "Paired VariablesList"

		ExplanationText
		{
			text: "
			Paired VariablesList should also work with or without preloadData.<br>
			Check that pairs and pairs.types are well defined in the options, and that the Pairs Variables table get the right values.
			"
		}

		VariablesForm
		{
			AvailableVariablesList { name: "availableForPairs" }
			AssignedPairsVariablesList { name: "pairs"; title: qsTr("Variable Pairs"); allowedColumns: ["scale"]}
		}

	}
}
