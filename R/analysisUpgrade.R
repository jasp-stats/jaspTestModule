Analysis <- function(jaspResults, dataset, options) {
  tableOfOptions(jaspResults, options, dataset)
  
	jaspResults[["optionsOverview"]] <- createJaspHtml(text=paste0(paste0("<li>", names(options), ": "), options, "</li>", collapse="\n"), elementType="ul")
}

AnalysisUpgradeA <- Analysis;
AnalysisUpgradeB <- Analysis;
