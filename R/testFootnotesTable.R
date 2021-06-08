testFootnotesTableFunc <- function(jaspResults, dataset, options)
{
  jaspResults[['table0']] <- createFootnotesTable(options=options)
  jaspResults[['table1']] <- createFootnotesTable(options=options, notUnique=TRUE)
  
	createEmptiesTable(jaspResults)
  createCombinations(jaspResults) 
}

createCombinations <- function(jaspResults)
{
  binary           <- data.frame(list(a=c("00", "01"), b=c("10", "11")))
  rownames(binary) <- c('c', 'd')
  tab              <- createJaspTable("Combining row- with col-names or not!")
  
  tab$setData(binary)
  
  tab$addFootnote(message="nothing!")
  tab$addFootnote(message="just row", rowNames='c')
  tab$addFootnote(message="just col", colNames='a')
  tab$addFootnote(message="row&&col", rowNames='d', colNames='b')

  jaspResults[["cartesianFootnotes"]] <- tab
}

createEmptiesTable <- function(jaspResults)
{
 	#for https://github.com/jasp-stats/INTERNAL-jasp/issues/538 (footnotes mess)

  tab  <- createJaspTable(paste0("Table with Footnotes at empty cell"))
  jaspResults[["tableEmptyCell"]] <- tab

  tab$setExpectedSize(rows=3, cols=3)
  tab$setColumnName(1, 'b')
  tab$setRowName(1, 'b')

  tab$setColumnName(2, 'a')
  tab$setColumnName(3, 'c')
  tab$setRowName(3, 'a')

  tab$addFootnote(message="hallo", rowNames='a', colNames='c')

  tab$addRows(list(a=NA, b=NA, c=NA))
  tab$addFootnote(message="NA!", rowNames='b', colNames='b')
}

createFootnotesTable <- function(numFootnotes=3, rowNames=c("b", "c", "c"), colNames=c("a", "a", "b"), options, notUnique=FALSE)
{
  foo <- sapply(letters[21:23], function(col) paste(letters[24:26], col))
  rownames(foo) <- colnames(foo) <- letters[1:3]
  
  tableFootnotes <- createJaspTable(paste0("Table with Footnotes at rowNames=(", paste0(rowNames, collapse=", "), ") and colNames=(", paste0(colNames, collapse=", "), ")", collapse=""), foo, dependencies="checkbox_0")

  msgNum <- 0

  while(msgNum < numFootnotes)
  {
    msgNum <- msgNum + 1

    if(options$checkbox_0 == notUnique)       tableFootnotes$addFootnote(message = paste0("msg", as.character(msgNum)), rowNames = rowNames[[msgNum]], colNames = colNames[[msgNum]])
    else if(options$checkbox_1 != notUnique)  tableFootnotes$addFootnote(message = "Identical Twins!",                  rowNames = rowNames[[msgNum]], colNames = colNames[[msgNum]])
    else                                      tableFootnotes$addFootnote(message = "Identical Symbols!",                rowNames = rowNames[[msgNum]], colNames = colNames[[msgNum]], symbol="?")
  }

  return(tableFootnotes);
}
