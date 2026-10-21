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

#' Test Multi-DataSet Controls
#'
#' @param datasets a named list of data.frames keyed by DATASET TITLE - the titles the
#'   dataset selection options of this form carry (their defaults below, rendered as the
#'   selection surface, e.g. "Iris" or "Iris - myfilter"). Every entry is loaded standalone
#'   into the bridge workspace (runWrappedAnalysis stores them via jaspSyntax::loadDataSets,
#'   each under its own name as the dataset title); the analysis itself receives its slices
#'   keyed by filter id - the jaspBase datasets contract (see jaspBase::runJaspResults).
multiDataSetControlsFunc <- function(
          datasets = NULL,
          version = "1",
          assignedA = list(types = list(), value = list()),
          assignedDefault = list(types = list(), value = list()),
          assignedDerived = list(types = list(), value = list()),
          assignedK = list(types = list(), value = list()),
          assignedThree = list(types = list(), value = list()),
          boundG = list(types = list(), value = list()),
          codeF = list(columns = list(), model = "", modelOriginal = ""),
          comboA = list(types = "unknown", value = ""),
          comboG = "first",
          comboI = list(types = "unknown", value = ""),
          dataSetA = "",
          dataSetD = "",
          dataSetF = "",
          dataSetG = "",
          dataSetJ = "",
          dataSetK = "",
          dataSetM3 = "",
          doubleH = 1.5,
          factorsE = list(),
          factorsK = list(list(indicators = list(), name = "Fac1", title = "Factor 1")),
          gateH = FALSE,
          gatedH = 10,
          interactionD = list(optionKey = "components", types = list(), value = list()),
          pairsJ = list(),
          plainSwitch = FALSE,
          plotHeight = 320,
          plotWidth = 480,
          radioH = "mean",
          rowsC = list(optionKey = "variable", types = list(), value = list()),
          rowsH = 5,
          showMeta = FALSE,
          sliderH = 0.5,
          tableL = list(list(levels = list("Row 0", "Row 1", "Row 2", "Row 3", "Row 4"), name = "data 1", values = list(1, 2, 3, 4, 5)), list(levels = list("Row 0", "Row 1", "Row 2", "Row 3", "Row 4"), name = "data 2", values = list(0.5, 1, 1.5, 2, 2.5))),
          textH = "") {

   defaultArgCalls <- formals(jaspTestModule::multiDataSetControlsFunc)
   defaultArgs <- lapply(defaultArgCalls, eval)
   options <- as.list(match.call())[-1L]
   options <- lapply(options, eval)
   defaults <- setdiff(names(defaultArgs), names(options))
   options[defaults] <- defaultArgs[defaults]
   options[["datasets"]] <- NULL
   options[["version"]] <- NULL


   # mds-plan D8.3: `datasets` must be a named list of data.frames keyed by DATASET TITLE - the
   # titles the dataset selection options of this form carry (e.g. list(Iris = iris, Sleep = sleep)).
   # No positional pin: the dataset that plays `data` (the frame the formula machinery evaluates
   # against) is the first selection option whose effective value names one of the loaded datasets,
   # resolved at run time from `options`. Every entry is loaded standalone by runWrappedAnalysis
   # (jaspBase::storeDataSets -> jaspSyntax::loadDataSets, each under its own name as the dataset
   # title); the analysis itself receives its slices keyed by filter id (jaspBase datasets contract).
   selectionOptions <- c("dataSetK", "dataSetG", "dataSetF", "dataSetJ", "dataSetM3", "dataSetA", "dataSetD")
   data <- NULL
   if (!is.null(datasets) && length(datasets)) {
      for (selectionOption in selectionOptions) {
         selectionValue <- options[[selectionOption]]
         if (!is.character(selectionValue) || length(selectionValue) != 1L || is.na(selectionValue) || !nzchar(selectionValue)) next
         if (selectionValue %in% names(datasets)) { data <- datasets[[selectionValue]]; break }
         bareTitle <- sub(" - [^-]*$", "", selectionValue) # 'Title - filterName' surface: bare-title fallback, best effort
         if (bareTitle %in% names(datasets)) { data <- datasets[[bareTitle]]; break }
      }
   if (is.null(data)) {
      if (length(selectionOptions))
         stop("`datasets` must be a named list keyed by dataset title (e.g. list(Iris = iris)): the dataset selection option(s) ", paste(selectionOptions, collapse = ", "), " select a title matching none of: ", paste(names(datasets), collapse = ", "))
      data <- datasets[[1L]] # this form has no dataset selection surface: the first entry is the documented primary (jaspSyntax::loadDataSets)
   }
   }

   optionsWithFormula <- c("assignedA", "assignedDefault", "assignedDerived", "assignedK", "assignedThree", "boundG", "codeF", "comboA", "comboG", "comboI", "dataSetA", "dataSetD", "dataSetF", "dataSetG", "dataSetJ", "dataSetK", "dataSetM3", "factorsE", "factorsK", "interactionD", "pairsJ", "rowsC", "tableL")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "multiDataSetControlsFunc", "testMultiDataSetControls.qml", options, version, TRUE, datasets = datasets))
}