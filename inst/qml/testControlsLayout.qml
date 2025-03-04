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
	Section
	{
		title: "Dropdown"

		ExplanationText
		{
			text:
			"This tests the width of the Dropdowns according to the fieldWidth, default value/index, setLabelAbove, addEmptyValue and placeholderText properties<br><br>" +
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

	Section
	{
		title: "Checkox"

		ExplanationText
		{
			text:
				"This analysis tests the alignment of the Checkboxes in a Group, when it has some children, with childrenOnSameRow set or unset.<br><br>" +
				"By checking a Checkbox, the controls inside the Checkbox becomes enabled. <br>" +
				"If these controls are set with childrenOnSameRow, the controls should be aligned on the same horizontal as the checkbox.<br>" +
				"If these controls are not with childrenOnSameRow, the controls are displayed in a Group onder the Checkbox: if TextField or DropDown controls are used, their label / control field should be aligned as in a normal Group.<br>" +
				"This should work with several levels of Checkboxes."
		}

		Group
		{
			title: qsTr("Text field and Dropdown alignment")
			DoubleField { name: "doubleInGroup";	label: "Double"						}
			DropDown	{ name: "dropDownInGroup";	label: "Dropdown"	}
			TextField	{ name: "textInGroup";		label: "Some text"					}
		}

		Group
		{
			title:	qsTr("Control on same rows")

			CheckBox { name: "quartiles";	label: qsTr("Quartiles") }
			CheckBox
			{
				name:				"quantilesForEqualGroups"; label: qsTr("Cut points for: ")
				childrenOnSameRow:	true

				IntegerField
				{
					name:			"quantilesForEqualGroupsNumber"
					afterLabel:		qsTr(" equal groups")
				}
			}

			CheckBox
			{
				name:				"percentiles"
				label:				qsTr("Percentiles:")
				childrenOnSameRow:	true

				TextField
				{
					inputType:	"doubleArray"
					name:		"percentileValues"
					fieldWidth: 60
				}
				IntegerField
				{
					label:		"with"
					name:		"intValue"
				}
			}
		}

		Group
		{
			title:		qsTr("Inference")

			CheckBox { name: "seMean";	label: qsTr("S.E. mean") }

			CheckBox
			{
				name: "meanCi"
				label: qsTr("Confidence interval for mean")

				CIField
				{
					name: "meanCiLevel"
					label: qsTr("Width")
					info: qsTr("width of the confidence interval.")
				}

				DropDown
				{
					name: "meanCiMethod"
					label: qsTr("Method")
					id: meanCiMethod
					indexDefaultValue: 0
					info: qsTr("How should the confidence interval be computed? By default, we use a `T model`, which yields results identical to a one-sample t-test. Alternative options are a normal model (%1), or `Bootstrap`.").arg("$\\bar{x} \\pm z_{95} \\times SE$")
					values:
					[
						{label: qsTr("T model"),	value: "oneSampleTTest"},
						{label: qsTr("Normal model"),	value: "normalModel"},
						{label: qsTr("Bootstrap"),		value: "bootstrap"}
					]
				}
			}

			CheckBox
			{
				name: "sdCi"
				label: qsTr("Confidence interval for std. deviation")
				info: qsTr("a confidence interval for the standard deviation based on bootstrap samples.")

				CIField
				{
					name: "sdCiLevel"
					label: qsTr("Width")
				}

				DropDown
				{
					name: "sdCiMethod"
					label: qsTr("Method")
					id: sdCiMethod
					values:
					[
						{label: qsTr("Analytical (chi-square)"),	value: "chiSquaredModel"},
						{label: qsTr("Bootstrap"),		value: "bootstrap"}
					]
				}
			}
		}

		CheckBox
		{
			name: "checkboxWithSeveralLevels"
			label: "CheckBox with several levels"

			IntegerField
			{
				name: "integerFirstLevel"
				label: "First level integer"
			}

			CheckBox
			{
				name: "checkBoxSecondLevel"
				label: "Second level checkbox"

				DropDown
				{
					name: "dropDownSecondLevel"
					values: ["one", "two", "three"]
					label: "Second level dropdown"
				}
				IntegerField
				{
					name: "integerSecondLevel"
					label: "Second level integer"
				}
			}

			PercentField
			{
				name: "percentFirstLevel"
				label: "First level percent"
			}
		}
	}
}
