
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
# install.packages("remotes")
remotes::install_github("zerogetsamgow/cgcRelativities")
```

## Relativities

Relativities data is stored in three files Data is stored as

- `relativies_recommended.rda`, the actual relativities recommended by
  the CGC.

``` r
recommended = cgcRelativities::relativities_recommended

dplyr::glimpse(recommended)
#> Rows: 216
#> Columns: 6
#> $ download        <chr> "./data-raw/20268._Relativities_over_ti…
#> $ update_year     <int> 2026, 2026, 2026, 2026, 2026, 2026, 202…
#> $ state_name      <fct> New South Wales, Victoria, Queensland, …
#> $ financial_year  <date> 2001-06-30, 2001-06-30, 2001-06-30, 20…
#> $ relativity      <dbl> 0.88914, 0.84510, 1.02507, 0.98692, 1.2…
#> $ relativity_type <chr> "Recommended", "Recommended", "Recommen…
```

- `relativies_annual.rda`, the annual relativities based on one year of
  assessment date used to calculate the recommendations

``` r
annual = cgcRelativities::relativities_annual

dplyr::glimpse(annual)
#> Rows: 264
#> Columns: 5
#> $ update_year     <int> 2016, 2017, 2016, 2018, 2017, 2016, 201…
#> $ state_name      <chr> "Australian Capital Territory", "Austra…
#> $ financial_year  <date> 2013-06-30, 2014-06-30, 2014-06-30, 20…
#> $ relativity      <dbl> 1.08701, 1.18811, 1.19179, 1.17701, 1.1…
#> $ relativity_type <chr> "Annual", "Annual", "Annual", "Annual",…
```

`relativies_floorless.rda` a set of imputed relativities assumming 2018
reforms had not been implemented.

``` r
floorless = cgcRelativities::relativities_floorless

dplyr::glimpse(floorless)
#> Rows: 88
#> Columns: 5
#> $ state_name      <chr> "Australian Capital Territory", "Austra…
#> $ update_year     <int> 2016, 2017, 2018, 2019, 2020, 2021, 202…
#> $ financial_year  <date> 2016-06-30, 2017-06-30, 2018-06-30, 20…
#> $ relativity      <dbl> 1.15648, 1.19496, 1.18070, 1.23759, 1.1…
#> $ relativity_type <chr> "Floorless", "Floorless", "Floorless", …
```
