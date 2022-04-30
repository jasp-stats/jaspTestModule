import QtQuick 		2.12
import JASP.Module 	1.0

Description
{
	id:					testModuleDescription
	title:				qsTr("Wait for it...")
	icon: 				"test.svg"
	description: 		qsTr("A module to test stuff with.")
	version:			"1.0"
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
		title:		qsTr("Test encoding")
		qml:		"testEncoding.qml"
		func:		"testEncodingFunc"
	}

	Analysis
	{
		title:		qsTr("Test Qml Source")
		qml:		"testQmlSource.qml"
		func:		"testQmlSourceFunc"
	}

	Analysis
	{
		title:		qsTr("Test optionContainsValue")
		qml:		"testOptionContainsValue.qml"
		func:		"testOptionContainsValue"
	}

	Separator {}

	GroupTitle { title:		"QML Widgets"; }

	Analysis
	{
		title:			qsTr("Custom Contrasts Widget")
		qml:			"customContrasts.qml"
		func:			"customContrasts"
		requiresData:	true
	}

	Analysis
	{
		title:			"Save Load Button"
		qml:			"testSaveLoadButton.qml"
		func:			"testSaveLoadButton"
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

