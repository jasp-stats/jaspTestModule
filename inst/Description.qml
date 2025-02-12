import QtQuick
import JASP.Module

Description
{
	id:					testModuleDescription
	title:				qsTr("Wait for it...")
	icon: 				"test.svg"
	description: 		qsTr("A module to test stuff with.")
	version			: "0.19.2"
	author:				"Joris Goosen"
	maintainer:			"Joris Goosen <Joris@JorisGoosen.nl>"
	website:			""
	license:			"Whatever"
	requiresData: 		false

	Timer
	{
		interval: 5000
		onTriggered:
		{
			console.log(qsTr("Timer that displays the fact that updating Description.qml from live javascript code works fine."))
			testModuleDescription.title = qsTr("Test Module")
			footnotesEntry.title 		= qsTr("Test Footnotes jaspTable")
		}

		running: true
		repeat: false
	}

	GroupTitle	{ title:	"jaspResults stuff"	}
	Analysis
	{
		title:	qsTr("Test Transposed jaspTable")
		qml:	"test.qml"
		func:	"testTransposedTableFunc"
	}

	Analysis
	{
		title:	qsTr("Test jaspTable with crappy data")
		qml:	"testCrapDataTable.qml"
		func:	"testCrapDataTable"
	}

	Analysis
	{
		title:	qsTr("Test jaspTable formatting")
		qml:	"testTableFormatting.qml"
		func:	"testTableFormattingFunc"
	}

	Analysis
	{
		id:			footnotesEntry
		title:		qsTr("Wait for it...")
		qml:		"test.qml"
		func:		"testFootnotesTableFunc"
	}

	Analysis
	{
		title:		qsTr("Test jaspState")
		qml:		"testState.qml"
		func:		"testStateFunc"
	}

	Analysis
	{
		title:		qsTr("Test jaspHtml")
		qml:		"testHtml.qml"
		func:		"testHtmlFunc"
	}

	Analysis
	{
		title:		qsTr("Test latex")
		qml:		"testHtml.qml"
		func:		"testLatexFunc"
	}

	Analysis
	{
		title:		qsTr("Test jaspContainer")
		qml:		"test.qml"
		func:		"testContainerFunc"
	}

	Analysis
	{
		title:		qsTr("Test Plot Status")
		qml:		"TestPlotStatus.qml"
		func:		"testPlotStatus"
	}

	Analysis
	{
		title:		qsTr("Test Variables encoding")
		qml:		"testEncoding.qml"
		func:		"testEncodingFunc"
	}

	Analysis
	{
		title:		qsTr("Test Variables encoding with preloadData")
		qml:		"testEncoding.qml"
		func:		"testEncodingPreloadDataFunc"
		preloadData	: true
	}

	Analysis
	{
		title:		qsTr("Test optionContainsValue")
		qml:		"testOptionContainsValue.qml"
		func:		"testOptionContainsValue"
	}

	Analysis
	{
		title:	qsTr("Test Mixed Columns jaspTable")
		qml:	"testMixedColumns.qml"
		func:	"testMixedColumnsTableFunc"
	}

	Separator {}

	GroupTitle { title:		"Data and columns"; }

	Analysis
	{
		title:		qsTr("Test (comp) columns from analyses")
		qml:		"testAnalysisColumnFunc.qml"
		func:		"testAnalysisColumnFunc"
	}



	Separator {}

	GroupTitle { title:		"QML Widgets"; }

	Analysis
	{
		title:			"Test R Source"
		qml:			"testRSource.qml"
		func:			"testRSourceFunc"
	}

	Analysis
	{
		title:			"Test Sources with special attributes"
		qml:			"testSpecialSources.qml"
		func:			"testSpecialSourcesFunc"
	}

	Analysis
	{
		title:			"Radio Button"
		qml:			"RadioButtonTest.qml"
		func:			"radioButtonFunc"
		requiresData:	false
	}

	Analysis
	{
		title:			"Min Max"
		qml:			"MinMaxTest.qml"
		func:			"minMaxFunc"
		requiresData:	false
	}

	Analysis
	{
		title:			qsTr("Custom Contrasts Widget")
		qml:			"customContrasts.qml"
		func:			"customContrasts"
		requiresData:	true
	}

	Analysis
	{
		title:			qsTr("Filtered Data Entry")
		qml:			"filteredDataEntry.qml"
		func:			"filteredDataEntry"
		requiresData:	true
	}

	Analysis
	{
		title:			"Save Load Button"
		qml:			"testSaveLoadButton.qml"
		func:			"testSaveLoadButton"
	}

	Analysis
	{
		title:			"Test Variables Form"
		qml:			"testVariablesForm.qml"
		func:			"testVariablesForm"
	}

	Analysis
	{
		title:			"Test Option Names"
		qml:			"testOptionNames.qml"
		func:			"testOptionNames"
	}

	Analysis
	{
		title:			"Test TableView Widget"
		qml:			"tableView.qml"
		func:			"tableView"
	}

	Analysis
	{
		title:			"Test ComponentsList & TableView layout"
		qml:			"testComponentsListLayout.qml"
		func:			"testComponentsListLayout"
	}

	Analysis
	{
		title:			"info testing"
		qml:			"TestInfo.qml"
		func:			"infoTestFunc"
		requiresData:	false
	}

	Analysis
	{
		title:			"Test Factors Form"
		qml:			"testFactorsForm.qml"
		func:			"testFactorsFormFunc"
	}

	Analysis
	{
		title:			"Test Dropdown"
		qml:			"testDropdown.qml"
		func:			"testDropdownFunc"
	}

	Analysis
	{
		title:			"Syntax Highlighting"
		qml:			"SyntaxHighlighting.qml"
		func:			"syntaxhighlightingFunc"
	}

	Analysis
	{
		title:			"ToolTip"
		qml:			"Tooltip.qml"
		func:			"tooltipFunc"
	}

	Analysis
	{
		title:			"Test label format"
		qml:			"testLabelFormat.qml"
		func:			"testLabelFormatFunc"
	}

	Separator {}

	Analysis
	{
		title:			"Descriptives!"
		qml:			"CopyOfDescriptives.qml"
		func:			"descriptivesLink"
		requiresData:	true
	}

	GroupTitle	{ title:	"Load JASP file"	}

	Analysis
	{
		title:			"Default values with bindings"
		qml:			"testDefaultValuesWithBindings.qml"
		func:			"testDefaultValuesWithBindings"
	}

	Separator { debug: true; }

	GroupTitle { title:		"DEBUG QML Widgets"; debug: true; }

	Analysis
	{
		title:			"DEBUG Custom Contrasts Widget"
		qml:			"customContrasts.qml"
		func:			"customContrasts"
		requiresData:	true
		debug:			true
	}

	Separator {}
	GroupTitle { title: "Upgrading Modules" }

	Analysis
	{
		title:			"Analysis A";
		func:			"AnalysisUpgradeA";
		qml:			"AnalysisUpgrade.qml"
		requiresData:	false
	}


	Analysis
	{
		title:			"Analysis B";
		func:			"AnalysisUpgradeB";
		qml:			"AnalysisUpgrade.qml"
		requiresData:	false
	}

		Analysis
	{
		title:			"Analysis A with incompatible to B";
		func:			"AnalysisUpgradeIncompatibleA";
		qml:			"AnalysisUpgrade.qml"
		requiresData:	false
	}


	Analysis
	{
		title:			"Analysis B but then incompatible";
		func:			"AnalysisUpgradeIncompatibleB";
		qml:			"AnalysisUpgrade.qml"
		requiresData:	false
	}


	Separator {}
	GroupTitle { title: "Features" }

	Analysis
	{
		title:			"Reporting"
		func:			"JaspReportTest"
		qml:			"JaspReportTest.qml"
		requiresData:	true
	}

}

