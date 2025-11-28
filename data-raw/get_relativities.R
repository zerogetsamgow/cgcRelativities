# Get cgc fill urls
source("~/cgcRelativities/data-raw/get_cgc_urls.R")

# Get recommended relativities history from 2025 review
relativities_recommended =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "time"),
    str_detect(sheets,"S8"),
    update_year==2025
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="k2:s500"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  mutate(nsw = as.numeric(nsw)) |>
  filter(!is.na(nsw)) %>%
  pivot_longer(nsw:nt,names_to="state.abb",values_to="relativity")  |>
  mutate(
    relativity = as.numeric(relativity),
    state_name = factor(str_to_upper(state.abb), levels = cgc.abb, labels = cgc_names)
  ) |>
  select(update_year, state_name, financial_year, relativity) |>
  mutate(financial_year=fy::fy2date(financial_year),
         relativity_type="Recommended")

# Save for export
usethis::use_data(relativities_recommended, overwrite = TRUE)

# Get annual relativities for most recent years
cgc.relativities.2020.to.2025 =
  cgc.data |>
  filter(

    str_detect(
      file_name,
      "Calculation_of_relativities"),
    str_detect(sheets,"relativ"),
    str_detect(sheets,"S7-3")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="a1:j75"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  select(-contains("elati"))  |>
  filter(!is.na(x2)) |>
  mutate(financial_year =  str_extract(x2,"[0-9]{4}\\-[0-9]{2}")) |>
  fill(financial_year) |>
  rename("assess_name"=x1,
         "assess_average"=x10) |>
  filter(assess_average==1) |>
  pivot_longer(contains("x"),names_to="state_name",values_to="relativity")  |>
  mutate(
    relativity = as.numeric(relativity),
    state_index = str_extract(state_name,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = cgc_names[state_index]
  ) |>
  select(update_year, state_name, financial_year, relativity) |>
  group_by(update_year, state_name, financial_year) |>
  arrange(state_name, financial_year, desc(update_year)) |>
  ungroup()

# Get annual relativities for earlier years
cgc.relativities.pre2020 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Calculation_of_relativities"),
    str_detect(sheets,"Table S8")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A1:j500"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  filter(!is.na(x1),!is.na(x2)) %>%
  filter(str_detect(x1,"[0-9]{4}\\-[0-9]{2}")) |>
  rename("financial_year"=x1,
         "assess_average"=x10) |>
  pivot_longer(contains("x"),names_to="state_name",values_to="relativity")  |>
  mutate(
    relativity = as.numeric(relativity),
    state_index = str_extract(state_name,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = cgc_names[state_index]
  ) |>
  select(update_year, state_name, financial_year, relativity) |>
  group_by(update_year, state_name,financial_year) |>
  arrange(state_name,financial_year, desc(update_year)) |>
  ungroup()

# Combine yearly relativities
relativities_annual =
  bind_rows(
    cgc.relativities.pre2020,
    cgc.relativities.2020.to.2025

  ) |>
  mutate(financial_year=fy::fy2date(financial_year),
         relativity_type = "Annual")

rm(
  cgc.relativities.pre2020,
  cgc.relativities.2020.to.2025
)

# Save for export
usethis::use_data(relativities_annual, overwrite = TRUE)


# Calculate 'relativities_floorless' if floor wasn't introduced.
relativities_floorless =
  relativities_annual |>
  # filter(update_year %in% 2023:2025, relativity_year < today()) |>
  group_by(state_name, update_year) |>
  summarise(financial_year = last(financial_year)+years(1),
            relativity = mean(relativity)) |>
  add_column(relativity_type="Floorless") |>
  ungroup()

# Save for export
usethis::use_data(relativities_floorless, overwrite = TRUE)


latest_summary =
  cgc.data |>
  filter(
    str_detect(download,"Calculation"),
    str_detect(sheets,"yrly relativities"),
    update_year==2025
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="a2:j100"))  |>
  unnest(data) |>
  janitor::clean_names() |>
  filter(!is.na(x2)) |>
  mutate(financial_year =  str_extract(x2,"[0-9]{4}\\-[0-9]{2}")) |>
  fill(financial_year) |>
  select(financial_year,starts_with("x")) |>
  rename("assessment_category"=x1) |>
  pivot_longer(starts_with("x"), names_to = "state_index") |>
  mutate(
   state_index = str_extract(state_index,"[2-9]") |> as.numeric(),
   state_index = state_index - 1,
   state_name = factor(state_index, labels = cgc.abb),
   value = as.numeric(value)) |>
  filter(!is.na(value), state_name %in% strayr::state_abb_au) |>
  select(-state_index) |>
  pivot_wider(names_from = state_name)

usethis::use_data(latest_summary, overwrite = TRUE)


