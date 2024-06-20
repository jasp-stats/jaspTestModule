testRSourceFunc <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  
	
	jaspResults[["msg"]] <- createJaspHtml(text=gettext('<i>Something is written to a R source</i>'))

	myData <- list()
        top2 = list()
        top2[["subTopA"]] <- list("A", "B")
        top2[["subTopB"]] <- list("C", "D", "E")

        myData[["top1"]] <- list("elt1", "elt2")
        myData[["top2"]] <- top2


        jaspResults[["exampleSourceId"]] <- createJaspQmlSource(sourceID="exampleSourceId", value=myData)
}
