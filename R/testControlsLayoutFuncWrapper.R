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

#' Test Controls layout
#'
#' @param meanCiLevel, width of the confidence interval.
#' @param meanCiMethod, How should the confidence interval be computed? By default, we use a `T model`, which yields results identical to a one-sample t-test. Alternative options are a normal model ($\bar{x} \pm z_{95} \times SE$), or `Bootstrap`.
#' @param sdCi, a confidence interval for the standard deviation based on bootstrap samples.
#'    Defaults to \code{FALSE}.
testControlsLayoutFunc <- function(
          data = NULL,
          version = "1",
          checkBoxSecondLevel = FALSE,
          checkboxWithSeveralLevels = FALSE,
          doubleInGroup = 0,
          dropDownInGroup = list(types = "unknown", value = ""),
          dropDownNominal = list(types = "unknown", value = ""),
          dropDownOrdinal = list(types = "unknown", value = ""),
          dropDownScale = list(types = "unknown", value = ""),
          dropDownSecondLevel = "one",
          dropDownStartValue = "really long values!!!!!",
          dropDownValues = "one",
          dropDownValuesAbove = "one",
          dropDownValuesEmptyValue = "",
          dropDownValuesFixed = "one",
          dropDownValuesFixedAbove = "one",
          dropDownValuesFixedEmptyValue = "",
          dropDownValuesFixedStartValue = "really long values!!!!!",
          dropDownVariables = list(types = "unknown", value = ""),
          dropDownVariablesEmptyValue = "",
          dropDownVariablesFixed = list(types = "unknown", value = ""),
          dropDownVariablesFixedEmptyValue = list(types = "unknown", value = ""),
          dropDownVariablesFixedLabelAbove = list(types = "unknown", value = ""),
          dropDownVariablesFixedStartIndex = list(types = "unknown", value = ""),
          dropDownVariablesLabel = list(types = "unknown", value = ""),
          dropDownVariablesStartIndex = list(types = "unknown", value = ""),
          intValue = 0,
          integerFirstLevel = 0,
          integerSecondLevel = 0,
          maxLevels = 100,
          maxNumeric = 100,
          meanCi = FALSE,
          meanCiLevel = 0.95,
          meanCiMethod = "oneSampleTTest",
          minLevels = -1,
          minNumeric = -1,
          percentFirstLevel = 0.5,
          percentileValues = list(),
          percentiles = FALSE,
          plotHeight = 320,
          plotWidth = 480,
          quantilesForEqualGroups = FALSE,
          quantilesForEqualGroupsNumber = 0,
          quartiles = FALSE,
          sdCi = FALSE,
          sdCiLevel = 0.95,
          sdCiMethod = "chiSquaredModel",
          seMean = FALSE,
          textInGroup = "") {

   defaultArgCalls <- formals(jaspTestModule::testControlsLayoutFunc)
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

   optionsWithFormula <- c("dropDownInGroup", "dropDownNominal", "dropDownOrdinal", "dropDownScale", "dropDownSecondLevel", "dropDownStartValue", "dropDownValues", "dropDownValuesAbove", "dropDownValuesEmptyValue", "dropDownValuesFixed", "dropDownValuesFixedAbove", "dropDownValuesFixedEmptyValue", "dropDownValuesFixedStartValue", "dropDownVariables", "dropDownVariablesEmptyValue", "dropDownVariablesFixed", "dropDownVariablesFixedEmptyValue", "dropDownVariablesFixedLabelAbove", "dropDownVariablesFixedStartIndex", "dropDownVariablesLabel", "dropDownVariablesStartIndex", "meanCiMethod", "sdCiMethod")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "testControlsLayoutFunc", "testControlsLayout.qml", options, version, FALSE))
}