## --------------------------------------
## Rsq FUNCTION FOR GAMLSSINF0TO1 MODELS
## --------------------------------------

#' Cox-Snell / Cragg-Uhler R-squared for GAMLSS `gamlssinf0to1` models
#'
#' Local patch of `gamlss:::Rsq()` that maps the `"InfBE"` family (used
#' by zero-and-one-inflated beta models fit through `gamlss.inf`) to
#' the `BEINF()` family so that the null model can be fit and pseudo
#' R-squared computed. Without this shim the upstream function fails
#' because it can't resolve the family name.
#'
#' For arguments (`object`, `type`) see `?gamlss::Rsq`.
#'
#' @inheritParams gamlss::Rsq
#'
#' @return Same as `gamlss::Rsq()`.
#' @note Keep this shim sourced whenever the active GAMLSS Rmd is run.
#' @seealso `gamlss::Rsq`

Rsq_2 <- function (object, type = c("Cox Snell", "Cragg Uhler", "both")) {
  type <- match.arg(type)
  if (!is.gamlss(object))
    stop("this is design for gamlss objects only")
  Y <- if (object$family[1] %in% .gamlss.bi.list)
    cbind(object$y, object$bd - object$y) else object$y

  fam <- if (object$family == "InfBE")
    BEINF() else
    object$family

  suppressWarnings(m0 <- gamlssML(Y ~ 1, family = fam))
  rsq1 <- 1 - exp((2/object$N) * (logLik(m0)[1] - logLik(object)[1]))
  rsq2 <- rsq1/(1 - exp((2/object$N) * logLik(m0)[1]))
  if (type == "Cox Snell")
    return(rsq1)
  if (type == "Cragg Uhler")
    return(rsq2)
  if (type == "both")
    return(list(CoxSnell = rsq1, CraggUhler = rsq2))
}
