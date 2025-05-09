import QtQuick
import JASP.Controls

Form
{
	columns: 1

	info: "This is a bunch of info on a form!"
	infoBottom: "This is a bunch of info on the bottom of a form!"

	CheckBox
	{
		id:		checkbox
		name:	"checkbox"
		label:	"A checkbox: "
		info:	"Check this out"
	}

	DropDown
	{
		id: 						dropdown
		name: 						"dropDown"
		indexDefaultValue: 	 		0
		startValue:					"high"
		label: 						qsTr("Inherent risk")
		info: 						"dropdown with info on each value"
		values: 					[
			{ label: qsTr("High"),		value: "high",		info: "So High!"},
			{ label: qsTr("Medium"), 	value: "medium",	info: "Middling"},
			{ label: qsTr("Low"), 		value: "low",		info: "Down low"},
			{ label: qsTr("Manual"), 	value: "custom",	info: "Who knows?"}
		]
	}

	DropDown
	{
		id: dropdownVariables
		name: "dropdownVariables"
		label: "Dropdown with variables"
		info: "You can choose one of the variables"
	}


	DropDown
	{
		property var extraValues: [
			{ label: qsTr("One"),		value: "one",		info: "First one"},
			{ label: qsTr("Two"),		value: "two",		info: "Second one"}
		]
		name: "dropdownVariableAndExtraValues"
		label: "Dropdown with variables and extra values"
		info: "You can choose one of the variables or special values"
		source: [{values: extraValues}, {isDataSetVariables: true}]
	}

	RadioButtonGroup
	{
		name:	"radiobuttongroup"
		info:	"A grouping of buttons of radio"
		text: 	"hallo!"

		RadioButton	{	label:	"text button uno"; info: "and some info on button"; 			name: "rButton1"	}
		RadioButton	{	label:	"label button duo"; info: "and more info on the other button"; 	name: "rButton2"	}
	}

	SimpleTableView
	{
		name:	"simpleTableView"
		info:	"a tableview with some info"
	}

	Slider
	{
		name:		"slideOnOuttaHere"
		info:		"slip and slide suicide"
		label:		"sliding: "
	}

	CheckBox
	{
		name: 						"barPlot"
		label: 						qsTr("Bar plots")

		info: qsTr("Displays the sample means as bars and the confidence intervals or standard errors as error bars for each measure.")

		RadioButtonGroup
		{
			name: "barPlotErrorType"

			RadioButton
			{
				value: 				"ci"
				label: 				qsTr("Confidence interval")
				checked: 			true
				childrenOnSameRow: 	true
				info:				qsTr("Coverage of the confidence intervals in percentages. By default, the confidence interval is set to 95%. This can be changed into the desired percentage.")

				CIField { name: 	"barPlotCiLevel"}
			}
			RadioButton { value: 	"se";	label: qsTr("Standard error"); info: qsTr("By selecting this option, the error bars will represent standard errors of the mean of each condition." )}
		}

		CheckBox
		{
			name: "barPlotYAxisFixedToZero";
			label: qsTr("Fix horizontal axis to 0"); checked: true;
			info: qsTr("Fix horizontal axis to 0: Forces the graph to show the default x-axis at y = 0")
		}
	}

	Section
	{
		title: "Some fields in a section"
		//name:	"aSection"

		DoubleField
		{
			name: "doubleFieldWithAfterLabel"
			infoLabel:	"Double field with after-label"
			label:		"this is a label"
			afterLabel: "this is an afterLabel"
			info:		"this is in doublefield that has a label and an afterLabel"
		}

		IntegerField
		{
			name: "integerFieldWithAfterLabel"
			defaultValue: 1000
			fieldWidth: 50
			min: 100
			label:		"this is a label"
			afterLabel: "this is an afterLabel"
			info:		"this is in integerfield that has a label and an afterLabel"
		}
	}

	Section
	{
		title: "Another section just for shows"
		//name:	"aSection"

		TabView
		{
			id:					tabview
			name:				"tabview"
			maximumItems:		10
			newItemName:		qsTr("NEW ITEM")
			optionKey:			"name"

			info:				"This is an info field on a tabview"

			content: Column
			{
				TextArea
				{
					name:				"syntax"
					//textType:			JASP.TextTypeModel
					trim:				true
					applyScriptInfo:	qsTr("Ctrl + Enter to apply. Click on the blue button above for help on the restriction syntax")
					info:				"TextArea inside tabview"
				}

				Group
				{
					columns: 2
					CheckBox
					{
						name:		"summary"
						label:		qsTr("Summary for %1").arg(rowValue)
						info:		"a checkbox whether you want a summary"
					}

					CheckBox
					{
						name:		"marginalMean"
						label:		qsTr("Marginal means for %1").arg(rowValue)
						info:		"a checkbox whether you want a marginalMean"
					}

				}
			}
		}


		VariablesForm
		{
			info:	"I am a variablesForm"
			AvailableVariablesList			{ info: "All variables info"; 					name: "allVariablesList"										}
			AssignedVariablesList			{ info: "assigned variables nominal allowed"; 	name: "varA";			title: qsTr("With allowed")				; id: varA ;	allowedColumns: 	["nominal"]	}
			AssignedRepeatedMeasuresCells	{ info: "assigned RM"; 							name: "cells";			title: qsTr("RM!")	}
			AssignedPairsVariablesList		{ info: "assigned pairs"; 						name: "paairs";			title: qsTr("PAIRS!")	}
			FactorLevelList					{ info:	"FactorLevelList";						name: "repeatedMeasuresFactors";	title: qsTr("Repeated Measures Factors");	factorName: qsTr("RM Factor")	}
		}

		DropDown
		{
			name: "dropdownWithVariablesSource"
			source: varA
			label: "DropDown with variables from `With allowed` list"

		}
	}

}
