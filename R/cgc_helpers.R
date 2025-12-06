
#' Get CGC files related to a particular update
#'
#' @param url a (character) string containing a url corresponding to the data page
#' for a CGC update or review.
#'
#' @rdname get_cgc_files

#' @importFrom rvest read_html
#' @importFrom rvest html_elements
#' @importFrom rvest html_attr
#' @importFrom curl curl
#' @importFrom tibble as_tibble_col

#' @export
get_cgc_files = function(url) {
  temp.tbl =
    url |>
    curl::curl(handle = curl::new_handle("useragent" = "zerogetsamgow")) |>
    rvest::read_html() |>
    rvest::html_elements(".file--x-office-spreadsheet") |>
    rvest::html_attr("href") |>
    tibble::as_tibble_col("file.url")
}


#' Download CGC files related to a particular update
#'
#' @param url a (character) string containing a url corresponding to the data page
#' for a CGC update or review.
#' @param download a (character) string corresponding to destination file in ./data-raw
#'
#' @rdname download_cgc

#' @importFrom rvest read_html
#' @importFrom rvest html_elements
#' @importFrom rvest html_attr
#' @importFrom curl curl
#' @importFrom tibble as_tibble_col
#' @importFrom utils download.file

#' @export
download_cgc = function(url,destination) {
  if(!file.exists(destination)) utils::download.file(
    url,
    destination,
    method = "curl",
    mode = "wb")
}
