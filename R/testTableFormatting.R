testTableFormattingFunc <- function(jaspResults, dataset, options)
{
  	tableOfOptions(jaspResults, options, dataset)
  

	# the correlation table stored here
	mainTable <- createJaspTable(title = "Table with some formatting")
	

	tableData  <- data.frame(
		list(
			someNumber=c(0, 1, 2, 3.3), 
			someMoney=c(10, 11.00, 100000002, 100.12),
			someMoneyDollar=c(1043, 11.00, 100000002, 100.12), 
			someFixedDecimals=c(1.234, 12.34, 123.4, 1234.0 ), 
			someString=c("a", "b", "c", "een of andere tekst")))

	# the displayed columns are supposed to be just the number of variable
	mainTable$addColumnInfo(name = "someNumber", 		title = "Numbers", 				type = "number", format="")
	mainTable$addColumnInfo(name = "someMoneyDollar", 	title = "Money from USA", 		type = "number", format="monetaryUSD")
	mainTable$addColumnInfo(name = "someMoney", 		title = "Money", 				type = "number", format="monetary")
	mainTable$addColumnInfo(name = "someFixedDecimals", title = "Fixed decimals", 		type = "number", format="dp:1")
	mainTable$addColumnInfo(name = "someString", 		title = "Strings", 				type = "string", format="")
	mainTable$setData(tableData)

	#mainTable$print()
	jaspResults[['formatted']] <- mainTable

}
