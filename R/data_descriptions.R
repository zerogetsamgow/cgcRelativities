#' Annual relativities
#'
#' A dataset of annual relativities for each assessment year calculated by the CGC.
#'
#' @format ## `cgc`
#' A data frame with nrow(relativities_annual) rows and ncol(relativities_annual) columns:
#' \describe{
#'   \item{update_year}{Year of the CGC update or review the data was source from.}
#'   \item{state_name}{The Australian State or Territory the relativity is for.}
#'   \item{financial_year}{Financial year data used to calculate the relativity was drawn from.}
#'   \item{relativity}{The annual per capita relativity for that year as assessed by the CGC.}
#'   \item{relativity_type}{The type of relativity `annual` to diffentiate from averaged recommended relativities.}
#'   ...
#' }
#' @source <https://www.cgc.gov.au/reports-for-government/>
"relativities_annual"

#' Recommended relativities
#'
#' A dataset of relativities recommended by the CGC.
#'
#' @format ## `cgc`
#' A data frame with nrow(relativities_recommended) rows and ncol(relativities_recommended) columns:
#' \describe{
#'   \item{update_year}{Year of the CGC update or review the data was sourced from.}
#'   \item{state_name}{The Australian State or Territory the relativity is for.}
#'   \item{financial_year}{Financial year the relativity was to be used.}
#'   \item{relativity}{The recommended relativity for that year as assessed by the CGC.}
#'   \item{relativity_type}{The type of relativity `recommended` to diffentiate from annual relativities.}
#'   ...
#' }
#' @source <https://www.cgc.gov.au/reports-for-government/>
"relativities_recommended"

#' Adjusted relativities
#'
#' A dataset of relativities calculated on the basis a floor was never introduced.
#'
#' @format ## `cgc`
#' A data frame with nrow(relativities_floorless) rows and ncol(relativities_floorless) columns:
#' \describe{
#'   \item{update_year}{Year of the CGC update or review the data was sourced from.}
#'   \item{state_name}{The Australian State or Territory the relativity is for.}
#'   \item{financial_year}{Financial year the relativity was to be used.}
#'   \item{relativity}{The recommended relativity for that year as assessed by the CGC.}
#'   \item{relativity_type}{The type of relativity `floorless` to diffentiate from recommended relativities.}
#'   ...
#' }
#' @source <https://www.cgc.gov.au/reports-for-government/>
"relativities_floorless"


#' Adjusted revenue
#'
#' A dataset of the CGC's estimates of state own source revenue.
#'
#' @format ## `cgc`
#' A data frame with nrow(revenue_adjusted) rows and ncol(revenue_adjusted) columns:
#' \describe{
#'   \item{update_year}{Year of the CGC update or review the data was sourced from.}
#'   \item{state_name}{The Australian State or Territory the relativity is for.}
#'   \item{revenue_name}{The Australian State or Territory the relativity is for.}
#'   \item{financial_year}{Financial year the relativity was to be used.}
#'   \item{revenue}{The recommended relativity for that year as assessed by the CGC.}
#'   \item{revenue_type}{The type of estimate `fadjusted` to diffentiate from assessed and actual revenue.}
#'   ...
#' }
#' @source <https://www.cgc.gov.au/reports-for-government/>
"revenue_adjusted"

#' Assessed revenue
#'
#' A dataset of the CGC's assessemtent of state own source revenue.
#'
#' @format ## `cgc`
#' A data frame with nrow(revenue_assessed) rows and ncol(revenue_assessed) columns:
#' \describe{
#'   \item{update_year}{Year of the CGC update or review the data was sourced from.}
#'   \item{state_name}{The Australian State or Territory the relativity is for.}
#'   \item{revenue_name}{The Australian State or Territory the relativity is for.}
#'   \item{financial_year}{Financial year the relativity was to be used.}
#'   \item{revenue}{The recommended relativity for that year as assessed by the CGC.}
#'   \item{revenue_type}{The type of estimate `assessed` to diffentiate from adjusted and actual revenue.}
#'   ...
#' }
#' @source <https://www.cgc.gov.au/reports-for-government/>
"revenue_assessed"



#' GFS Revenue
#'
#' A dataset of the ABS's estimates of of state own source revenue.
#'
#' @format ## `abs`
#' A data frame with nrow(revenue_assessed) rows and ncol(revenue_assessed) columns:
#' \describe{
#'   \item{gfs_category}{The type of measure `revenue` to diffentiate from expenses.}
#'   \item{gfs_subcategory}{The GFS `revenue` category.}
#'   \item{state_name}{The Australian State or Territory the estimate is for.}
#'   \item{financial_year}{Financial year the estimate is for.}
#'   \item{value}{The estimated value.}
#'   ...
#' }
#' @source <https://www.abs.gov.au/statistics/economy/government/government-finance-statistics-annual/>
"revenue_gfs"




#' GFS Taxation
#'
#' A dataset of the ABS's estimates of of state taxation.
#'
#' @format ## `abs`
#' A data frame with nrow(revenue_assessed) rows and ncol(revenue_assessed) columns:
#' \describe{
#'   \item{gfs_category}{The type of measure `expenses` to diffentiate from expenses.}
#'   \item{gfs_subcategory}{The GFS `expense` category.}
#'   \item{state_name}{The Australian State or Territory the estimate is for.}
#'   \item{financial_year}{Financial year the estimate is for.}
#'   \item{value}{The estimated value.}
#'   ...
#' }
#' @source <https://www.abs.gov.au/statistics/economy/government/taxation-revenue-australia>
"taxation_gfs"
