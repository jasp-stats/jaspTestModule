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

#' Radio Button
#'
radioButtonFunc <- function(
          data = NULL,
          version = "1",
          assigned = list(types = list(), value = list()),
          buttons1 = list(list(value = "button1"), list(value = "button2")),
          buttons2 = list(list(value = "button1"), list(value = "button2")),
          dynamic = list(),
          dynamicGroupWithDynamicButtons = list(list(value = "grouo1"), list(value = "group2")),
          dynamicGroupWithStaticButtons = list(list(value = "grouo1"), list(value = "group2")),
          firstGroup = "one",
          plotHeight = 320,
          plotWidth = 480,
          secondGroup = "one",
          staticGroupWithDynamicButtons = "",
          staticGroupWithStaticAndDynamicButtons = "Static button") {

   defaultArgCalls <- formals(jaspTestModule::radioButtonFunc)
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

   optionsWithFormula <- c("assigned", "buttons1", "buttons2", "dynamic", "dynamicGroupWithDynamicButtons", "dynamicGroupWithStaticButtons")
   for (name in optionsWithFormula) {
      if ((name %in% optionsWithFormula) && inherits(options[[name]], "formula")) options[[name]] = jaspBase::jaspFormula(options[[name]], data)   }

   return(jaspBase::runWrappedAnalysis("jaspTestModule", "radioButtonFunc", "RadioButtonTest.qml", options, version, FALSE))
}