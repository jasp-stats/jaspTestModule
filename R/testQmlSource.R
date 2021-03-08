testQmlSourceFunc <- function(jaspResults, dataset, options)
{
	
	jaspResults[["msg"]] <- createJaspHtml(text='<i>Er wordt iets naar qml source geschreven!</i>')

	jaspResults[["qmlSource"]] <- createJaspQmlSource(sourceID="exampleSourceId", value=list(1, 2, 3, c(1,2,3,4), "hahaha", c("A" ,"B", "C", "?")))
}