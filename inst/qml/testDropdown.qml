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

Form
{
	Group
	{
		title: "Dropdown with values"
		DropDown
		{
			label: qsTr("No fixed width")
			name: "dropDownValues"
			values: ["one", "two", "really long values!!!!!"]
		}

		DropDown
		{
			label: qsTr("fixed width")
			name: "dropDownValuesFixed"
			values: ["one", "two", "really long values!!!!!"]
			fieldWidth: 100
		}

		DropDown
		{
			label: qsTr("fixed width with startValue")
			name: "dropDownValuesFixedStartValue"
			values: ["one", "two", "really long values!!!!!"]
			fieldWidth: 100
			startValue: "really long values!!!!!"
		}

		DropDown
		{
			label: qsTr("fixed width with emptyValue")
			name: "dropDownValuesFixedEmptyValue"
			values: ["one", "two", "really long values!!!!!"]
			fieldWidth: 100
			addEmptyValue: true
		}

		DropDown
		{
			setLabelAbove: true
			label: qsTr("No fixed width")
			name: "dropDownValuesAbove"
			values: ["one", "two", "really long values!!!!!"]
		}

		DropDown
		{
			setLabelAbove: true
			label: qsTr("fixed width")
			name: "dropDownValuesFixedAbove"
			values: ["one", "two", "really long values!!!!!"]
			fieldWidth: 100
		}
	}

	Group
	{
		title: "Dropdown with variables"

		DropDown
		{
			label: qsTr("No fixed width")
			name: "dropDownVariables"
		}

		DropDown
		{
			label: qsTr("fixed width")
			name: "dropDownVariablesFixed"
			fieldWidth: 100
		}

		DropDown
		{
			label: qsTr("fixed width with startIndex")
			name: "dropDownVariablesFixedStartIndex"
			fieldWidth: 100
			currentIndex: 10
		}

		DropDown
		{
			label: qsTr("fixed width with emptyValue")
			name: "dropDownVariablesFixedEmptyValue"
			fieldWidth: 100
			addEmptyValue: true
			placeholderText: "Custom empty value"
		}

		DropDown
		{
			setLabelAbove: true
			label: qsTr("No fixed width")
			name: "dropDownVariablesLabel"
		}

		DropDown
		{
			setLabelAbove: true
			label: qsTr("fixed width")
			name: "dropDownVariablesFixedLabel"
			fieldWidth: 100
		}

	}


}
