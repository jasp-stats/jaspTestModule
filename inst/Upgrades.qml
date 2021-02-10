import QtQuick		2.12
import JASP.Module	1.0

Upgrades
{
	Upgrade
	{
		functionName: 		"AnalysisA"
		newFunctionName:	"AnalysisB"
		fromVersion:		"0.1"
		toVersion:			"0.1"
	
		ChangeRename
		{
			condition:	function(options) { return options$frequencyTables === true; } 
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