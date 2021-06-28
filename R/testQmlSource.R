testQmlSourceFunc <- function(jaspResults, dataset, options)
{
	
	jaspResults[["msg"]] <- createJaspHtml(text=gettext('<i>Something is written to a R source</i>'))

	myData <- list()
	one <- list(gettext("this"), gettext("that"))
	two <- list("c", "d")
	subList <- list()
	subList[["sub"]] <- list("x", "z")
	subList[["sub2"]] <- list("f", "g", "h")

	myData[["one"]] <- one
	myData[["two"]] <- two
	myData[["three"]] <- c(1L,2L,3L)
	myData[["four"]] <- subList


	jaspResults[["qmlSource"]] <- createJaspQmlSource(sourceID="exampleSourceId", value=myData)
}
