# Get cgc fill urls
source("~/cgcRelativities/data-raw/get_cgc_urls.R")

# Get assessed revenue, most years are same format
assessed_revenue_base =
  cgc.data |>
  filter(
    update_year %in% c(2020,2022:2025),
    str_detect(sheets,"Assessed.*rev")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A2:j75", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  mutate(
    revenue = as.numeric(revenue),
    state_name = factor(str_to_upper(state_name), levels = cgc.abb, labels = cgc_names),
    revenue_type = "Assessed") |>
  filter(!is.na(revenue))

# @021 data starts in a different row
assessed_revenue_2021 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Assessed_budget"),
    update_year %in% c(2021),
    str_detect(sheets,"Assessed.*rev")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A3:j75", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  mutate(
    revenue = as.numeric(revenue),
    state_name = factor(str_to_upper(state_name), levels = cgc.abb, labels = cgc_names),
    revenue_type = "Assessed"
    ) |>
  filter(!is.na(revenue))

# Get remainding data
assessed_revenue_pre_2020 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "(A|a)ssessed"),
    update_year %in% c(2015:2019),
    str_detect(sheets,"Assessed.*rev"),
    !str_detect(download,"summary")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A2:j75", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  mutate(revenue_name = str_extract(x1,"[A-z]*\\s((t|T)ax|duty|revenue)")) |>
  fill(revenue_name) |>
  filter(x1!=revenue_name,!is.na(nsw)) |>
  select(
    update_year,
    revenue_name,
    "financial_year" = "x1",
    nsw:nt
  ) |>
  pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue") |>
  mutate(
    revenue = as.numeric(revenue)/1e6,
    state_name = factor(str_to_upper(state_name), levels = cgc.abb, labels = cgc_names),
    revenue_type = "Assessed"
  ) |>
  select(names(assessed_revenue_base)) |>
  filter(!is.na(revenue))

# Combine datasets for export
revenue_assessed =
  bind_rows(
    assessed_revenue_pre_2020,
    assessed_revenue_2021,
    assessed_revenue_base
  ) |>
  mutate(revenue_name = str_replace(revenue_name,"^assessed","Total assessed"),
         revenue_name = str_replace(revenue_name,"Stamp duty.*","Stamp duty"),
         revenue_name = str_replace(revenue_name,"Motor tax(es)","Motor tax"),
         financial_year = fy::fy2date(financial_year)) |>
  select(update_year, state_name, revenue_name, financial_year, revenue, revenue_type) |>
  unique()

rm(assessed_revenue_2021,assessed_revenue_base,assessed_revenue_pre_2020)
# Save for export
usethis::use_data(revenue_assessed, overwrite = TRUE)

# Get adjusted revenue
# Most years are consistent format, get those first
adjusted_revenue_base =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Adjusted_budget"),
    update_year %in% c(2020,2022:2025),
    str_detect(sheets,"Own.*revenue")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A3:j75", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  fill(revenue_name) |>
  pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  mutate(
    revenue = as.numeric(revenue),
    state_name = factor(str_to_upper(state_name), levels = cgc.abb, labels = cgc_names),
    revenue_type = "Adjusted") |>
  filter(!is.na(revenue))

# @021 data starts in a different row
adjusted_revenue_2021 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Adjusted_budget"),
    update_year %in% c(2021),
    str_detect(sheets,"rev")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A3:j75", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  select(update_year,
         "revenue_name" = "category",
         "financial_year",
         nsw:nt) |>
  fill(revenue_name) |>
  pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue" ) |>
  mutate(
    revenue = as.numeric(revenue),
    state_name = factor(str_to_upper(state_name), levels = cgc.abb, labels = cgc_names),
    revenue_type = "Adjusted"
  ) |>
  filter(!is.na(revenue))


adjusted_revenue_pre_2020 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "adjusted_budget"),
    update_year %in% c(2015:2019),
    str_detect(sheets,"Own.*rev"),
    !str_detect(download,"Summary")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A2:j75", col_names = TRUE, col_types = "text"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  mutate(revenue_name = str_extract(x1,"[A-z]*\\s((t|T)ax|duty|revenue)")) |>
  fill(revenue_name) |>
  filter(x1!=revenue_name,!is.na(nsw)) |>
  select(
    sheets,
    update_year,
    revenue_name,
    "financial_year" = "x1",
    nsw:nt
  ) |>
  pivot_longer(nsw:nt, names_to = "state_name", values_to = "revenue") |>
  mutate(
    revenue = as.numeric(revenue),
    state_name = factor(str_to_upper(state_name), levels = cgc.abb, labels = cgc_names),
    revenue_type = "Adjusted"
  ) |>
  select(names(revenue_assessed)) |>
  filter(!is.na(revenue))

revenue_adjusted =
  bind_rows(
    adjusted_revenue_pre_2020,
    adjusted_revenue_2021,
    adjusted_revenue_base
  ) |>
  mutate(revenue_name = str_replace(revenue_name,"^assessed","Total assessed"),
         revenue_name = str_replace(revenue_name,"Stamp duty.*","Stamp duty"),
         revenue_name = str_replace(revenue_name,"Motor tax(es)","Motor tax"),
         financial_year = fy::fy2date(financial_year)) |>
  select(update_year, state_name, revenue_name, financial_year, revenue, revenue_type)

# Save for export
usethis::use_data(revenue_adjusted, overwrite = TRUE)

rm(adjusted_revenue_pre_2020,
   adjusted_revenue_2021,
   adjusted_revenue_base)





