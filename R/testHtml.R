testHtmlFunc <- function(jaspResults, dataset, options)
{
	elementType <- 'p'
  
  jaspResults[["html"]] <- createJaspHtml(title = gettextf("Formula for %s", jaspBase::mathExpression(r"{\mathcal{M}_{1}}")))
  jaspResults[["html"]]$text <- gettextf(
    "Under %s, we have %s where %s",
    jaspBase::mathExpression(r"{\mathcal{M}_1}"),
    jaspBase::mathExpression(r"{p(\theta \mid y) = \frac{p(\theta) \times p(y \mid \theta)}{p(y)},}", inline = FALSE),
    jaspBase::mathExpression(r"{p(y) = \int p(\theta) \times p(y \mid \theta) d\theta.}", inline = FALSE)
  )
  jaspResults[["table"]] <- createJaspTable(title = gettextf("Summary for %s", jaspBase::mathExpression(r"{\theta}")))
  jaspResults[["table"]]$addColumnInfo(name = "parameter", title = gettext("Parameter"))
  jaspResults[["table"]]$addColumnInfo(name = "estimate", title = jaspBase::mathExpression(r"{\mathop{\mathbb{E}}(\theta \mid y)}"), type = "number")
  jaspResults[["table"]]$addColumnInfo(name = "variance", title = jaspBase::mathExpression(r"{\mathop{\mathbb{VAR}}(\theta \mid y)}"), type = "number")

  jaspResults[["table"]]$setData(
    list(
      parameter = jaspBase::mathExpression(c("\\alpha", "\\beta", "\\gamma", "\\delta")),
      estimate = rnorm(4),
      variance = rexp(4, 1)
    )
  )
  jaspResults[["table"]]$addFootnote(
    message = gettextf(
      "Posterior expectation for parameter %s is computed as %s",
      jaspBase::mathExpression("\\overrightarrow{AB}"),
      jaspBase::mathExpression(r"{\bar{\theta} = \frac{\sum \theta_i}{n}}")
      ),
    symbol = jaspBase::mathExpression("\\ast"),
    colNames = "estimate"
  )
  }
