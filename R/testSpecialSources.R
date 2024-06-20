testSpecialSourcesFunc <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  
	
        jaspResults[["msg"]] <- createJaspHtml(text=gettext('<i>Nothing special</i>'))
}
