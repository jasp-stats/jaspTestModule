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

#' Test jaspState
#'
testStateFunc <- function(
          data = NULL,
          version = "1",
          checkbox_0 = FALSE,
          checkbox_1 = FALSE,
          plotHeight = 320,
          plotWidth = 480,
          saveMe = "Blablabla",
          tabview = list(list(checkbox_2 = FALSE, tabviewOptions = "Tab 1", variablesForStateTab2 = list(types = list(), value = list()), variablesTab1 = list(types = list(), value = list()))),
          variables = list(types = list(), value = list()),
          variablesForState = list(types = list(), value = list())) {

   defaultArgCalls <- formals(jaspTestModule::testStateFunc)
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

   optionsWithFormula <- c("tabview", "variables", "variablesForState")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "testStateFunc", "testState.qml", options, version, FALSE))
}