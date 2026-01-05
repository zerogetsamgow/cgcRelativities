
# Get actual tax revenue from ABS
taxation_gfs =
  tibble::tibble(
    abs_url =
      stringr::str_c("https://www.abs.gov.au/statistics/economy/government/",
            "taxation-revenue-australia/2023-24/55060DO001_202324.xlsx")
  ) |>
  dplyr::mutate(
    file_name = basename(abs_url),
    download = file.path(cgc.path,file_name)
  ) |>
  dplyr::mutate(
    x =
      purrr::pmap(list(abs_url, download),download_cgc)) |>
  dplyr::select(-x) |>
  # Get sheet names.
  dplyr::mutate(sheets = purrr::map(download, readxl::excel_sheets)) |>
  tidyr::unnest(sheets) |>
  dplyr::filter(stringr::str_detect(sheets,"Table_[2-9]")) |>
  dplyr::mutate(
    data =
      purrr::pmap(list(download,sheets), readxl::read_excel, range="A5:k50", col_names = TRUE, col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::rename("revenue_name" = x1) |>
  dplyr::filter(
    !is.na(revenue_name),
    !stringr::str_detect(revenue_name, "(T|t)otal")) |>
  dplyr::mutate(
    state_index = stringr::str_extract(sheets,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = strayr::state_name_au[state_index]
  ) |>
  tidyr::pivot_longer(
    starts_with("x"),
    names_to = "financial_year",
    values_to = "revenue"
  ) |>
  dplyr::mutate(
    revenue = as.numeric(revenue),
    financial_year =
      stringr::str_extract(financial_year,"[0-9]{4}\\_[0-9]{2}") |>
      stringr::str_replace("_","-"),
    financial_year = fy::fy2date(financial_year)
  ) |>
  dplyr::filter(
    financial_year > lubridate::ymd("2000-6-30"),
    !is.na(revenue),
    revenue != 0 ,
    !stringr::str_detect(revenue_name,"Municipal")
  ) |>
  dplyr::mutate(
    revenue_type = "Actual",
    revenue_name = stringr::str_replace(revenue_name, ".*payroll.*","Payroll tax"),
    revenue_name = stringr::str_replace(revenue_name, ".*(I|i)nsurance.*","Insurance tax"),
    revenue_name = stringr::str_replace(revenue_name,"taxes","tax"),
    revenue_name = stringr::str_replace(revenue_name,".*vehicle.*","Motor tax"),
    revenue_name = stringr::str_replace(revenue_name,"Stamp.*","Stamp duty"),
    revenue_name = stringr::str_replace(revenue_name, ".*(gambling|betting|lotteries|Casino).*","Gambling tax"),
    revenue_name = stringr::str_replace(revenue_name,"(Other|Excises|Franchise|Government).*","Other tax"),
  ) |>
  dplyr::group_by(
    download, state_name, financial_year, revenue_name, revenue_type
  ) |>
  dplyr::summarise(revenue = sum(revenue),.groups = 'drop')

#Clean up
files = unique(taxation_gfs$download)
file.remove(files)

taxation_gfs =
  taxation_gfs |>
  dplyr::select(-download)

# Save for export
usethis::use_data(taxation_gfs, overwrite = TRUE)
remove(taxation_gfs)


# Get GFS data
abs_gfs =
  stringr::str_c("https://www.abs.gov.au/statistics/economy/government/",
        "government-finance-statistics-annual/latest-release") |>
  rvest::read_html() |>
  rvest::html_elements('div [href$=xlsx]') |>
  rvest::html_attr("href") |>
  tibble::as_tibble_col("url") |>
  dplyr:::mutate(
    url = stringr::str_c("https://www.abs.gov.au", url)
  ) |>
  dplyr::filter(stringr::str_detect(url,"DO00[3-9]|DO010")) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    download = tempfile(fileext = ".xlsx")) |>
  dplyr::ungroup()  |>
  dplyr::mutate(
    x =
      purrr::pmap(
        list(url,download),
        function(a,b) if(!file.exists(b)) download.file(a,b,mode="wb")))  |>
  dplyr::select(-x) |>
  dplyr::mutate(sheets = purrr::map(download,readxl::excel_sheets)) |>
  tidyr::unnest(sheets) |>
  dplyr::filter(sheets=="Table_1") |>
  dplyr::mutate(
    data =
      purrr::pmap(list(download, sheets), readxl::read_excel, range="A5:k50", col_names = TRUE, col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::mutate(
    gfs_category =
      stringr::str_extract(x1,"GFS.*"), .before = "x1") |>
  tidyr::fill(gfs_category) |>
  dplyr::filter(
    !is.na(x1),
    !stringr::str_detect(x1,"Total")) |>
  dplyr::rename("gfs_subcategory"=x1) |>
  tidyr::pivot_longer(
    tidyselect::starts_with("x"), names_to = "financial_year") |>
  dplyr::filter(!is.na(value)) |>
  dplyr::mutate(
    value = as.numeric(value),
    financial_year =
      stringr::str_remove(financial_year,"x") |>
      stringr::str_replace("_","-") |>
      fy::fy2date() |>
      lubridate::ceiling_date("months") - lubridate::days(1),
    state_index =
      stringr::str_extract(url, "DO0[0-1][0-9]") |>
      stringr::str_remove("DO0") |> as.numeric() - 2,
    financial_year =
      fy::date2fy(financial_year) |> fy::fy2date(),
    state_name =
      strayr::state_name_au[state_index]) |>
  dplyr::select(
    download,
    gfs_category,
    gfs_subcategory,
    state_name,
    financial_year,
    value
  )

revenue_gfs =
  abs_gfs |>
  dplyr::filter(
    stringr::str_detect(gfs_category, "Revenue")
  )

expenses_gfs =
  abs_gfs |>
  dplyr::filter(
    stringr::str_detect(gfs_category, "Expenses")
  )

usethis::use_data(revenue_gfs, overwrite = TRUE)
usethis::use_data(expenses_gfs, overwrite = TRUE)

# Clean up
files = unique(abs_gfs$download)
file.remove(files)
remove(revenue_gfs, expenses_gfs, abs_gfs)

# Get and tidy estimated residential population data from ABS
population_erp =
  readabs::read_abs(
    "3101.0",
    check_local = "FALSE"
  )  |>
  readabs::separate_series() |>
  dplyr::filter(
    series_3 %in% strayr::state_name_au,
    stringr::str_detect(
      series_2,
      "Persons")
  ) |>
  dplyr::mutate(
    financial_year =
      lubridate::ceiling_date(
        date,
        unit = "month") - lubridate::days(1))  |>
  dplyr::group_by(
    "state_name"=series_3,
    financial_year,
    unit
  ) |>
  dplyr::summarise(
    population = dplyr::last(value), .groups = "drop"
  )

usethis::use_data(population_erp, overwrite = TRUE)
remove(population_erp)

estimated_gsp =
  "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-state-accounts/latest-release" |>
  rvest::read_html() |>
  rvest::html_elements('div [href$=xlsx]') |>
  rvest::html_attr("href") |>
  tibble::as_tibble_col("url") |>
  dplyr::mutate(
    url = stringr::str_c("https://www.abs.gov.au", url)
  ) |>
  dplyr::filter(
    stringr::str_detect(url,"All")) |>
  dplyr::mutate(
    download = tempfile(fileext = ".xlsx")) |>
  dplyr::mutate(
    x =
      purrr::pmap(
        list(url,download),
        function(a,b) if(!file.exists(b)) download.file(a,b,mode="wb")))  |>
  dplyr::select(-x) |>
  dplyr::mutate(sheets = purrr::map(download,readxl::excel_sheets)) |>
  tidyr::unnest(sheets) |>
  dplyr::filter(stringr::str_detect(sheets,"Data")) |>
  # Extract data
  dplyr::mutate(
    data = purrr::pmap(list(download,sheets), readxl::read_excel))  |>
  dplyr::select(download, data) |>
  tidyr::unnest(data) |>
  dplyr::rename(
    "date" = 2
  ) |>
  dplyr::mutate(
    date = janitor::excel_numeric_to_date(as.numeric(date))
  ) |>
  dplyr::filter(
    !is.na(date)
  ) |>
  tidyr::pivot_longer(
    -tidyselect::starts_with("d"),
    names_to = "series"
  ) |>
  dplyr::mutate(value = as.numeric(value)) |>
  dplyr::filter(
    !is.na(value)
  ) |>
  readabs::separate_series() |>
  dplyr::filter(
    stringr::str_detect(series_2,"Gross state product: Current prices$"),
    !stringr::str_detect(series_1,"Total")
  ) |>
  dplyr::select(
    download,
    date,
    "state_name" = series_1,
    "measure" = series_2,
    "gsp" = value
  ) |>
  dplyr::mutate(financial_year = fy::date2fy(date) |> fy::fy2date()) |>
  dplyr::group_by(
    download,
    financial_year,
    state_name,
    measure
  ) |>
  dplyr::summarise(gsp = sum(gsp)) |>
  dplyr::ungroup()

files = unique(estimated_gsp$download)
file.remove(files)

estimated_gsp =
  estimated_gsp |>
  dplyr::select(-download)

usethis::use_data(estimated_gsp, overwrite = TRUE)
remove(estimated_gsp)

