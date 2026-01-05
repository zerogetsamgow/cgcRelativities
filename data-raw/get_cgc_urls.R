library(cgcRelativities)
# Define paths, both local and online
cgc.path = "./data-raw"
cgc.url = "https://www.cgc.gov.au/reports-for-government/"

# Create table of URLs to search for files
cgc.data =
  tibble::tibble(
    "update_year" = 2015:2025
  ) |>
  dplyr::mutate(
    # CGC urls vary across update_years and reviews, so create correct urls below
    cgc.update.url =
      dplyr::if_else(update_year %in% 2025,
                     stringr::str_c(cgc.url,update_year,"-methodology-review/gst-relativities-2025-26"),stringr::str_c(cgc.url,update_year,"-update")),
    cgc.update.url =
      dplyr::if_else(update_year %in% 2024:2025,
                     stringr::str_c(cgc.update.url,"/tables-charts-and-supporting-data"),
                             cgc.update.url),
    cgc.update.url =
      dplyr::if_else(
        update_year %in% 2022:2023,
        stringr::str_c(cgc.update.url,"/supporting-data"),
        cgc.update.url),
    cgc.update.url =
      dplyr::if_else(
        update_year %in% c(2015,2020),
        stringr::str_replace(cgc.update.url,"update","review"),
        cgc.update.url)
  )  |>
  # Find files reference at each url
  dplyr::mutate(file.url=purrr::pmap(list(cgc.update.url),get_cgc_files)) |>
  tidyr::unnest(file.url) |>
  # Clean names for easier handling
  dplyr::mutate(
    file_name = basename(file.url) |>
      stringr::str_remove_all("^[ruU][0-9]{4}") |>
      stringr::str_replace_all("(\\%2[0-9])+"," ") |>
      stringr::str_replace_all("_"," ") |>
      stringr::str_remove("(\\s)*\\-(\\s)*(2015\\s)*(Review|Report)") |>
      stringr::str_replace_all("(\\s)[0-9]*\\.xlsx",".xlsx ") |>
      stringr::str_replace_all("\\s","_") |>
      stringr::str_to_title() |>
      trimws(),
    file_name =
      stringr::str_c(update_year,file_name),
      # Create download target
      download=file.path(cgc.path,file_name))  |>
  # Download files, if not already stored locally
  dplyr::mutate(x =
           purrr::pmap(
             list(file.url, download),
             download_cgc
           )
  )  |>
  dplyr::select(-x) |>
  # Get sheet names.
  dplyr::mutate(sheets = purrr::map(download,readxl::excel_sheets)) |>
  tidyr::unnest(sheets)

# CGC orders by current population. ABS and strayr use different order
cgc_names = strayr::state_name_au[c(1:3,5,4,6,8,7)]
cgc.abb = strayr::state_abb_au[c(1:3,5,4,6,8,7)]


