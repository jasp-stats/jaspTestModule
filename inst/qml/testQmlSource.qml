import QtQuick 			2.8
import JASP.Controls 	1.0

Form 
{

	VariablesForm
	{
		AvailableVariablesList
		{
			name: "fromR"
			source: ["exampleSourceId"]
		}

		AssignedVariablesList
		{
			name: "assignMe"
		}
	}
}

