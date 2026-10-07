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

#' Test Variables Form
#'
testVariablesForm <- function(
          data = NULL,
          version = "1",
          addCheckBox = FALSE,
          addDropDown = FALSE,
          maxLevel = -1,
          maxNumLevel = -1,
          minLevel = -1,
          minNumLevel = -1,
          nominal = FALSE,
          ordinal = FALSE,
          plotHeight = 320,
          plotWidth = 480,
          scale = TRUE,
          setType = list(types = "unknown", value = ""),
          toggleRemoveInvisibles = FALSE,
          toggleVisibility = TRUE,
          varS = list(types = list(), value = list()),
          varToggle = list(types = list(), value = list()),
          variablesWithControls = list(optionKey = "variable", types = list(), value = list())) {

   defaultArgCalls <- formals(jaspTestModule::testVariablesForm)
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

   optionsWithFormula <- c("setType", "varS", "varToggle", "variablesWithControls")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "testVariablesForm", "testVariablesForm.qml", options, version, FALSE))
}