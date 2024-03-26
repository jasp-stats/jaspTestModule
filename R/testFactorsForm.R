
testFactorsFormFunc <- function(jaspResults, dataset, options)
{

  tableOfOptions(jaspResults, options)

  jaspResults[["Hallo"]] <- createJaspHtml(text="hallo!")
}
