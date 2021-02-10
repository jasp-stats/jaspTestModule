import QtQuick		2.12
import JASP.Module	1.0

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
			condition:	function(options) { return options['frequencyTables'] === true; } 
			from:		"frequencyTables"
			to:			"chocolade"
		}
		
		ChangeCopy
		{
			from:	"scatterPlot"
			to:		"frequencyTables"
		}
		
		ChangeSetValue
		{
			name:		"variables"
			jsonVal:	["contNormal", "contExpon"] 
		}
		
		ChangeJS
		{
			name:		"colorPalette"
			jsFunction: function(option)
			{
				console.log("ChangeJS actually works!")
				
				if(option === "colorblind")	return "viridis";
				else						return "colorblind";
			}
		}
	}
}