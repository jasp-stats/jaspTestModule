radioButtonFunc <- function(jaspResults, dataset, options)
{
	elementType <- 'p'

	jaspResults[['boodschap']] 		 <- createJaspHtml(text=paste0(options), info="some info on a jaspHtml")
	jaspResults[['tafel']]     		 <- createJaspTable(title="Glory", colTitles=c('hallo', 'wereld'), info="some info on a table")
	jaspResults[['nested']]    		 <- createJaspContainer("Chairs", info='this is a container you know')
	jaspResults[['nested']][['egg']] <- createJaspHtml(text="This is nested within a container", info="some info on a nested jaspHtml")
}
