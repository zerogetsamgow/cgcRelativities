#' Annual relativities
#'
#' A dataset of annual relativities calculated by the CGC
#'
#' @format ## `who`
#' A data frame with nrow(yearly_relativities) rows and ncol(yearly_relativities) columns:
#' \describe{
#'   \item{update_year}{Year of the CGC update or review the data was source from.}
#'   \item{state_name}{The Australian State or Territory the relativity is for.}
#'   \item{relativity_year}{Financial year the relativity should be applied to.}
#'   \item{assess_value}{The year data used to calculate the relativity comes from.}
#'   ...
#' }
#' @source <https://www.cgc.gov.au/reports-for-government/>
"relativities_annual"
