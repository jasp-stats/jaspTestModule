testMixedColumnsTableFunc <- function(jaspResults, dataset, options) {

  if (options[["checkbox_0"]])
    set.seed(123)

  jaspResults[["info"]] <- createJaspHtml(paste0("Seed is ", if (options[["checkbox_0"]]) "" else "not", " set"))

  df <- makeRandomMixedTable()

  # Test 1, assign columns directly ----
  tb <- createJaspTable("Directly assign columns")

  for (i in seq_len(ncol(df))) {
    colname <- paste0("col", i)
    tb$addColumnInfo(name = colname, title = "b_JASP", type = "mixed")
    tb[[colname]] <- df[[i]]
  }

  jaspResults[["directlyAssignedColumns"]] <- tb

  # Test 2, addColumns pass data.frame ----
  tb <- createJaspTable("addColumns with list argument")

  tb$addColumns(cols = df)
  jaspResults[["addColumnsWithList"]] <- tb

  # Test 3, addColumns pass one by one ----
   tb <- createJaspTable("addColumns one by one")

   for (i in seq_len(ncol(df)))
     tb$addColumns(cols = df[i])

   jaspResults[["addColumnsOneByOne"]] <- tb

  # Test 4, setData ----
  tb <- createJaspTable(title = "use setData(df)")

  tb$setData(df)
  print(tb) # should also look okay in the terminal
  jaspResults[["setData(df)"]] <- tb

  # Test 5, addRows ----
  tb <- createJaspTable(title = "use addRows(df)")

  rowList <- lapply(seq_len(nrow(df)), function(i) {
    lst <- lapply(seq_len(ncol(df)), function(j) {
      jaspBase::createMixedRow(
        value = df[[i, j]]$value,
        type  = df[[i, j]]$type
      )
    })
    names(lst) <- names(df)
    lst
  })

  for (i in seq_along(rowList))
    tb$addRows(rowList[[i]])

  jaspResults[["addRows"]] <- tb

}

simpleMixedTable <- function() {
  data.frame(
    col  = jaspBase::createMixedColumn(
      values = list(1.23, 0.04, "hoi", 123),
      types =  c("number", "pvalue", "string", "integer")
    ),
    col2 = 1:4
  )
}

makeRandomMixedTable <- function(nrow = 8, ncol = 3, maxChar = 10) {

  types  <- sample(c("number", "pvalue", "string", "integer"), nrow * ncol, TRUE)
  values <- lapply(types, function(t) {
    switch(t,
      "number"  = rnorm(1),
      # make it probable to test the effect of the exact p-values setting
      "pvalue"  = if (runif(1) <= .7) runif(1, 1e-20, 1e-5) else runif(1),
      "string"  = paste(sample(letters, maxChar, TRUE), collapse = ""),
      "integer" = if (runif(1) <= .5) sample.int(100000, 1) else sample.int(10, 1)
    )
  })

  df <- do.call(cbind.data.frame, lapply(1:ncol, \(i) {
    index <- (1:nrow) + (i - 1) * nrow
    jaspBase::createMixedColumn(
      values = values[index],
      types  =  types[index]
    )
  }))
  colnames(df) <- paste0("col", seq_len(ncol(df)))
  df
}
