# Get cgc fill urls
source("./data-raw/get_cgc_urls.R")

# Get assessed revenue, most years are same format
assessed_revenue_base =
  cgc.data |>
  dplyr::filter(
    update_year %in% c(2020,2022:2025),
    stringr::str_detect(sheets,"Assessed.*rev")
  ) |>
  dplyr::mutate(
    data =
      purrr::pmap(
        list(download,sheets),
        readxl::read_excel,
        range="A2:j75",
        col_names = TRUE,
        col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  tidyr::pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  dplyr::mutate(
    revenue = as.numeric(revenue),
    state_name =
      factor(
        stringr::str_to_upper(state_name),
        levels = cgc.abb,
        labels = cgc_names),
    revenue_type = "Assessed") |>
  dplyr::filter(!is.na(revenue))

# @021 data starts in a different row
assessed_revenue_2021 =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "Assessed_budget"),
    update_year %in% c(2021),
    stringr::str_detect(sheets,"Assessed.*rev")
  ) |>
  dplyr::mutate(
    data =
      purrr::pmap(
        list(download,sheets),
        readxl::read_excel,
        range="A3:j75",
        col_names = TRUE, col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  tidyr::pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  dplyr::mutate(
    revenue = as.numeric(revenue),
    state_name =
      factor(
        stringr::str_to_upper(state_name),
        levels = cgc.abb,
        labels = cgc_names),
    revenue_type = "Assessed"
    ) |>
  dplyr::filter(!is.na(revenue))

# Get remainding data
assessed_revenue_pre_2020 =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "(A|a)ssessed"),
    update_year %in% c(2015:2019),
    stringr::str_detect(sheets,"Assessed.*rev"),
    !stringr::str_detect(download,"summary")
  ) |>
  dplyr::mutate(
    data = purrr::pmap(
      list(download,sheets),
      readxl::read_excel,
      range="A2:j75",
      col_names = TRUE,
      col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::mutate(
    revenue_name =
      stringr::str_extract(
        x1,
        "[A-z]*\\s((t|T)ax|duty|revenue)")) |>
  tidyr::fill(revenue_name) |>
  dplyr::filter(x1!=revenue_name,!is.na(nsw)) |>
  dplyr::select(
    update_year,
    revenue_name,
    "financial_year" = "x1",
    nsw:nt
  ) |>
  tidyr::pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue") |>
  dplyr::mutate(
    revenue = as.numeric(revenue)/1e6,
    state_name =
      factor(
        stringr::str_to_upper(state_name), levels = cgc.abb, labels = cgc_names),
    revenue_type = "Assessed"
  ) |>
  dplyr::select(names(assessed_revenue_base)) |>
  dplyr::filter(!is.na(revenue))

# Combine datasets for export
revenue_assessed =
  dplyr::bind_rows(
    assessed_revenue_pre_2020,
    assessed_revenue_2021,
    assessed_revenue_base
  ) |>
  dplyr::mutate(
    revenue_name =
      stringr::str_replace(revenue_name,"^assessed","Total assessed"),
   revenue_name =
     stringr::str_replace(revenue_name,"Stamp duty.*","Stamp duty"),
   revenue_name =
     stringr::str_replace(revenue_name,"Motor tax(es)","Motor tax"),
   financial_year =
     fy::fy2date(financial_year)) |>
  dplyr::select(update_year, state_name, revenue_name, financial_year, revenue, revenue_type) |>
  unique()

rm(assessed_revenue_2021,assessed_revenue_base,assessed_revenue_pre_2020)
# Save for export
usethis::use_data(revenue_assessed, overwrite = TRUE)

# Get adjusted revenue
# Most years are consistent format, get those first
adjusted_revenue_base =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "Adjusted_budget"),
    update_year %in% c(2020,2022:2025),
    stringr::str_detect(sheets,"Own.*revenue")
  ) |>
  dplyr::mutate(
    data =
      purrr::pmap(
        list(download,sheets),
        readxl::read_excel,
        range="A3:j75",
        col_names = TRUE,
        col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  tidyr::fill(revenue_name) |>
  tidyr::pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  dplyr::mutate(
    revenue = as.numeric(revenue),
    state_name =
      factor(
        stringr::str_to_upper(state_name),
        levels = cgc.abb,
        labels = cgc_names),
    revenue_type = "Adjusted") |>
  dplyr::filter(!is.na(revenue))

# @021 data starts in a different row
adjusted_revenue_2021 =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "Adjusted_budget"),
    update_year %in% c(2021),
    stringr::str_detect(sheets,"rev")
  ) |>
  dplyr::mutate(
    data =
      purrr::pmap(
        list(download,sheets),
        readxl::read_excel,
        range="A3:j75",
        col_names = TRUE,
        col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  tidyr::fill(revenue_name) |>
  tidyr::pivot_longer(
    nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  dplyr::mutate(
    revenue = as.numeric(revenue),
    state_name =
      factor(
        stringr::str_to_upper(state_name),
        levels = cgc.abb,
        labels = cgc_names),
    revenue_type = "Adjusted"
  ) |>
  dplyr::filter(!is.na(revenue))


adjusted_revenue_pre_2020 =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "adjusted_budget"),
    update_year %in% c(2015:2019),
    stringr::str_detect(sheets,"Own.*rev"),
    !stringr::str_detect(download,"Summary")
  ) |>
  dplyr::mutate(
    data = purrr::pmap(
      list(download,sheets),
      readxl::read_excel,
      range="A2:j75",
      col_names = TRUE,
      col_types = "text"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::mutate(
    revenue_name =
      stringr::str_extract(
        x1,
        "[A-z]*\\s((t|T)ax|duty|revenue)")) |>
  tidyr::fill(revenue_name) |>
  dplyr::filter(x1!=revenue_name,!is.na(nsw)) |>
  dplyr::select(
    sheets,
    update_year,
    revenue_name,
    "financial_year" = "x1",
    nsw:nt
  ) |>
  tidyr::pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue") |>
  dplyr::mutate(
    revenue = as.numeric(revenue),
    state_name =
      factor(
        stringr::str_to_upper(state_name),
        levels = cgc.abb,
        labels = cgc_names),
    revenue_type = "Adjusted"
  ) |>
  dplyr::select(names(revenue_assessed)) |>
  dplyr::filter(!is.na(revenue))

revenue_adjusted =
  dplyr::bind_rows(
    adjusted_revenue_pre_2020,
    adjusted_revenue_2021,
    adjusted_revenue_base
  ) |>
  dplyr::mutate(
    revenue_name =
      stringr::str_replace(
        revenue_name,
        "^assessed",
        "Total assessed"),
    revenue_name =
      stringr::str_replace(
        revenue_name,
        "Stamp duty.*",
        "Stamp duty"),
    revenue_name =
      stringr::str_replace(
        revenue_name,
        "Motor tax(es)",
        "Motor tax"),
    financial_year = fy::fy2date(financial_year)) |>
  dplyr::select(update_year, state_name, revenue_name, financial_year, revenue, revenue_type)

# Save for export
usethis::use_data(revenue_adjusted, overwrite = TRUE)

rm(adjusted_revenue_pre_2020,
   adjusted_revenue_2021,
   adjusted_revenue_base)





