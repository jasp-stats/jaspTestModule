import QtQuick
import JASP
import JASP.Controls
import QtQuick.Layouts
import "./common"

Form
{
	Section
	{
		title	: "Source with combineTerms"
		columns	: 1

		ExplanationText
		{
			text:
				"The terms of the source can be combined by using the 'combineTerms' attribute.<br>" +
				"This can be set to CombinationCross, CombinationInteraction, Combination2Way, Combination3Way, Combination4Way or Combination5Way<br>" +
				"Here only CombinationCross, Combination2Way & Combination3Way is tested: CombinationCross should give all combinationsm, Combination2Way all combinations with 2 items " +
				"and Combination3Way all combinations with 3 items" +
				"<ul>" +
				"<li>Select some variables, and check that the Combination2Way, Combination3Way & CombinationCross gives the right combinations</li>" +
				"<li>For combinations2way & Combination3Way, check that the extra DropDown should get the items of the selected variables, minus the variables used by the combinations.</li>" +
				"<li>Duplicate the analysis and check that the controls have the same values.</li>" +
				"</ul>"
		}

		VariablesForm
		{
			AvailableVariablesList	{ name: "allVariablesList"								}
			AssignedVariablesList	{ name: "variables";		title: qsTr("Variables");	id: variables 	}
		}

		Text { visible: variables.count <= 1; text: "At least 2 variables must be selected for Combinations 2 Way" }

		ComponentsList
		{
			id		: combinations2way
			title	: "Combinations 2 way"
			name	: "combinations2way"
			visible	: variables.count > 1
			source	: [ {name: "variables", combineTerms: JASP.Combination2Way}]

			property int textWidth: variables.maxTermsWidth

			rowComponent: RowLayout
			{
				property var pair : rowValue.split(INTERACTION_SEPARATOR)

				Text { Layout.preferredWidth: combinations2way.textWidth; text: pair[0] }
				Text { text: "-" }
				Text { Layout.preferredWidth: combinations2way.textWidth; text: pair[1] }
				DropDown
				{
					name			: "mediation"
					addEmptyValue	: true
					placeholderText	: qsTr("No Mediation")
					source			: [{name: "variables", discard: {values: pair} }]
				}
			}
		}


		Text { visible: variables.count <= 2; text: "At least 3 variables must be selected for Combinations 3 Way" }

		ComponentsList
		{
			id		: combinations3way
			title	: "Combinations 3 way"
			name	: "combinations3way"
			visible	: variables.count > 2
			source	: [ {name: "variables", combineTerms: JASP.Combination3Way}]

			property int textWidth: variables.maxTermsWidth

			rowComponent: RowLayout
			{
				property var triple : rowValue.split(INTERACTION_SEPARATOR)

				Text { Layout.preferredWidth: combinations3way.textWidth; text: triple[0] }
				Text { text: INTERACTION_SEPARATOR }
				Text { Layout.preferredWidth: combinations3way.textWidth; text: triple[1] }
				Text { text: INTERACTION_SEPARATOR }
				Text { Layout.preferredWidth: combinations3way.textWidth; text: triple[2] }
				DropDown
				{
					name			: "mediation"
					addEmptyValue	: true
					placeholderText	: qsTr("No Mediation")
					source			: [{name: "variables", discard: {values: triple} }]
				}
			}
		}

		ComponentsList
		{
			id		: combinationCross
			title	: "Combination Cross"
			name	: "combinationCross"
			source	: [ {name: "variables", combineTerms: JASP.CombinationCross}]

			property int textWidth: variables.maxTermsWidth

			rowComponent: Text { text: rowValue }
		}
	}

	Section
	{
		title	: "Source with levels"

		ExplanationText
		{
			text:
				"When a source has for attribute 'levels', then it gets all the labels of the variables in the source" +
				"<ul>" +
				"<li>If the source has only 1 variable, then all labels of this source are used. The order of the labels are kept (check it by changing the order)</li>" +
				"<li>If the source has several variables, then all labels of all variables are used. Duplicate labels are removed. The order of the labels must be the same as the order of the variables in the source.</li>" +
				"<li>Duplicate the analysis and check that the controls have the same values.</li>" +
				"</ul>"
		}

		VariablesForm
		{
			preferredHeight: 200
			AvailableVariablesList	{ name: "allVariablesList2"	}
			AssignedVariablesList
			{
				id				: variableWithLabels
				name			: "variableWithLabels"
				title			: qsTr("One variable with labels")
				singleVariable	: true
				allowedColumns	: ["nominal", "nominalText", "ordinal"]
			}

			AssignedVariablesList
			{
				id				: severalVariablesWithLabels
				name			: "severalVariablesWithLabels"
				title			: qsTr("Several variables with labels")
				allowedColumns	: ["nominal", "nominalText", "ordinal"]
			}

		}

		DropDown
		{
			name: "labelsFor1Variable"
			label: "Labels for 1 variable"
			source: [ {name: "variableWithLabels", use: "levels"} ]
		}

		DropDown
		{
			name: "labelsForSeveralVariable"
			label: "Labels for several variables"
			source: [ {name: "severalVariablesWithLabels", use: "levels"} ]
		}
	}

	Section
	{
		title	: "Filter source with some types"

		ExplanationText
		{
			text:
				"When a source has for attribute 'type=<some type>', then it filters the variables with this type<br>" +
				"If several types are accepted, then the types must be separared by '|': 'type=ordinal|nominal'" +
				"<ul>" +
				"<li>Select some variables, and check that the dropdowns get the right filtered variables</li>" +
				"<li>If a dropdown has some value, and this value is not more in the source, then the dropdown should be set automatically to the another value.</li>" +
				"<li>Duplicate the analysis and check that the controls have the same values.</li>" +
				"</ul>"
		}

		VariablesForm
		{
			preferredHeight: 200
			AvailableVariablesList	{ name: "allVariablesList3"	}
			AssignedVariablesList
			{
				id				: selectedVariables
				name			: "selectedVariables"
				title			: qsTr("Several variable")
			}

		}

		DropDown
		{
			name: "scaleVariables"
			label: "Scale variables"
			source: [ {name: "selectedVariables", use: "type=scale"} ]
		}

		DropDown
		{
			name: "ordinalVariables"
			label: "Ordinal variables"
			source: [ {name: "selectedVariables", use: "type=ordinal"} ]
		}

		DropDown
		{
			name: "ordinalAndNominalVariables"
			label: "Ordinal and nominal variables"
			source: [ {name: "selectedVariables", use: "type=ordinal|nominal"} ]
		}
	}

	Section
	{
		title	: "Source with controls"

		ExplanationText
		{
			text:
				"If a source has some sontrols, it is posible to specify to fetch the value of a control (and not the values of the source self)<br>" +
				"<ul>" +
				"<li>Select some variables, they should all get the value 'one': check that the dropdown get only the value 'one'</li>" +
				"<li>Set the checkbox for some variables: the dropdown should get the values of these variables dropdown values</li>" +
				"<li>Change some values for the variables: the dropdown should get the new values</li>" +
				"<li>If 2 variables have the same value, the dropdown should remove the duplicates</li>" +
				"<li>If 2 variables have the same value, but only one is checked, then the dropdown value should be added</li>" +
				"<li>If all variables have different values than 'one' (the default), then the dropdown should not have 'one' as value. Add a new variable (that gets the default 'one' as value): the dropdown should get this value.</li>" +
				"<li>Set the dropdown to some value and remove all variables that are set to this value: the dropdown should get automtically another value.</li>" +
				"<li>Duplicate the analysis and check that the controls have the same values.</li>" +
				"</ul>"
		}

		VariablesForm
		{
			preferredHeight: 200
			AvailableVariablesList	{ name: "allVariablesList4"	}
			AssignedVariablesList
			{
				id				: selectedVariablesWithControls
				name			: "selectedVariablesWithControls"
				title			: qsTr("Variable with controls")

				rowComponent	: Row
				{
					DropDown { name: "extra"; values: ["one", "two", "three", "four", "five"] }
					CheckBox { name: "check" }
				}
			}

		}

		DropDown
		{
			name: "controlVariables"
			label: "Dropdown values of selected variables"
			source: [{ name: "selectedVariablesWithControls.extra", condition: "check" }]
		}

	}

	Section
	{
		title	: "Source with conditions"
		columns	: 1

		ExplanationText
		{
			text:
				"If a source has some sontrols, it is posible to filter the values according to some value of the controls<br>" +
				"Here, the first variables list gets all variables that are unchecked and value equals to 'one': the default values<br>" +
				"The second variables list gets all variables that are checked and value different than 'one'" +
				"<ul>" +
				"<li>Select some variables, and check that both variables list get the right variables according to their conditions</li>" +
				"<li>Duplicate the analysis and check that the controls have the same values.</li>" +
				"</ul>"
		}

		VariablesForm
		{
			preferredHeight: 200
			AvailableVariablesList	{ name: "allVariablesList5"	}
			AssignedVariablesList
			{
				id				: selectedVariablesWithCondition
				name			: "selectedVariablesWithControls2"
				title			: qsTr("Variable with controls")

				rowComponent	: Row
				{
					DropDown { name: "extraValue"; values: ["one", "two", "three", "four", "five"] }
					CheckBox { name: "check" }
				}
			}

		}

		AssignedVariablesList
		{
			preferredHeight	: 150
			name			: "variablesWithConditions"
			label			: "Variables unchecked and value equal to 'one'"
			source			: [ {name: "selectedVariablesWithControls2", condition: "check == false && extraValue == 'one'"} ]
		}
		AssignedVariablesList
		{
			preferredHeight	: 150
			name			: "variablesWithConditions2"
			label			: "Variables checked and value different than 'one'"
			source			: [ {name: "selectedVariablesWithControls2", condition: "check == true && extraValue != 'one'"} ]
		}

	}
}

