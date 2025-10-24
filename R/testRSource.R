testRSourceFunc <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  
	

	myData <- list()
        top2 = list()
        top2[["subTopA"]] <- list("A", "B")
        top2[["subTopB"]] <- list("C", "D", "E")

        myData[["top1"]] <- list("elt1", "elt2")
        myData[["top2"]] <- top2


      exampleSourceId <- createJaspQmlSource(sourceID="myRSourceId", value=myData)
      myRSourceId2 <- createJaspQmlSource(value=myData)
      jaspResults[["exampleSourceId"]] <- exampleSourceId
      jaspResults[["myRSourceId2"]] <- myRSourceId2 # No sourceID is given so myRSourceId2 will be used

      jaspResults[["rsource1"]] <- createJaspHtml(text=paste0('R source exampleSourceId: ', gsub("[\r\n]", " ", exampleSourceId$value)))
      jaspResults[["rsource2"]] <- createJaspHtml(text=paste0('R source myRSourceId2: ', gsub("[\r\n]", " ", myRSourceId2$value)))


}
