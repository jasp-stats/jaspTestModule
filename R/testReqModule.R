descriptivesLink <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  
	Descriptives::Descriptives(jaspResults, dataset, options)
}