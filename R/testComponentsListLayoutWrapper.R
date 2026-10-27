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

#' Test ComponentsList & TableView layout
#'
testComponentsListLayout <- function(
          data = NULL,
          version = "1",
          addBorderCheck = TRUE,
          addItemManuallyCheck = TRUE,
          buttonsInRowCheck = FALSE,
          columns = "3",
          componentsList = list(local({ .l <- list("#", "Second column", "Third column", "First hypothesis", "#"); names(.l) <- c("", "col2", "col3", "hypothesis", "value"); .l }), local({ .l <- list("#2", "Second hypothesis", "#2"); names(.l) <- c("", "hypothesis", "value"); .l }), list(col2 = "col 2", col3 = "col 3", col4 = "col 4", col5 = "col 5", col6 = "col 6", hypothesis = "Hypothesis 3", value = "#3"), list(col2 = "col 2", col3 = "col 3", col4 = "col 4", col5 = "col 5", col6 = "col 6", hypothesis = "Hypothesis 4", value = "#4")),
          contrasts = list(optionKey = "variable", types = list(), value = list()),
          customContrasts = list(),
          fixedFactors = list(optionKey = "components", types = list(), value = list()),
          headers = "Header with array",
          heightCheck = FALSE,
          plotHeight = 320,
          plotWidth = 480,
          showButtonsCheck = TRUE,
          showTitleCheck = FALSE,
          tableHeightCheck = FALSE,
          tableView = list(list(levels = list(), name = "data 1", values = list()), list(levels = list(), name = "data 2", values = list()))) {

   defaultArgCalls <- formals(jaspTestModule::testComponentsListLayout)
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

   optionsWithFormula <- c("columns", "componentsList", "contrasts", "customContrasts", "fixedFactors", "headers", "tableView")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "testComponentsListLayout", "testComponentsListLayout.qml", options, version, FALSE))
}