//
// Copyright (C) 2013-2026 University of Amsterdam
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.
//
import QtQuick
import JASP.Controls
import JASP
import "./common"

Form
{
	ExplanationText
	{
		text:
		"This tests the term specification of the Factors Form (advancedAvailable). Each Factors Form below takes its variables from 'Variables'; each has a table in the output with, per model, the formula that jaspBase::prepareModelTerms() makes of its option. With a dependent variable the models are also fitted with lm(), and the table shows the coefficients with the labels the form gives them.<br>" +
		"Assign a continuous variable, a nominal or ordinal one and a dependent variable first. Then, in each form:<br>" +
		"- Click 'Specify': the table replaces the lists and keeps their height, so the page does not move; with many rows the rows scroll and the header and the buttons stay. Each variable has a base row; change its specification (e.g. Natural log, Natural cubic spline with df 4, Sum coding) and check that the term is renamed in the models and in the output.<br>" +
		"- Add a row with +: choose a variable, then a specification and its parameters (Tab moves between the fields and keeps the focused field in view). Add a constant offset where it is offered. Remove an added row with its x.<br>" +
		"- Back: the available list offers the defined terms and '(Intercept)'. Assign them to the models, interactions included (select several and use the arrow); an interaction with '(Intercept)' or an offset is removed again.<br>" +
		"- The expand icon in the corner of a model shows its terms full width, at the same height; remove a term there.<br>" +
		"- Rename a variable or a level in the data: the definitions, the terms and the output follow.<br>" +
		"- Reset switches the term specification off: the models get the variables of their terms back.<br>" +
		"- Duplicate the analysis, and save and reopen the file: the definitions, the models and the output stay the same."
	}

	VariablesForm
	{
		AvailableVariablesList	{ name: "allVariables" }
		AssignedVariablesList	{ name: "dependent";	title: "Dependent (optional: fits the models)";	singleVariable: true;	allowedColumns: ["scale"] }
		AssignedVariablesList	{ name: "variables";	title: "Variables";								allowedColumns: ["scale", "ordinal", "nominal"] }
	}

	Section
	{
		title:		"Optional intercept, every specification and restrictions"
		expanded:	true

		ExplanationText
		{
			text:
			"Every specification of the catalogue (jaspBase inst/modelTermSpecifications.json) is offered here: the defaults, and the ones a form has to list (offset, constant offset, rank, normal scores, Arrhenius, indicators). The Restriction column fixes coefficients (one number per column of a term, or empty for free). '(Intercept)' can be removed from each model; indicator coding needs a model without it."
		}

		FactorsForm
		{
			name:							"optionalTerms"
			availableVariablesListName:		"optionalTermsAvailable"
			availableVariablesList.source:	"variables"
			allowInteraction:				true
			initNumberFactors:				2
			baseName:						"model"
			baseTitle:						"Model"
			startIndex:						0
			allowedColumns:					[]
			advancedAvailable:				true
			restrictionAvailable:			true
			continuousSpecifications:		["default", "offset", "offsetConstant", "rank", "normalScores", "arrhenius"]
			categoricalSpecifications:		["default", "indicator"]
		}
	}

	Section
	{
		title: "Forced intercept, on from the start"

		ExplanationText
		{
			text:
			"This form starts with the term specification on (advanced: true) and every model has an intercept (interceptMode: 'forced'), so '(Intercept)' is not a term to assign. Only the default specifications are offered, so the specifications that need the support of the analysis (offsets, rank, ...) must not be in the drop-downs."
		}

		FactorsForm
		{
			name:							"forcedTerms"
			availableVariablesListName:		"forcedTermsAvailable"
			availableVariablesList.source:	"variables"
			allowInteraction:				true
			initNumberFactors:				1
			baseName:						"model"
			baseTitle:						"Model"
			startIndex:						0
			allowedColumns:					[]
			advancedAvailable:				true
			advanced:						true
			interceptMode:					"forced"
		}
	}

	Section
	{
		title: "No intercept"

		ExplanationText
		{
			text:
			"Here no model has an intercept once the term specification is on (interceptMode: 'none', as in a Cox regression): '(Intercept)' is neither a row of the table nor a term, and the formulas start with '0 +'. Before 'Specify' the form is a plain Factors Form, with an intercept."
		}

		FactorsForm
		{
			name:							"noInterceptTerms"
			availableVariablesListName:		"noInterceptTermsAvailable"
			availableVariablesList.source:	"variables"
			allowInteraction:				true
			initNumberFactors:				1
			baseName:						"model"
			baseTitle:						"Model"
			startIndex:						0
			allowedColumns:					[]
			advancedAvailable:				true
			interceptMode:					"none"
		}
	}

	Section
	{
		title: "Without the term specification"

		ExplanationText
		{
			text:
			"The same Factors Form without advancedAvailable: there is no 'Specify' button and no expand icon, and the option is exactly the one Factors Forms always had (compare it in the options table with the forms above)."
		}

		FactorsForm
		{
			name:							"basicTerms"
			availableVariablesListName:		"basicTermsAvailable"
			availableVariablesList.source:	"variables"
			allowInteraction:				true
			initNumberFactors:				1
			baseName:						"model"
			baseTitle:						"Model"
			startIndex:						0
			allowedColumns:					[]
		}
	}
}
