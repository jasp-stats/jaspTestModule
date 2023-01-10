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
import QtQuick 			2.8
import QtQuick.Layouts 	1.3
import JASP
import JASP.Controls 	1.0

Form 
{
	columns: 2
	Group
	{
		title: "Double TextFields"
		DoubleField
		{
			id: defaultDoubleLower
			label: "Set lower integer default"
			name: "lowerIntegerDefault"
			value: 0.1
		}

		DoubleField
		{
			id:		doubleLower
			name:	"doubleLower"
			label:  "Double Lower"
			max:	doubleUpper.value
			defaultValue: defaultDoubleLower.value
			min:	0
		}

		DoubleField
		{
			id:		doubleUpper
			name:	"doubleUpper"
			label:  "Upper Double Exclusive"
			min:	doubleLower.value
			defaultValue: 0.50
			max:	1
			inclusive: JASP.MinOnly
		}
	}
	Group
	{
		title: "Integer TextFields"
		IntegerField
		{
			id: defaultIntegerLower
			label: "Set lower Integer default"
			name: "lowerDefault"
			value: 1
		}

		IntegerField
		{
			id:		integerLower
			name:	"integerLower"
			label:  "Integer Lower"
			max:	integerUpper.value
			defaultValue: defaultIntegerLower.value
			min:	0
		}

		IntegerField
		{
			id:		integerUpper
			name:	"integerUpper"
			label:  "Integer Upper Exclusive"
			min:	integerLower.value
			defaultValue: 5
			max:	10
			inclusive: JASP.MinOnly
		}
	}

}
