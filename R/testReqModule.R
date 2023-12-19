descriptivesLink <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options)
  
	Descriptives::Descriptives(jaspResults, dataset, options)
}