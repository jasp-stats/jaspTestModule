#' @export
JaspReportTest <- function(jaspResults, dataset, options)
{
	if(options[["selectedVariable"]] == "" || options[["reportMe"]] == "") {
    jaspResults[["msg"]] <- createJaspHtml("Select a variable and enter a formula please", dependencies=c("reportMe", "selectedVariable"))
  } else {

    dataset      <- .readDataSetToEnd(columns=options[["selectedVariable"]])
    column       <- dataset[[options[["selectedVariable"]]]]
    reportResult <- eval(parse(text=options[["reportMe"]]))
    reportOnThis <- any(reportResult)
    
    jaspResults[["reportingForDuty"]] <- createJaspReport(
      paste("this is a generic text that tells you I have ", ifElse(reportOnThis, "SOMETHING", "nothing"), " to report."), 
      reportOnThis, dependencies=c("reportMe", "selectedVariable"))
  }
    
}