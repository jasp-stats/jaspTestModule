testSpecialSourcesFunc <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options)
  
	
        jaspResults[["msg"]] <- createJaspHtml(text=gettext('<i>Nothing special</i>'))
}
