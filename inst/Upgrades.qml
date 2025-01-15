import QtQuick
import JASP.Module

Upgrades
{
	Upgrade
	{
		functionName: 		"AnalysisUpgradeA"
		newFunctionName:	"AnalysisUpgradeB"
		fromVersion:		"1.0"
		toVersion:			"1.0"
	
		ChangeRename
		{
			id:			chocoTime
			condition:	function(options) { return options['scatterPlot'] === true; } 
			from:		"frequencyTables"
			to:			"chocolade"
		}

		ChangeRemove
		{
			name:		"chocolade"
			condition:	chocoTime.condition
		}
		
		ChangeCopy
		{
			from:	"scatterPlot"
			to:		"frequencyTables"
		}
		
		ChangeSetValue
		{
			name:		"variables"
			jsonValue:	[qmlUtils.encodeAllColumnNames("contNormal"), "contExpon"] 
		}
		
		ChangeJS
		{
			id:			me
			name:		"colorPalette"
			jsFunction: function(option)
			{
				console.log("ChangeJS actually works!")

				qmlUtils.encodeJson({"hahaha": "V1"}, me);
				
				if(option["colorPalette"] === "colorblind")	return "viridis";
				else										return "colorblind";
			}
		}
	}

		Upgrade
	{
		functionName: 		"AnalysisUpgradeIncompatibleA"
		newFunctionName:	"AnalysisUpgradeIncompatibleB"
		fromVersion:		"1.0"
		toVersion:			"1.0"
	
		ChangeIncompatible
		{
			msg:		"Because there was too much awesome shit to add"
		}

	}
}