#
# Copyright (C) 2013-2025 University of Amsterdam
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# This is a generated file. Don't change it!

#' ToolTip
#'
#' @param IntegerWithInfo, Field with info
#' @param IntegerWithTooLongValueAndInfo, Field with info and too long value
#' @param checkBoxWithInfo, Great info
#'    Defaults to \code{FALSE}.
#' @param checkBoxWithInfoAndTooltip, Great info
#'    Defaults to \code{FALSE}.
#' @param checkBoxWithSubCheckBox, Info for checkbox with sub checkboxes
#'    Defaults to \code{FALSE}.
#' @param dropDownLabelAbove, Dropdown with info and label above
#' @param dropDownLabelAboveWithExtraInfo, Dropdown with extra info for value 'Two' and label above
#' \itemize{
#'   \item \code{"one"} (default) 
#'   \item \code{"two"}: Extra info for Two
#'   \item \code{"three"}
#' }
#' @param dropdownWithExtraInfo, Dropdown with info
#' \itemize{
#'   \item \code{"one"} (default) : This is one
#'   \item \code{"two"}
#' }
#' @param dropdownWithInfo, Dropdown with info
#' @param radioButtonsWithInfo, Info for the RadioButton group
#' \itemize{
#'   \item \code{"radioWithoutInfo"}
#'   \item \code{"radioWithInfo"}: Info just for this RadioButton
#' }
#' @param rowRadioButtonsWithInfo, Info for the Row RadioButton group
#' \itemize{
#'   \item \code{"radioWithoutInfo"}
#'   \item \code{"radioWithInfo"}: Info just for this RadioButton
#' }
#' @param rowRadioButtonsWithoutLabelWithInfo, No label but an info
#' \itemize{
#'   \item \code{"one"}
#'   \item \code{"two"}
#' }
#' @param subCheckBoxWithInfo, Info for Sub CheckBox
#'    Defaults to \code{FALSE}.
tooltipFunc <- function(
          data = NULL,
          version = "1",
          IntegerWithInfo = 0,
          IntegerWithTooLongValue = 1234567,
          IntegerWithTooLongValueAndInfo = 1234567,
          RadioButtonGroup1 = "group1RadioButton1",
          RadioButtonGroup2 = "group2RadioButton1",
          checkBoxWithInfo = FALSE,
          checkBoxWithInfoAndTooltip = FALSE,
          checkBoxWithSubCheckBox = FALSE,
          checkBoxWithTooltip = FALSE,
          checkBoxWithoutTootip = FALSE,
          dropDownLabelAbove = "one",
          dropDownLabelAboveWithExtraInfo = "one",
          dropdownWithExtraInfo = "one",
          dropdownWithInfo = "one",
          plotHeight = 320,
          plotWidth = 480,
          radioButtons = "radioWithoutInfo",
          radioButtonsWithInfo = "radioWithoutInfo",
          rowRadioButtons = "radioWithInfo",
          rowRadioButtonsWithInfo = "radioWithoutInfo",
          rowRadioButtonsWithoutLabelWithInfo = "one",
          rowRadioButtonsWithoutLabelWithoutInfo = "two",
          subCheckBoxWithInfo = FALSE,
          subCheckBoxWithoutInfo = FALSE) {

   defaultArgCalls <- formals(jaspTestModule::tooltipFunc)
   defaultArgs <- lapply(defaultArgCalls, eval)
   options <- as.list(match.call())[-1L]
   options <- lapply(options, eval)
   defaults <- setdiff(names(defaultArgs), names(options))
   options[defaults] <- defaultArgs[defaults]
   options[["data"]] <- NULL
   options[["version"]] <- NULL


   if (!jaspBase::jaspResultsCalledFromJasp() && !is.null(data)) {
      jaspBase::storeDataSet(data)
   }

   optionsWithFormula <- c("dropDownLabelAbove", "dropDownLabelAboveWithExtraInfo", "dropdownWithExtraInfo", "dropdownWithInfo")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "tooltipFunc", "Tooltip.qml", options, version, FALSE))
}