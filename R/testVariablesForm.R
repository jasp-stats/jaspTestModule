
testVariablesForm <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  

	jaspResults[["Hallo"]] <- createJaspHtml(text="hallo!")
}