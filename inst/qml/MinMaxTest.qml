//
// Copyright (C) 2013-2019 University of Amsterdam
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
			"This analysis checks default values of Integer & Double Fields with min/max constraints<br>" +
			"A default value can be set for Integer & Double Fields. This default value can have a binding with another value: in this case, if the binding value changes, and the Integer/Double fields has still the default value, then the value of the Integer/Double fields should change accordingly.<br>" +
			"Also an Integer/Double Fields can have min/max constraints. To simulate range value, 2 fields set the lower and upper values of each other: the first field sets the min of the second field, and the second field sets the max of the first field<br>" +
			"Moreover there can be a min constraint of the lower bound, and a max constraint of the upper bound.<br>" +
			"It is then important that warning/error constraint messages are clear for the user.<br>" +
			"Here the min lower bound is 0, and the max upper bound is 1 (exclusive) for the double field and 10 (exclusive) for the integer field." +
			"<ul>" +
			"<li>Change the default value of the Default Double/Integer Lower Bound fields (between 0 and the upper bound) and check that the Double/Integer Lower Bound changes accordingly.</li>" +
			"<li>Change the Double/Integer Bound fields (between 0 and the upper bound) so that it gets another value than its default value. Change the default value: check that the Upper Bound values do not change</li>" +
			"<li>Check that you cannot set a negative value to the Lower bound fields</li>" +
			"<li>Check that if you set 1 for the Double Upper Bound (and 10 for the Integer Upper Bound) then you get a temporary error message, and the last valid value is set back automatically</li>" +
			"<li>Check that if you set the Lower Bound values to a higher value that the one in Upper Bound, then you get a temporary error message, and the last valid value is set back automatically</li>" +
			"<li>Set the Default Lower Bound values and the Lower Bound values equal again. Change then the Default Lower Bound values to a higher value than the Upper Bound value: check that you get 1 or 2 error messages for the Lower and Upper bound fields</li>" +
			"<li>Duplicate the analysis, and check that the values are the same even if the lower value is the same as the default value or not.</li>" +
			"</ul>"
	}


	Group
	{
		title: "Double Range TextFields"
		DoubleField
		{
			id: defaultDoubleLower
			label: "Default Double Lower Bound"
			name: "lowerIntegerDefault"
			value: 0.1
		}

		DoubleField
		{
			id:		doubleLower
			name:	"doubleLower"
			label:  "Double Lower Bound"
			max:	doubleUpper.value
			defaultValue: defaultDoubleLower.value
			min:	0
		}

		DoubleField
		{
			id:		doubleUpper
			name:	"doubleUpper"
			label:  "Double Upper Bound (Exclusive)"
			min:	doubleLower.value
			defaultValue: 0.50
			max:	1
			inclusive: JASP.MinOnly
		}
	}
	Group
	{
		title: "Integer Range TextFields"
		IntegerField
		{
			id: defaultIntegerLower
			label: "Default Integer Lower Bound"
			name: "lowerDefault"
			value: 1
		}

		IntegerField
		{
			id:		integerLower
			name:	"integerLower"
			label:  "Integer Lower Bound"
			max:	integerUpper.value
			defaultValue: defaultIntegerLower.value
			min:	0
		}

		IntegerField
		{
			id:		integerUpper
			name:	"integerUpper"
			label:  "Integer Upper Bound (Exclusive)"
			min:	integerLower.value
			defaultValue: 5
			max:	10
			inclusive: JASP.MinOnly
		}
	}

	ExplanationText
	{
		text: "Test also range controls that use FormulaField.<br>" +
			  "The default values is set to \"-1\" (as string) and 1 as integer: you should be able to initializa FormulaField with both string and integer/double.<br>" +
			  "Afterwards you can set the values with 1/2 or sin(1) and check that the min/max is still respected."
	}

	Group
	{
		title: "Range using FormulaFields."
		FormulaField
		{
			id:					leftInput
			name:				"leftFormula"
			defaultValue:		"-1"
			min:				-Infinity
			max:				rightInput.realValue
		}

		FormulaField
		{
			id:					rightInput
			name:				"rightFormula"
			defaultValue:		1
			realValue:			1
			min:				leftInput.realValue
			max:				Infinity
		}
	}
}
