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
	columns: 1
	DoubleField
	{
		id: defaultLower
		label: "Set lower default"
		name: "lowerDefault"
		value: 0.1
	}

	DoubleField
	{
		id:		lower
		name:	"lower"
		label:  "Lower"
		max:	upper.value
		defaultValue: defaultLower.value
		min:	0
	}

	DoubleField
	{
		id:		upper
		name:	"upper"
		label:  "Upper Exclusive"
		min:	lower.value
		defaultValue: 0.50
		max:	1
		inclusive: JASP.MinOnly
	}
}
