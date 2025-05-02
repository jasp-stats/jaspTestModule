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
