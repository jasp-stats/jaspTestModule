//
// Copyright (C) 2013-2025 University of Amsterdam
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
import JASP
import JASP.Controls
import "./common"

Form
{
	columns: 2

	ExplanationText
	{
		text:
			"This analysis checks values in Formula, Integer & Double Fields<br>" +
			"Each field show its value in its label, and for Formula fields, it shows also the real value.<br>" +
			"Check that you can set infinity value for Double and Formula fields, also that the real values for formula fields are updated.<br>" +
			"Check that you cannot set more decimals than allowed in Double Fields.<br>" +
			"Set decimals with comma ',' or dot'.', and check that the values set in the label are always in English format (with dot).<br>" +
			"Change the Language and Alternative language to check that the dots and commas correspond to the chosen language, but the label get the always the English fomat.<br>" +
			"Duplicate the analysis, and check that the values are the same."
	}


	Group
	{
		title: "Formula fields"
		FormulaField
		{
			label: "Default infinity: " + value + ", real value: " + realValue
			name: "formulaInfinity"
			value: "Inf"
		}

		FormulaField
		{
			label: "Default min infinity: " + value + ", real value: " + realValue
			name: "formulaMinInfinity"
			value: "-Inf"
		}

		FormulaField
		{
			label: "Default nan: " + value + ", real value: " + realValue
			name: "formulaNan"
			value: "nan"
		}

		FormulaField
		{
			label: "Default 1/2: " + value + ", real value: " + realValue
			name: "formulaHalf"
			value: "1/2"
		}
	}

	Group
	{
		title: "Double fields"
		DoubleField
		{
			label: "Default infinity: " + value
			name: "doubleInfinity"
			value: Infinity
		}

		DoubleField
		{
			label: "Default min infinity: " + value
			name: "doubleMinInfinity"
			value: -Infinity
			negativeValues: true
		}

		DoubleField
		{
			label: "Default with 1 decimals: " + value
			name: "doubleWith1Decimals"
			value: 0.1
			decimals: 1
			fieldWidth: 100
			negativeValues: true
		}

		DoubleField
		{
			label: "Default with 3 decimals (default): " + value
			name: "doubleWith3Decimals"
			value: 0.123
			fieldWidth: 100
			negativeValues: true
		}

		DoubleField
		{
			label: "Default with 5 decimals: " + value
			name: "doubleWith5Decimals"
			value: 0.12345
			decimals: 5
			fieldWidth: 100
			negativeValues: true
		}

	}

	Group
	{
		title: "Integer fields"
		IntegerField
		{
			label: "Default 1 + 1: " + value
			name: "integerInfinity"
			value: 1 + 1
		}
	}
}
