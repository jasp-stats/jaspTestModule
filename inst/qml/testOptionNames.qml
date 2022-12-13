import QtQuick
import JASP
import JASP.Controls

Form
{
    Formula { name: "formula" }
    VariablesForm
    {
        AvailableVariablesList { name: "allVariables"; title: "allVariables" }
        AssignedVariablesList { name: 'variables'; title: "variables" }
    }

    CheckBox
    {
        label: "allVariables: the Available Variables List has the same name."
        name: "allVariables"
    }

    RadioButtonGroup
    {
        title: "Test Radio Buttons"
        name: "myRadioButton"

        RadioButton { name: "data"; label: "data: No error expected" }
        RadioButton { name: "version"; label: "version: No error expected" }
        RadioButton { name: "jhsdf7634(*&(&))"; label: "jhsdf7634(*&(&))" }
    }

    CheckBox
    {
        label: "version: Error expected"
        name: "version"
    }
    CheckBox
    {
        label: "data: Error expected"
        name: "data"
    }

    CheckBox
    {
        label: "*^&*^&%jkkh"
        name: "*^&*^&%jkkh"
    }

    CheckBox
    {
        label: "if clicked name is changed to version"
        name: "test"
        onClicked: { name = "version"; }
    }

    CheckBox
    {
        label: "one"
        name: "one"
    }
    CheckBox
    {
        label: "one: 2 checkboxes with same name: error expected!"
        name: "one"
    }
    CheckBox
    {
        label: "if clicked, name is changed to one"
        name: "two"
        onClicked: {name = "one" }
    }

    CheckBox
    {
        label: "Formula: same name as formula: Error Expected"
        name: "formula"
    }
    CheckBox
    {
        label: "If clicked name is changed to formula"
        name: "noformula"
        onClicked: { name = "formula" }
    }

}
