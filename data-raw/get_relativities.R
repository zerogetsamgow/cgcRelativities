# Get cgc fill urls
source("~/cgcRelativities/data-raw/get_cgc_urls.R")

# Get recommended relativities history from 2025 review
relativities_recommended =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "time"),
    stringr::str_detect(sheets,"S8"),
    update_year==2025
  ) |>
  dplyr::mutate(
    data =
      purrr::pmap(list(download,sheets), readxl::read_excel, range="k2:s500"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::mutate(nsw = as.numeric(nsw)) |>
  dplyr::filter(!is.na(nsw)) |>
  tidyr::pivot_longer(nsw:nt, names_to = "state.abb", values_to = "relativity")  |>
  dplyr::mutate(
    relativity = as.numeric(relativity),
    state_name = factor(stringr::str_to_upper(state.abb), levels = cgc.abb, labels = cgc_names)
  ) |>
  dplyr::select(download, update_year, state_name, financial_year, relativity) |>
  dplyr::mutate(financial_year=fy::fy2date(financial_year),
         relativity_type="Recommended")

# Save for export
usethis::use_data(
  relativities_recommended, overwrite = TRUE)

remove(relativities_recommended)

# Get annual relativities for most recent years
cgc.relativities.2020.to.2025 =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "Calculation_of_relativities"),
    stringr::str_detect(sheets,"relativ"),
    stringr::str_detect(sheets,"S7-3")
  ) |>
  dplyr::mutate(
    data =
      purrr::pmap(list(download,sheets), readxl::read_excel, range="a1:j75"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::select(-contains("elati"))  |>
  dplyr::filter(!is.na(x2)) |>
  dplyr::mutate(
    financial_year = stringr::str_extract(x2,"[0-9]{4}\\-[0-9]{2}")) |>
  tidyr::fill(financial_year) |>
  dplyr::rename("assess_name"=x1,
         "assess_average"=x10) |>
  dplyr::filter(assess_average==1) |>
  tidyr::pivot_longer(contains("x"),names_to="state_name",values_to="relativity")  |>
  dplyr::mutate(
    relativity = as.numeric(relativity),
    state_index = stringr::str_extract(state_name,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = cgc_names[state_index]
  ) |>
  dplyr::select(update_year, state_name, financial_year, relativity) |>
  dplyr::group_by(update_year, state_name, financial_year) |>
  dplyr::arrange(state_name, financial_year, desc(update_year)) |>
  dplyr::ungroup()

# Get annual relativities for earlier years
cgc.relativities.pre2020 =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(
      file_name,
      "Calculation_of_relativities"),
    stringr::str_detect(sheets,"Table S8")
  ) |>
  dplyr::mutate(
    data =
      purrr::pmap(list(download,sheets), readxl::read_excel, range="A1:j500"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::filter(!is.na(x1),!is.na(x2)) |>
  dplyr::filter(stringr::str_detect(x1,"[0-9]{4}\\-[0-9]{2}")) |>
  dplyr::rename("financial_year"=x1,
         "assess_average"=x10) |>
  tidyr::pivot_longer(contains("x"),names_to="state_name",values_to="relativity")  |>
  dplyr::mutate(
    relativity = as.numeric(relativity),
    state_index = stringr::str_extract(state_name,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = cgc_names[state_index]
  ) |>
  dplyr::select(update_year, state_name, financial_year, relativity) |>
  dplyr::group_by(update_year, state_name,financial_year) |>
  dplyr::arrange(state_name,financial_year, desc(update_year)) |>
  dplyr::ungroup()

# Combine yearly relativities
relativities_annual =
  dplyr::bind_rows(
    cgc.relativities.pre2020,
    cgc.relativities.2020.to.2025
  ) |>
  dplyr::mutate(
    financial_year=fy::fy2date(financial_year),
    relativity_type = "Annual")

# Clean environment

rm(
  cgc.relativities.pre2020,
  cgc.relativities.2020.to.2025
)

# Save for export
usethis::use_data(relativities_annual, overwrite = TRUE)


# Calculate 'relativities_floorless' if floor wasn't introduced.
relativities_floorless =
  relativities_annual |>
  # dplyr::filter(update_year %in% 2023:2025, relativity_year < today()) |>
  dplyr::group_by(state_name, update_year) |>
  dplyr::summarise(
    financial_year = dplyr::last(financial_year) + lubridate::years(1),
    relativity = mean(relativity)) |>
  tibble::add_column(relativity_type = "Floorless") |>
  dplyr::ungroup()

# Save for export
usethis::use_data(relativities_floorless, overwrite = TRUE)


latest_summary =
  cgc.data |>
  dplyr::filter(
    stringr::str_detect(download,"Calculation"),
    stringr::str_detect(sheets,"yrly relativities"),
    update_year==2025
  ) |>
  dplyr::mutate(
    data = purrr::pmap(list(download,sheets), readxl::read_excel, range="a2:j100"))  |>
  tidyr::unnest(data) |>
  janitor::clean_names() |>
  dplyr::filter(!is.na(x2)) |>
  dplyr::mutate(
    financial_year =  stringr::str_extract(x2,"[0-9]{4}\\-[0-9]{2}")) |>
  tidyr::fill(financial_year) |>
  dplyr::select(financial_year,starts_with("x")) |>
  dplyr::rename("assessment_category"=x1) |>
  tidyr::pivot_longer(starts_with("x"), names_to = "state_index") |>
  dplyr::mutate(
   state_index = stringr::str_extract(state_index,"[2-9]") |> as.numeric(),
   state_index = state_index - 1,
   state_name = factor(state_index, labels = cgc.abb),
   value = as.numeric(value)) |>
  dplyr::filter(!is.na(value), state_name %in% strayr::state_abb_au) |>
  dplyr::select(financial_year,assessment_category, state_name, value)

usethis::use_data(latest_summary, overwrite = TRUE)
remove(latest_summary)

#Clean up
files = unique(cgc.data$download)
file.remove(files)
