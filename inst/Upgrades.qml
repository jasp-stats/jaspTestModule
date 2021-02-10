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
			jsonValue:	["contNormal", "contExpon"] 
		}
		
		ChangeJS
		{
			name:		"colorPalette"
			jsFunction: function(option)
			{
				console.log("ChangeJS actually works!")
				
				if(option["colorPalette"] === "colorblind")	return "viridis";
				else										return "colorblind";
			}
		}
	}
}