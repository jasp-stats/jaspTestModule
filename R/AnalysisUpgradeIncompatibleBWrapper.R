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

#' Analysis B but then incompatible
#'
#' @param stemAndLeaf, Create a Stem and leaf table.
#'    Defaults to \code{FALSE}.
#' @param stemAndLeafScale, The scale parameter controls how much the table is expanded. For example, scale = 2 will cause the table to be roughly twice as long as the default (scale = 1).
AnalysisUpgradeIncompatibleB <- function(
          data = NULL,
          version = "1",
          addSmooth = TRUE,
          addSmoothCI = TRUE,
          addSmoothCIValue = 0.95,
          binWidthType = "sturges",
          chartType = "_3pieCharts",
          chartValues = "_1frequencies",
          colorPalette = "colorblind",
          descriptivesIntervalPlot = FALSE,
          descriptivesPiechart = FALSE,
          descriptivesQQPlot = FALSE,
          distPlotDensity = FALSE,
          distPlotRug = FALSE,
          frequencyTables = FALSE,
          frequencyTablesMaximumAmount = 10,
          graphTypeAbove = "density",
          graphTypeRight = "density",
          iqr = FALSE,
          kurtosis = FALSE,
          mad = FALSE,
          madrobust = FALSE,
          maximum = TRUE,
          mean = TRUE,
          median = FALSE,
          minimum = TRUE,
          mode = FALSE,
          numberOfBins = 30,
          percentileValuesEqualGroups = FALSE,
          percentileValuesEqualGroupsNo = 4,
          percentileValuesPercentiles = FALSE,
          percentileValuesQuartiles = FALSE,
          plotCorrelationMatrix = FALSE,
          plotHeight = 320,
          plotVariables = FALSE,
          plotWidth = 480,
          range = FALSE,
          regressionType = "smooth",
          scatterPlot = FALSE,
          shapiro = FALSE,
          showLegend = TRUE,
          skewness = FALSE,
          splitPlotBoxplot = TRUE,
          splitPlotColour = FALSE,
          splitPlotJitter = FALSE,
          splitPlotOutlierLabel = FALSE,
          splitPlotViolin = FALSE,
          splitPlots = FALSE,
          splitby = list(types = list(), value = ""),
          standardDeviation = TRUE,
          standardErrorMean = FALSE,
          statisticsValuesAreGroupMidpoints = FALSE,
          stemAndLeaf = FALSE,
          stemAndLeafScale = 1,
          sum = FALSE,
          variables = list(types = list(), value = list()),
          variance = FALSE) {

   defaultArgCalls <- formals(jaspTestModule::AnalysisUpgradeIncompatibleB)
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

   optionsWithFormula <- c("binWidthType", "colorPalette", "splitby", "variables")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "AnalysisUpgradeIncompatibleB", "AnalysisUpgrade.qml", options, version, FALSE))
}