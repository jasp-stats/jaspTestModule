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

#' Test Sources with special attributes
#'
testSpecialSourcesFunc <- function(
          data = NULL,
          version = "1",
          assigned = list(types = list(), value = list()),
          combinationCross = list(),
          combinations2way = list(),
          combinations3way = list(),
          compList = list(list(dropDownValuesa = list(types = "unknown", value = ""), value = "#")),
          controlVariables = "",
          labelsFor1Variable = "",
          labelsForSeveralVariable = "",
          ordinalAndNominalVariables = list(types = "unknown", value = ""),
          ordinalVariables = list(types = "unknown", value = ""),
          plotHeight = 320,
          plotWidth = 480,
          scaleVariables = list(types = "unknown", value = ""),
          selectedVariables = list(types = list(), value = list()),
          selectedVariablesWithControls = list(optionKey = "variable", types = list(), value = list()),
          selectedVariablesWithControls2 = list(optionKey = "variable", types = list(), value = list()),
          severalVariablesWithLabels = list(types = list(), value = list()),
          variableWithLabels = list(types = list(), value = ""),
          variables = list(types = list(), value = list()),
          variablesWithConditions = list(types = list(), value = list()),
          variablesWithConditions2 = list(types = list(), value = list())) {

   defaultArgCalls <- formals(jaspTestModule::testSpecialSourcesFunc)
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

   optionsWithFormula <- c("assigned", "combinationCross", "combinations2way", "combinations3way", "compList", "controlVariables", "labelsFor1Variable", "labelsForSeveralVariable", "ordinalAndNominalVariables", "ordinalVariables", "scaleVariables", "selectedVariables", "selectedVariablesWithControls", "selectedVariablesWithControls2", "severalVariablesWithLabels", "variableWithLabels", "variables", "variablesWithConditions", "variablesWithConditions2")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "testSpecialSourcesFunc", "testSpecialSources.qml", options, version, FALSE))
}