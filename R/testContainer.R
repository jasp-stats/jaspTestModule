testContainerFuncInternal <- function(jaspResults, dataset, options)
{
  tableOfOptions(jaspResults, options, dataset)
  
  cnt <- addContainer(addContainer(addContainer(addContainer(jaspResults, name="c0"))))
  testFootnotesTableFuncInternal(cnt, dataset, options)

  cnt <- addContainer(addContainer(addContainer(addContainer(jaspResults, name="c1")), title="hallo"))
  testFootnotesTableFuncInternal(cnt, dataset, options)

  cnt <- addContainer(addContainer(addContainer(addContainer(jaspResults, title="hallo", name="c2")), title="er zit er eentje stiekem om me heen"), title="hallo", initCollapsed=TRUE)
  testFootnotesTableFuncInternal(cnt, dataset, options)
}

addContainer <- function(inContainer, name="container", title="", initCollapsed=FALSE)
{
  inContainer[[name]] = createJaspContainer(title=title, initCollapsed=initCollapsed)

  return(inContainer[[name]])
}
