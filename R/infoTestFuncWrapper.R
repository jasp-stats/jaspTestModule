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

#' info testing
#'
#' This is a bunch of info on a form!
#'
#' @param barPlot, Displays the sample means as bars and the confidence intervals or standard errors as error bars for each measure.
#'    Defaults to \code{FALSE}.
#' @param barPlotYAxisFixedToZero, Fix horizontal axis to 0: Forces the graph to show the default x-axis at y = 0
#'    Defaults to \code{TRUE}.
#' @param cells, assigned RM
#' @param checkbox, Check this out
#'    Defaults to \code{FALSE}.
#' @param doubleFieldWithAfterLabel, this is in doublefield that has a label and an afterLabel
#' @param dropDown, dropdown with info on each value
#' \itemize{
#'   \item \code{"high"} (default) : So High!
#'   \item \code{"medium"}: Middling
#'   \item \code{"low"}: Down low
#'   \item \code{"custom"}: Who knows?
#' }
#' @param dropdownVariableAndExtraValues, You can choose one of the variables or special values
#' @param dropdownVariables, You can choose one of the variables
#' @param integerFieldWithAfterLabel, this is in integerfield that has a label and an afterLabel
#' @param paairs, assigned pairs
#' @param radiobuttongroup, A grouping of buttons of radio
#' \itemize{
#'   \item \code{"rButton2"}: and more info on the other button
#'   \item \code{"rButton1"}: and some info on button
#' }
#' @param repeatedMeasuresFactors, FactorLevelList
#' @param simpleTableView, a tableview with some info
#' @param slideOnOuttaHere, slip and slide suicide
#' @param tabview, This is an info field on a tabview
#' @param varA, assigned variables nominal allowed
infoTestFunc <- function(
          data = NULL,
          version = "1",
          barPlot = FALSE,
          barPlotCiLevel = 0.95,
          barPlotErrorType = "ci",
          barPlotYAxisFixedToZero = TRUE,
          cells = list(),
          checkbox = FALSE,
          doubleFieldWithAfterLabel = 0,
          dropDown = "high",
          dropdownVariableAndExtraValues = list(types = "unknown", value = "one"),
          dropdownVariables = list(types = "unknown", value = ""),
          dropdownWithVariablesSource = list(types = "unknown", value = ""),
          integerFieldWithAfterLabel = 1000,
          paairs = list(),
          plotHeight = 320,
          plotWidth = 480,
          radiobuttongroup = "rButton2",
          repeatedMeasuresFactors = list(list(levels = list("Level 1", "Level 2"), name = "RM Factor 1")),
          simpleTableView = list(),
          slideOnOuttaHere = 0.5,
          tabview = list(list(marginalMean = FALSE, name = "NEW ITEM", summary = FALSE, syntax = "")),
          varA = list(types = list(), value = list())) {

   defaultArgCalls <- formals(jaspTestModule::infoTestFunc)
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

   optionsWithFormula <- c("cells", "dropDown", "dropdownVariableAndExtraValues", "dropdownVariables", "dropdownWithVariablesSource", "paairs", "repeatedMeasuresFactors", "simpleTableView", "tabview", "varA")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "infoTestFunc", "TestInfo.qml", options, version, FALSE))
}