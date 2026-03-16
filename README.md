
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cgcRelativities

<!-- badges: start -->

![GitHub R package
version](https://img.shields.io/github/r-package/v/zerogetsamgow/cgcRelativities)
![GitHub last
commit](https://img.shields.io/github/last-commit/zerogetsamgow/cgcRelativities)
<!-- badges: end -->

cgcRelativities provides tidy data versions of certain data tables from
the Commonwealth Grant’s Commission’s annual [Reports to
Government](https://www.cgc.gov.au/reports-for-government).

At present data on relativities and own source revenue are included in
the package.

## Installation

You can install the development version of cgcRelativities from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("zerogetsamgow/cgcRelativities")
```

## Relativities

Relativities data is stored in three files Data is stored as

- `relativies_recommended.rda`, the actual relativities recommended by
  the CGC.

``` r
recommended = cgcRelativities::relativities_recommended

dplyr::glimpse(recommended)
#> Rows: 208
#> Columns: 6
#> $ download        <chr> "./data-raw/20258._Relativities_over_time.xlsx", "./da…
#> $ update_year     <int> 2025, 2025, 2025, 2025, 2025, 2025, 2025, 2025, 2025, …
#> $ state_name      <fct> New South Wales, Victoria, Queensland, Western Austral…
#> $ financial_year  <date> 2001-06-30, 2001-06-30, 2001-06-30, 2001-06-30, 2001-…
#> $ relativity      <dbl> 0.8891397, 0.8451044, 1.0250686, 0.9869240, 1.2043289,…
#> $ relativity_type <chr> "Recommended", "Recommended", "Recommended", "Recommen…
```

- `relativies_annual.rda`, the annual relativities based on one year of
  assessment date used to calculate the recommendations

``` r
annual = cgcRelativities::relativities_annual

dplyr::glimpse(annual)
#> Rows: 240
#> Columns: 5
#> $ update_year     <int> 2016, 2017, 2016, 2018, 2017, 2016, 2019, 2018, 2017, …
#> $ state_name      <chr> "Australian Capital Territory", "Australian Capital Te…
#> $ financial_year  <date> 2013-06-30, 2014-06-30, 2014-06-30, 2015-06-30, 2015-…
#> $ relativity      <dbl> 1.0870078, 1.1881117, 1.1917922, 1.1770131, 1.1997169,…
#> $ relativity_type <chr> "Annual", "Annual", "Annual", "Annual", "Annual", "Ann…
```

`relativies_floorless.rda` a set of imputed relativities assumming 2018
reforms had not been implemented.

``` r
floorless = cgcRelativities::relativities_floorless

dplyr::glimpse(floorless)
#> Rows: 80
#> Columns: 5
#> $ state_name      <chr> "Australian Capital Territory", "Australian Capital Te…
#> $ update_year     <int> 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, …
#> $ financial_year  <date> 2016-06-30, 2017-06-30, 2018-06-30, 2019-06-30, 2020-…
#> $ relativity      <dbl> 1.1564809, 1.1949631, 1.1807033, 1.2375893, 1.1511166,…
#> $ relativity_type <chr> "Floorless", "Floorless", "Floorless", "Floorless", "F…
```
