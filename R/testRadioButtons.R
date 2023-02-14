radioButtonFunc <- function(jaspResults, dataset, options)
{
    jaspResults[['dynamic']] <- createJaspHtml(text=jsonlite::toJSON(options["dynamic"], auto_unbox = TRUE, digits = NA, null="null", force = TRUE))
    jaspResults[['firstGroup']] <- createJaspHtml(text=jsonlite::toJSON(options["firstGroup"], auto_unbox = TRUE, digits = NA, null="null", force = TRUE))
    jaspResults[['secondGroup']] <- createJaspHtml(text=jsonlite::toJSON(options["secondGroup"], auto_unbox = TRUE, digits = NA, null="null", force = TRUE))
}
