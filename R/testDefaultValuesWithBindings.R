testDefaultValuesWithBindings <- function(jaspResults, dataset, options)
{
	checked <- paste("Checked: ", options[["check"]])
	radio <- paste("Radio: ", options[["radio"]])
	drop <- paste("Drop: ", options[["drop"]])
	jaspResults[["msg"]] <- createJaspHtml(text=paste("Result: ", checked, radio, drop, sep="<br>"))
}
