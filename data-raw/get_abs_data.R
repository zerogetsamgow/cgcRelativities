source("~/cgcRelativities/data-raw/get_cgc_urls.R", echo = TRUE)

# Get actual tax revenue from ABS
taxation_gfs =
  tibble(
    abs_url =
      str_c("https://www.abs.gov.au/statistics/economy/government/",
            "taxation-revenue-australia/2023-24/55060DO001_202324.xlsx")
  ) |>
  mutate(
    file_name=basename(abs_url),
    download = file.path(cgc.path,file_name)
  ) |>
  mutate(x =
           pmap(
             list(abs_url, download),
             download_cgc
           )
  )  |>
  select(-x) |>
  # Get sheet names.
  mutate(sheets=map(download,readxl::excel_sheets)) |>
  unnest(sheets) |>
  filter(str_detect(sheets,"Table_[2-9]")) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A5:k50", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  rename("revenue_name" = x1) |>
  filter(!is.na(revenue_name), !str_detect(revenue_name, "(T|t)otal")) |>
  mutate(
    state_index = str_extract(sheets,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = strayr::state_name_au[state_index]
  ) |>
  tidyr::pivot_longer(
    starts_with("x"),
    names_to = "financial_year",
    values_to = "revenue"
  ) |>
  mutate(
    revenue = as.numeric(revenue),
    financial_year = str_extract(financial_year,"[0-9]{4}\\_[0-9]{2}") |> str_replace("_","-"),
    financial_year = fy::fy2date(financial_year)
  ) |>
  filter(
    financial_year > ymd("2000-6-30"),
    !is.na(revenue), revenue != 0 , !str_detect(revenue_name,"Municipal")
  ) |>
  mutate(
    revenue_type = "Actual",
    revenue_name = str_replace(revenue_name, ".*payroll.*","Payroll tax"),
    revenue_name = str_replace(revenue_name, ".*(I|i)nsurance.*","Insurance tax"),
    revenue_name = str_replace(revenue_name,"taxes","tax"),
    revenue_name = str_replace(revenue_name,".*vehicle.*","Motor tax"),
    revenue_name = str_replace(revenue_name,"Stamp.*","Stamp duty"),
    revenue_name = str_replace(revenue_name, ".*(gambling|betting|lotteries|Casino).*","Gambling tax"),
    revenue_name = str_replace(revenue_name,"(Other|Excises|Franchise|Government).*","Other tax"),
  ) |>
  group_by(
    state_name, financial_year, revenue_name, revenue_type
  ) |>
  summarise(revenue = sum(revenue),.groups = 'drop')

# Save for export
usethis::use_data(taxation_gfs, overwrite = TRUE)
remove(taxation_gfs)

# Get GFS data
abs_gfs =
  str_c("https://www.abs.gov.au/statistics/economy/government/",
        "government-finance-statistics-annual/latest-release") |>
  read_html() |>
  html_elements('div [href$=xlsx]') |>
  html_attr("href") |>
  as_tibble_col("url") |>
  mutate(
    url = str_c("https://www.abs.gov.au", url)
  ) |>
  filter(str_detect(url,"DO00[3-9]|DO010")) |>
  rowwise() |>
  mutate(
    download = tempfile(fileext = ".xlsx")) |>
  ungroup()  |>
  mutate(
    x =
      pmap(
        list(url,download),
        function(a,b) if(!file.exists(b)) download.file(a,b,mode="wb")))  |>
  select(-x) |>
  mutate(sheets = map(download,readxl::excel_sheets)) |>
  unnest(sheets) |>
  filter(sheets=="Table_1") |>
  mutate(data=pmap(list(download, sheets), readxl::read_excel, range="A5:k50", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  mutate(gfs_category = str_extract(x1,"GFS.*"), .before = "x1") |>
  fill(gfs_category) |>
  filter(!is.na(x1),!str_detect(x1,"Total")) |>
  rename("gfs_subcategory"=x1) |>
  pivot_longer(starts_with("x"), names_to = "financial_year") |>
  filter(!is.na(value)) |>
  mutate(
    value = as.numeric(value),
    financial_year =
           str_remove(financial_year,"x") |>
           str_replace("_","-") |>
           fy::fy2date() |>
           ceiling_date("months") - days(1),
         state_index =str_extract(url, "DO0[0-1][0-9]") |> str_remove("DO0") |> as.numeric() - 2,
    financial_year = fy::date2fy(financial_year) |> fy::fy2date(),
         state_name = strayr::state_name_au[state_index]) |>
  select(
  gfs_category,
  gfs_subcategory,
  state_name,
  financial_year,
  value
  )

revenue_gfs =
  abs_gfs |>
  filter(
    str_detect(gfs_category, "Revenue")
  )

expenses_gfs =
  abs_gfs |>
  filter(
    str_detect(gfs_category, "Expenses")
  )

usethis::use_data(revenue_gfs, overwrite = TRUE)
usethis::use_data(expenses_gfs, overwrite = TRUE)
remove(revenue_gfs, expenses_gfs, abs_gfs)

# Get and tidy estimated residential population data from ABS
population_erp =
  readabs::read_abs(
    "3101.0",
    check_local = "FALSE"
  )  |>
  readabs::separate_series() |>
  filter(
    series_3 %in% strayr::state_name_au,
    stringr::str_detect(
      series_2,
      "Persons")
  ) |>
  mutate(financial_year =
           lubridate::ceiling_date(
             date,
             unit = "month")-days(1))  |>
  group_by(
    "state_name"=series_3,
    financial_year,
    unit
  ) |>
  summarise(
    population=last(value), .groups = "drop"
  )

usethis::use_data(population_erp, overwrite = TRUE)
remove(population_erp)

estimated_gsp =
  "https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-state-accounts/latest-release" |>
  read_html() |>
  html_elements('div [href$=xlsx]') |>
  html_attr("href") |>
  as_tibble_col("url") |>
  mutate(
    url = str_c("https://www.abs.gov.au", url)
  ) |>
  filter(str_detect(url,"All")) |>
  mutate(
    download = tempfile(fileext = ".xlsx")) |>
  ungroup()  |>
  mutate(
    x =
      pmap(
        list(url,download),
        function(a,b) if(!file.exists(b)) download.file(a,b,mode="wb")))  |>
  select(-x) |>
  mutate(sheets = map(download,readxl::excel_sheets)) |>
  unnest(sheets) |>
  filter(str_detect(sheets,"Data")) |>
  # Extract data
  mutate(data=pmap(list(download,sheets), readxl::read_excel))  |>
  select(data) |>
  unnest(data) |>
  rename(
    "date" = 1
  ) |>
  mutate(
    date = janitor::excel_numeric_to_date(as.numeric(date))
  ) |>
  filter(
    !is.na(date)
  ) |>
  pivot_longer(
    -date,
    names_to = "series"
  ) |>
  mutate(value = as.numeric(value)) |>
  filter(
    !is.na(value)
  ) |>
  readabs::separate_series() |>
  filter(
    str_detect(series_2,"Gross state product: Current prices$"),
    !str_detect(series_1,"Total")
  ) |>
  select(
    date,
    "state_name" = series_1,
    "measure" = series_2,
    "gsp" = value
  ) |>
  mutate(financial_year = fy::date2fy(date) |> fy::fy2date()) |>
  group_by(
    financial_year,
    state_name,
    measure
  ) |>
  summarise(gsp = sum(gsp)) |>
  ungroup()


usethis::use_data(estimated_gsp, overwrite = TRUE)

