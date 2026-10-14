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

#' Test Table View
#'
testTableView <- function(
          data = NULL,
          version = "1",
          diagonalTable = list(list(levels = list(), name = "data 1", values = list())),
          minimumLevels = 2,
          numberOfRows = 2,
          numberOfRows2 = 1,
          plotHeight = 320,
          plotWidth = 480,
          testButtons = list(list(levels = "Row 0", name = "data 1", values = "A"), list(levels = "Row 0", name = "data 2", values = "a"), list(levels = "Row 0", name = "data 3", values = "a")),
          testTypes = list(list(levels = list("Row 0", "Row 1"), name = "data 1", values = list("A", "B")), list(levels = list("Row 0", "Row 1"), name = "data 2", values = list("2", "2")), list(levels = list("Row 0", "Row 1"), name = "data 3", values = list(4, 4)))) {

   defaultArgCalls <- formals(jaspTestModule::testTableView)
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

   optionsWithFormula <- c("diagonalTable", "testButtons", "testTypes")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "testTableView", "testTableView.qml", options, version, FALSE))
}