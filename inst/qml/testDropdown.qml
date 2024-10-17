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
import "./common"

Form
{
	ExplanationText
	{
		text:
		"This analysis tests the width of the Dropdowns according to the fieldWidth, default value/index, setLabelAbove, addEmptyValue and placeholderText properties<br><br>" +
		"Per default, the dropdown width (and its popup menu) will fit the longest possible value of the popup values. If a Type icon is added for a variable, this is also taken into account.<br>" +
		"If the fieldWidth is set, then the width of the dropdown is fixed: if its value is smaller than the fixed length, then a white space is added, if it is smaller, then the value will be elided with '...'.<br>" +
		"The popup menu should still be as wide as necessary.<br>" +
		"Set some values in the Dropdonws and duplicate the analysis: check that the smae values are set."
	}

	columns: 1

	Group
	{
		title: "<b>Default Dropdown</b>"
		columns: 2

		Group
		{
			title: "Dropdown with values"
			columns: 1

			DropDown
			{
				label: qsTr("Label left")
				name: "dropDownValues"
				values: ["one", "two", "really long values!!!!!"]
			}
			DropDown
			{
				setLabelAbove: true
				label: qsTr("Label above")
				name: "dropDownValuesAbove"
				values: ["one", "two", "really long values!!!!!"]
			}
			DropDown
			{
				label: qsTr("With startValue")
				name: "dropDownStartValue"
				values: ["one", "two", "really long values!!!!!"]
				startValue: "really long values!!!!!"
			}
			DropDown
			{
				label: qsTr("With emptyValue")
				name: "dropDownValuesEmptyValue"
				values: ["one", "two", "really long values!!!!!"]
				addEmptyValue: true
				placeholderText: "Custom empty value"
			}
		}

		Group
		{
			title: "Dropdown with variables"
			columns: 1

			DropDown
			{
				label: qsTr("Label left")
				name: "dropDownVariables"
			}
			DropDown
			{
				setLabelAbove: true
				label: qsTr("Label above")
				name: "dropDownVariablesLabel"
			}
			DropDown
			{
				label: qsTr("With startIndex")
				name: "dropDownVariablesStartIndex"
				currentIndex: 10
			}
			DropDown
			{
				label: qsTr("With emptyValue")
				name: "dropDownVariablesEmptyValue"
				values: ["one", "two", "really long values!!!!!"]
				addEmptyValue: true
				placeholderText: "Custom empty value"
			}
		}
	}

	Group
	{
		title: "<b>Dropdown with fixed width</b>"
		columns: 2

		Group
		{
			title: "Dropdown with values"
			columns: 1

			DropDown
			{
				label: qsTr("Label left")
				name: "dropDownValuesFixed"
				values: ["one", "two", "really long values!!!!!"]
				fieldWidth: 100
			}

			DropDown
			{
				setLabelAbove: true
				label: qsTr("Label above")
				name: "dropDownValuesFixedAbove"
				values: ["one", "two", "really long values!!!!!"]
				fieldWidth: 100
			}

			DropDown
			{
				label: qsTr("With startValue")
				name: "dropDownValuesFixedStartValue"
				values: ["one", "two", "really long values!!!!!"]
				fieldWidth: 100
				startValue: "really long values!!!!!"
			}

			DropDown
			{
				label: qsTr("With emptyValue")
				name: "dropDownValuesFixedEmptyValue"
				values: ["one", "two", "really long values!!!!!"]
				fieldWidth: 100
				addEmptyValue: true
				placeholderText: "Custom empty value"
			}
		}

		Group
		{
			title: "Dropdown with variables"
			columns: 1

			DropDown
			{
				label: qsTr("Label left")
				name: "dropDownVariablesFixed"
				fieldWidth: 100
			}
			DropDown
			{
				setLabelAbove: true
				label: qsTr("Label above")
				name: "dropDownVariablesFixedLabelAbove"
				fieldWidth: 100
			}
			DropDown
			{
				label: qsTr("With startIndex")
				name: "dropDownVariablesFixedStartIndex"
				fieldWidth: 100
				currentIndex: 10
			}

			DropDown
			{
				label: qsTr("With emptyValue")
				name: "dropDownVariablesFixedEmptyValue"
				fieldWidth: 100
				addEmptyValue: true
				placeholderText: "Custom empty value"
			}
		}
	}

	Group
	{
		title: "<b>Dropdown with allowed types</b>"
		columns: 2

		Group
		{
			DropDown
			{
				label: qsTr("Scale")
				name: "dropDownScale"
				allowedColumns:	"scale"
				minNumericLevels: minNumeric.value
				maxNumericLevels: maxNumeric.value
			}
			DropDown
			{
				label: qsTr("Nominal")
				name: "dropDownNominal"
				allowedColumns:	"nominal"
				minLevels: minLevels.value
				maxLevels: maxLevels.value
			}
			DropDown
			{
				label: qsTr("Ordinal")
				name: "dropDownOrdinal"
				allowedColumns:	"ordinal"
				minLevels: minLevels.value
				maxLevels: maxLevels.value
			}
		}
		Group
		{
			IntegerField
			{
				id: minLevels
				name: "minLevels"
				label: "Min levels for Nominal and Ordinal"
				value: -1
				negativeValues: true
			}
			IntegerField
			{
				id: maxLevels
				name: "maxLevels"
				label: "Max levels for Nominal and Ordinal"
				value: 100
				negativeValues: true
			}
			IntegerField
			{
				id: minNumeric
				name: "minNumeric"
				label: "Min numerics for Scale"
				value: -1
				negativeValues: true
			}
			IntegerField
			{
				id: maxNumeric
				name: "maxNumeric"
				label: "Max numerics for Scale"
				value: 100
				negativeValues: true
			}
		}
	}
}
