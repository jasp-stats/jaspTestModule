

testCrapDataTable <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  
		
	tb <- createJaspTable()
	df <- structure(
	list(
		runOrder = 1:8,
		`abc (A)` = structure(
			c(NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_),
			contrasts = structure(c(-1, 1), .Dim = 2:1, .Dimnames = list(c("-1", "1"), NULL)),
			.Label = c("-1", "1"),
			class = "factor"
		),
		`cbd (B)` = structure(
			c(NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_),
			contrasts = structure(c(-1, 1), .Dim = 2:1, .Dimnames = list(c("-1", "1"), NULL)),
			.Label = c("-1", "1"),
			class = "factor"
		),
		`3 (C)` = structure(
			c(NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_),
			contrasts = structure(c(-1, 1), .Dim = 2:1, .Dimnames = list(c("-1", "1"), NULL)),
			.Label = c("-1", "1"),
			class = "factor"
		)
	),
	row.names = c(3L, 1L, 2L, 5L, 8L, 4L, 6L, 7L),
	class = "data.frame"
	)

	tb$setData(df)

	jaspResults[["hereYaGo"]] <- tb

}