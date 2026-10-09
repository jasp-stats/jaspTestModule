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

#' Test Multi-DataSet
#'
multiDataSetFunc <- function(
          datasets = NULL,
          version = "1",
          dataSetA = list(types = "unknown", value = ""),
          dataSetB = list(types = "unknown", value = ""),
          dependentA = list(types = list(), value = list()),
          dependentB = list(types = list(), value = list()),
          guardDemo = FALSE,
          plotHeight = 320,
          plotWidth = 480,
          showMeta = FALSE) {

   defaultArgCalls <- formals(jaspTestModule::multiDataSetFunc)
   defaultArgs <- lapply(defaultArgCalls, eval)
   options <- as.list(match.call())[-1L]
   options <- lapply(options, eval)
   defaults <- setdiff(names(defaultArgs), names(options))
   options[defaults] <- defaultArgs[defaults]
   options[["datasets"]] <- NULL
   options[["version"]] <- NULL


   data <- if (!is.null(datasets) && length(datasets)) datasets[[1]] else NULL

   optionsWithFormula <- c("dataSetA", "dataSetB", "dependentA", "dependentB")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "multiDataSetFunc", "testMultiDataSet.qml", options, version, TRUE, datasets = datasets))
}