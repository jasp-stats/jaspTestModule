testHtmlFunc <- function(jaspResults, dataset, options)
{
	elementType <- 'p'

	if(options$checkbox_error) 
		elementType <- 'errorMsg'

	jaspResults[["errorMsg"]] <- createJaspHtml(text=gettext('<p> Hello world! this is a formula \n\\[e=mc^2\\] \\[\\tilde{a}\\] \\[\\Overrightarrow{AB}\\] \\[\\begin{vmatrix}a & b \\\\ c & d \\end{vmatrix}\\]</p>'), elementType=elementType)

	jaspResults[['boodschap']] <- createJaspHtml(text=paste0('state contains: ', jaspResults[['state']]$object))
}
