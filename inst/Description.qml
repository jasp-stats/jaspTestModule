import QtQuick
import JASP.Module

Description
{
	id:					testModuleDescription
	title:				qsTr("Test Module")
	icon: 				"test.svg"
	description: 		qsTr("A module to test stuff with.")
	requiresData: 		false
	hasWrappers: 		true
	preloadData:		false
	
	Timer
	{
		interval: 5000
		onTriggered:
		{
			console.log(qsTr("Timer that displays the fact that updating Description.qml from live javascript code works fine."))
			testModuleDescription.title = qsTr("Test Module?")
		}

		running: true
		repeat: false
	}

	GroupTitle	{ title:	"jaspResults stuff"	}
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

	Separator {}

	GroupTitle { title: "Multi dataset" }

	// multiDataSetAware is not declared any more: the Analysis finds out by itself once its form
	// loads and a control registers a dataset selection (dataSetSelectionOption - see
	// testMultiDataSet.qml). The analysis then gets every dataset its options reference as the
	// `datasets` argument (jaspBase >= the multiDataSetAware branch) and its FilterSelect dropdowns
	// become live. The expander's filter button selects the default (hostless) source.
	Analysis
	{
		title:				"Test Multi-DataSet"
		qml:				"testMultiDataSet.qml"
		func:				"multiDataSetFunc"
		requiresData:		true
		preloadData:		true
		hasWrapper:			true
	}

	// the component zoo under multi-source provenance. Every control family
	// (assigned list, list-as-host, row-control ComponentsList with same-name twins across filters,
	// interaction terms, factor levels via encodeThis, textarea with own host, cross-host typed
	// bindTo copy) reports what it received and where it resolved; the RPC verifier asserts it.
	Analysis
	{
		title:				"Test Multi-DataSet Controls"
		qml:				"testMultiDataSetControls.qml"
		func:				"multiDataSetControlsFunc"
		requiresData:		true
		preloadData:		true
		hasWrapper:			true
	}

	// The old non-aware twin entry (func multiDataSetNonAware / qml testMultiDataSetNonAware)
	// is gone: it existed only to show that selection options stay inert
	// without multiDataSetAware, but its generated wrapper pointed at the AWARE form and so its
	// R entry point always errored. The non-aware code path is covered by the other
	// (plain, single-dataset) analyses in this module.

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

	GroupTitleSmall { title:		"Data and columns"; }

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
		title:			"Test Tab View"
		qml:			"testTabView.qml"
		func:			"testTabView"
	}

	Analysis
	{
		title:			"Test Table View"
		qml:			"testTableView.qml"
		func:			"testTableView"
	}

	Analysis
	{
		title:			"Test TextArea"
		qml:			"testTextArea.qml"
		func:			"testTextArea"
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
		title:			"Test Controls layout"
		qml:			"testControlsLayout.qml"
		func:			"testControlsLayoutFunc"
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

	Analysis
	{
		title:			"Test Input Field"
		qml:			"testInputField.qml"
		func:			"testInputFieldFunc"
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

