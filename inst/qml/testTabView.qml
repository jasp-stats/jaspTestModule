//
// Copyright (C) 2013-2025 University of Amsterdam
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
import JASP
import "./common"

Form
{
	Section
	{
		id: subTabViews
		title: "Sub Tab Views"

		ExplanationText
		{
			text:
			"This tests three layers of Tab Views. Each Tab View layer are defined differently:" +
			"<ol><li>The first layer has for source values with value/label format. These values are taken form the name/label of the 3 Checkboxes (if checked). " +
			"As these values have value/label format, each tab shows the label as button, and the value is used as option key for the tab (keyValue). The keyLabel in the option gives the label value, " +
			"so that it can be used in the result.</li>" +
			"<li>The second layer has for source the selected variables, if their checkbox is checked. In this case the keyValue and keyLabel are the names of the variables.</li>" +
			"<li>The third layer has no source: it has minimal 2 tabs with default name 'Model', and the user can add more tabs and change the title of each tab. IOn this case the keyValue and keyLabel are the names edited by the user.</li></ol>" +
			"Add and remove tabs for each layer and check the following:" +
			"<ul><li>The Value, Label and Type displayed are the right one.</li>" +
			"<li>The option 'subTabs' has the right keyValue (and keyLabel for the first layer)</li>" +
			"<li>Per row, there is a Checkbox: check some of them, change the names of the 3rd layer tab, and add or remove some tabs in the first and second layer. Check that the same checboxes are checked.</li>" +
			"<li>Duplicate the analysis, and check that you get the same tabs, with the same checkboxes</li></ul>"
		}

		VariablesForm
		{
			AvailableVariablesList	{ name: "allVariables"	}
			AssignedVariablesList	{ name: "variables"; rowComponent: CheckBox { name: "checkedVariable"; checked: true} }
		}

		Group
		{
			columns: 3
			Column { Text { text: "oneValue" } CheckBox { id: oneCheckBox;		name: "oneValue";	label: "One";	checked: true	} }
			Column { Text { text: "twoValue" } CheckBox { id: twoCheckBox;		name: "twoValue";	label: "Two";					} }
			Column { Text { text: "threeValue" } CheckBox { id: threeCheckBox;	name: "threeValue";	label: "Three";					} }
		}

		property var firstLayerValues: [oneCheckBox, twoCheckBox, threeCheckBox].filter(x => x.checked).map(x => ({value: x.name, label: x.label}))

		TabView
		{
			id: firstLayer
			name: "subTabs"
			values: subTabViews.firstLayerValues
			addItemManually: false
			optionKey: "keyValue"
			optionKeyLabel: "keyLabel"

			rowComponent: TabView
			{
				id: secondLayer
				name: "secondLayer"
				addItemManually: false
				source: [{name: "variables", condition: "checkedVariable"}]
				optionKey: "keyValue"

				property string layer1value:	rowValue
				property string layer1label:	rowLabel
				property string layer1type:		rowType

				rowComponent: TabView
				{
					id: thirdLayer
					name: "thirdLayer"
					minimumItems: 2
					newItemValue: "Model 1"
					optionKey: "keyValue"

					property string layer2value:	rowValue
					property string layer2label:	rowLabel
					property string layer2type:		rowType


					rowComponent: GridLayout
					{
						columns: 5
						Text { text: "<b>Layer</b>"	}	Text { text: "<b>Value</b>"				}	Text { text: "<b>label</b>"				}	Text { text: "<b>Type</b>"			}	Text { text: "<b>Check</b>"			}
						Text { text: "First Layer"	}	Text { text: secondLayer.layer1value	}	Text { text: secondLayer.layer1label	}	Text { text: secondLayer.layer1type }	CheckBox { name: "firstLayerCheck"	}
						Text { text: "Second Layer"	}	Text { text: thirdLayer.layer2value		}	Text { text: thirdLayer.layer2label		}	Text { text: thirdLayer.layer2type	}	CheckBox { name: "secondLayerCheck"	}
						Text { text: "Third Layer"	}	Text { text: rowValue					}	Text { text: rowLabel					}	Text { text: rowType				}	CheckBox { name: "thirdLayerCheck"	}
					}
				}
			}
		}
	}

	Section
	{
		title: "TabView with Repeated Measures Factors"
		ExplanationText
		{
			text:
			"This tests a Tab View with Variables Form contaning Repeated Measures factors: check that this works correctly with several tabs.<br>" +
			"Check also that the dropdown get the factors and for each factor, the right levels<br>" +
			"Duplicate the analysis, and check that you get the same variables set in each Variables List in each tab."
		}

		TabView
		{
			id: tabViewWithFactors
			name: "tabViewWithFactors"

			rowComponent: Column
			{
				spacing: 10
				VariablesForm
				{
					preferredHeight: 520 * preferencesModel.uiScale
					AvailableVariablesList         { name: "allVariablesList" }
					FactorLevelList                { name: "repeatedMeasuresFactors"; id: repeatedMeasuresFactors; title: qsTr("Repeated Measures Factors"); height: 180 * preferencesModel.uiScale; factorName: qsTr("RM Factor") }
					AssignedRepeatedMeasuresCells  { name: "repeatedMeasuresCells"; title: qsTr("Repeated Measures Cells"); source: "repeatedMeasuresFactors" }
				}

				Group
				{
					columns: 2
					height: jaspTheme.comboBoxHeight + 5

					DropDown { name: "factors"; label: "Factors"; values: repeatedMeasuresFactors.factors; id: factors }
					DropDown { name: "levels"; label: "Levels"; values: repeatedMeasuresFactors.factorLevelMap[factors.currentValue] }
				}
			}

		}
	}

	Section
	{
		title: "TabView Radio Button with default checked"
		ExplanationText
		{
			text:
			"Check another Radio Button: duplicate the analysis, and check that the right Radio Button is set"
		}

		TabView
		{
			name: "tabs"
			addItemManually: true

			rowComponent: RadioButtonGroup
			{
				name: 					"inputType"
				title: 					qsTr("Input type")
				radioButtonsOnSameRow: 	true
				columns: 				2

				RadioButton
				{
					value: 		"paths"
					label: 		qsTr("Paths")
					checked: 	true
				}
				RadioButton
				{
					value: 	"hayes"
					label: 	qsTr("Hayes")
				}
			}
		}
	}
}
