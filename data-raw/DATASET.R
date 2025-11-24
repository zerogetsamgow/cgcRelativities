# Library
library(tidyverse)
library(rvest)
library(readxl)
library(openxlsx)

# Define paths, both local and online
cgc.path = "./data-raw"
cgc.url = "https://www.cgc.gov.au/reports-for-government/"

# Create table of URLs to search for files
cgc.data =
  tibble::tibble(
    "update_year" = 2015:2025
  ) %>%
  dplyr::mutate(
    # CGC urls vary across update_years and reviews, so create correct urls below
    cgc.update.url = if_else(update_year %in% 2025,
                             str_c(cgc.url,update_year,"-methodology-review/gst-relativities-2025-26"),str_c(cgc.url,update_year,"-update")),
    cgc.update.url = if_else(update_year %in% 2024:2025,
                             str_c(cgc.update.url,"/tables-charts-and-supporting-data"),
                             cgc.update.url),
    cgc.update.url = if_else(update_year %in% 2022:2023,
                             str_c(cgc.update.url,"/supporting-data"),
                             cgc.update.url),
    cgc.update.url = if_else(update_year %in% c(2015,2020),
                             str_replace(cgc.update.url,"update","review"),
                             cgc.update.url)
  )  |>
  # Find files reference at each url
  mutate(file.url=pmap(list(cgc.update.url), get_cgc_files)) |>
  unnest(file.url) |>
  # Clean names for easier handling
  mutate(file_name=basename(file.url) |>
           str_remove_all("^[ruU][0-9]{4}") |>
           str_replace_all("(\\%2[0-9])+"," ") |>
           str_replace_all("_"," ") |>
           str_remove("(\\s)*\\-(\\s)*(2015\\s)*(Review|Report)") |>
           str_replace_all("(\\s)[0-9]*\\.xlsx",".xlsx ") |>
           str_to_title() |>
           trimws() %>%
           str_c(update_year,.),
         # Create download target
         download=file.path(cgc.path,file_name))  |>
  # Download files, if not already stored locally
  mutate(x =
           pmap(
             list(file.url, download),
             download_cgc
           )
  )  |>
  select(-x) |>
  # Get sheet names.
  mutate(sheets=map(download,readxl::excel_sheets)) |>
  unnest(sheets)

# CGC orders by current population. ABS and strayr use different order
cgc_names = strayr::state_name_au[c(1:3,5,4,6,8,7)]
cgc.abb = strayr::state_abb_au[c(1:3,5,4,6,8,7)]

# Get annual relativities for most recent years, (different sheet name and format)
cgc.relativities.after2020 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Calculation Of Relativities"),
    str_detect(sheets,"relativ"),
    !str_detect(sheets,"13")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A1:j200"))  |>
  unnest(data) |>
  select(-contains("elati"))  |>
  filter(is.na(...1)) |>
  mutate(relativity_year =  str_extract(...2,"[0-9]{4}\\-[0-9]{2}")) |>
  fill(relativity_year) |>
  rename("assess_name"=...1,
         "assess_average"=...10) |>
  filter(assess_average==1) |>
  select(-contains("per capita elati"))  |>
  pivot_longer(contains("..."),names_to="state_name",values_to="assess_value")  |>
  mutate(
    assess_value = as.numeric(assess_value),
    assess_average = as.numeric(assess_average),
    state_index = str_extract(state_name,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = cgc_names[state_index]
  ) |>
  select(update_year, state_name, relativity_year, assess_value) |>
  group_by(update_year, state_name, relativity_year) |>
  arrange(state_name, relativity_year, desc(update_year))


cgc.relativities.2020 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Calculation Of Relativities"),
    str_detect(sheets,"Assessed relativ"),
    update_year == 2020
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A1:j200"))  |>
  unnest(data) |>
  select(-contains("elati"))  |>
  filter(!is.na(...1),!is.na(...2)) |>
  filter(str_detect(...1,"[0-9]{4}\\-[0-9]{2}")) |>
  rename("relativity_year"=...1,
         "assess_average"=...10) |>
  select(-contains("per capita elati"))  |>
  pivot_longer(contains("..."),names_to="state_name",values_to="assess_value")  |>
  mutate(
    assess_value = as.numeric(assess_value),
    assess_average = as.numeric(assess_average),
    state_index = str_extract(state_name,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = cgc_names[state_index]
  ) |>
  select(update_year, state_name, relativity_year, assess_value) |>
  group_by(update_year, state_name, relativity_year) |>
  arrange(state_name, relativity_year, desc(update_year))


# Get annual relativities for earlier years
cgc.relativities.pre2020 =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Calculation Of Relativities"),
    str_detect(sheets,"Table S8")
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="A1:j500"))  |>
  unnest(data) |>
  select(-contains("elati")) %>%
  filter(!is.na(...1),!is.na(...2)) %>%
  filter(str_detect(...1,"[0-9]{4}\\-[0-9]{2}")) |>
  rename("relativity_year"=...1,
         "assess_average"=...10) |>
  pivot_longer(contains("..."),names_to="state_name",values_to="assess_value")  |>
  mutate(
    assess_value = as.numeric(assess_value),
    assess_average = as.numeric(assess_average),
    state_index = str_extract(state_name,"[0-9]") |> as.numeric(),
    state_index = state_index - 1,
    state_name = cgc_names[state_index]
  ) |>
  select(update_year, state_name, relativity_year, assess_value) |>
  group_by(update_year, state_name,relativity_year) |>
  arrange(state_name,relativity_year, desc(update_year))

# Combine yearly relativities
relativities_annual =
  bind_rows(
    cgc.relativities.pre2020,
    cgc.relativities.2020,
    cgc.relativities.after2020
  ) |>
  mutate(relativity_year=fy::fy2date(relativity_year),
         relativity_type = "Annual")

# Save for export
usethis::use_data(relativities_annual, overwrite = TRUE)

# Get recommended relativities upt to 2021-22 (before floor was introduced)
relativities_recommended =
  cgc.data |>
  filter(
    str_detect(
      file_name,
      "Time"),
    str_detect(sheets,"S8"),
    update_year==2025
  ) |>
  mutate(data=pmap(list(download,sheets), readxl::read_excel, range="k2:s500"))  |>
  unnest(data) |>
  mutate(NSW = as.numeric(NSW)) |>
  filter(!is.na(NSW)) %>%
  rename("relativity_year"=FinancialYear) |>
  pivot_longer(NSW:NT,names_to="state.abb",values_to="assess_value")  |>
  mutate(
    assess_value = as.numeric(assess_value),
    state_name = factor(str_to_upper(state.abb), levels = cgc.abb, labels = cgc_names)
  ) |>
  select(update_year, state_name, relativity_year, assess_value) |>
  group_by(update_year, state_name,relativity_year) |>
  arrange(state_name,relativity_year, desc(update_year))  |>
  mutate(relativity_year=fy::fy2date(relativity_year)+years(1)) |>
  add_column(relativity_type="Recommended")|>
  ungroup()

# Save for export
usethis::use_data(relativities_recommended, overwrite = TRUE)



# Calculate 'relativities_floorless' if floor wasn't introduced.
relativities_floorless =
  relativities_yearly |>
 # filter(update_year %in% 2023:2025, relativity_year < today()) |>
  group_by(state_name, update_year) |>
  summarise(relativity_year = last(relativity_year)+years(1),
            assess_value = mean(assess_value)) |>
  add_column(relativity_type="Floorless") |>
  ungroup()

# Save for export
usethis::use_data(relativities_floorless, overwrite = TRUE)
