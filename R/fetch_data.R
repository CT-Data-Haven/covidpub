## READ DATA ----
fetch_main_date_range <- function() {
  fetch_county_cases() %>%
    pull(date) %>%
    range()
}

fetch_county_cases <- function() {
  readr::read_csv(here::here("input_data/covid_county.csv")) %>%
    mutate(level = as_factor(level),
           name = ifelse(level == "county", paste(name, "County"), name))
}

fetch_town_cases <- function() {
  readr::read_csv(here::here("input_data/covid_town.csv"))
}

fetch_state_tests <- function() {
  readr::read_csv(here::here("input_data/covid_tests.csv"))
}

fetch_1d_cases <- function(d) {
  # town_county & pops both package datasets
  bind_rows(
    fetch_county_cases() %>%
      select(level, name, date, cases),
    fetch_town_cases() %>%
      mutate(level = "town")
  ) %>%
    filter(date == d) %>%
    mutate(level = as_factor(level)) %>%
    left_join(pops, by = c("name", "level")) %>%
    mutate(`Cases per 10k residents` = round(cases / total_pop * 1e4, digits = 1)) %>%
    arrange(level, county, name) %>%
    select(county, name, cases, `Cases per 10k residents`) %>%
    rename_with(stringr::str_to_sentence)
}

fetch_pops <- function() {
  readr::read_csv(here::here("input_data/total_pop_2019.csv"))
}

fetch_age_adj <- function() {
  readr::read_csv(here::here("input_data/covid_age_adjusted_race.csv")) %>%
    filter(race %in% c("Average", "White", "Black", "Latino", "Asian")) %>%
    mutate(across(race:measure, as_factor),
           race = fct_recode(race, Total = "Average"),
           measure = fct_relabel(measure, paste, "per 10k"))
}

fetch_cws <- function() {
  readr::read_csv(here::here("input_data/cws_2020_covid_basic_profile.csv")) %>%
    mutate(across(c(category, group), as_factor),
           group = group %>%
             fct_relabel(stringr::str_replace_all, 
                         c("(^\\b)(?=\\d)" = "Ages ",
                           "(^)(?=\\<?\\$)" = "Income ")) %>%
             fct_recode(Men = "Male", Women = "Female"))
}

fetch_hhp <- function() {
  list.files(here::here("input_data"), "^hhp_", full.names = TRUE) %>%
    rlang::set_names(stringr::str_extract, "(?<=hhp_group_)(\\w+)(?=\\.csv)") %>%
    rlang::set_names(recode, food_insecurity = "food_insecure", loss_of_work = "lost_work") %>%
    purrr::map(readr::read_csv) %>%
    purrr::map(mutate, across(c(dimension, group), as_factor),
               group = group %>%
                 fct_recode(Total = "CT") %>%
                 fct_relabel(age_names) %>%
                 fct_relabel(clean_titles),
               dimension = fct_recode(dimension, CT = "total", "By race/ethnicity" = "race", "By presence of kids" = "kids_present", "By age" = "age_range")) %>%
    purrr::map(rename, category = dimension)
}

## AGGREGATE & CALC ----
# use tsibble to verify completeness of data
# TODO: add note that weekly aggs are end of week or avg
# make sure end of week has passed already--don't include partial weeks
# weekday should be at least thursday--only a couple times a week doesn't have data thru then
full_week <- function() {
  fetch_county_cases() %>%
    filter(name == "Connecticut") %>%
    tsibble::as_tsibble(key = name, index = date) %>%
    mutate(weekday = lubridate::wday(date, week_start = 1, label = TRUE)) %>%
    tsibble::group_by_key() %>%
    tsibble::index_by(week = ~tsibble::yearweek(., week_start = 1)) %>%
    summarise(n = n(),
              weekday = last(weekday),
              wk_start = first(date),
              wk_end = last(date)) %>%
    filter(n >= 4, weekday >= "Thu") %>%
    as_tibble() %>%
    select(week, wk_start, wk_end)
}

agg_weekly_cases <- function(eow = TRUE) {
  x <- fetch_county_cases() %>%
    tsibble::as_tsibble(key = c(level, name), index = date) %>%
    tsibble::group_by_key() %>%
    tsibble::index_by(week = ~tsibble::yearweek(., week_start = 1))
  if (eow) {
    out <- x %>%
      semi_join(full_week(), by = c("date" = "wk_end", "week")) %>%
      tsibble::update_tsibble(index = week) %>%
      select(-date)
  } else {
    out <- x %>%
      summarise(across(cases:deaths, mean))
  }
  ungroup(out)
}

agg_weekly_tests <- function() {
  fetch_state_tests() %>%
    tsibble::as_tsibble(key = name, index = date) %>%
    tsibble::group_by_key() %>%
    tsibble::index_by(week = ~tsibble::yearweek(., week_start = 1)) %>%
    summarise(weekly_tests = sum(daily_tests),
              positive_tests = sum(positive_tests),
              tests = last(tests)) %>%
    ungroup() %>%
    semi_join(full_week(), by = "week")
}



calc_county_cases_trend <- function() {
  agg_weekly_cases() %>%
    filter(level == "county") %>%
    mutate(name = as_factor(name) %>%
             fct_reorder(cases, .fun = max, .desc = FALSE),
           week = as.Date(week)) %>%
    as_tibble()
}

calc_metrics_trend <- function() {
  inner_join(
    agg_weekly_cases(),
    agg_weekly_tests(),
    by = c("name", "week")
  ) %>%
    as_tibble() %>%
    mutate(week = as.Date(week)) %>%
    select(-weekly_tests, -positive_tests)
}

calc_test_pos <- function() {
  agg_weekly_tests() %>%
    select(-tests) %>%
    mutate(test_positivity_rate = positive_tests / weekly_tests) %>%
    as_tibble() %>%
    tidyr::pivot_longer(-name:-positive_tests, names_to = "measure") %>%
    mutate(measure = fct_relabel(measure, clean_titles),
           week = as.Date(week))
}

calc_hospital_change <- function() {
  agg_weekly_cases(eow = FALSE) %>%
    filter(name == "Connecticut", !is.na(hospitalizations)) %>%
    mutate(change = slider::slide_index_dbl(hospitalizations, week, diff, .before = 1, .complete = TRUE),
           direction = case_when(
             change > 0 ~ "Increasing",
             change < 0 ~ "Decreasing",
             TRUE       ~ "Constant"
           ) %>%
             as.factor() %>%
             fct_relevel("Increasing", "Constant")) %>%
    filter(!is.na(change)) %>%
    as_tibble() %>%
    mutate(week = as.Date(week))
}

calc_hosp_streak <- function() {
  # give most recent decrease of more than 1 week
  calc_hospital_change() %>%
    mutate(streak = streak(direction)) %>%
    group_by(streak, direction) %>%
    summarise(across(c(week, hospitalizations), list(start = first, end = last), .names = "{.fn}_{.col}")) %>%
    mutate(duration = difftime(end_week, start_week, units = "weeks")) %>%
    filter(direction == "Decreasing", duration > 1)
}



calc_rolling_diff <- function(n = 7, periods = 0:1) {
  x <- fetch_county_cases() %>%
    select(-hospitalizations, -deaths) %>%
    tsibble::as_tsibble(key = c(level, name), index = date) %>%
    tsibble::group_by_key() %>%
    mutate(new_cases = slider::slide_index_dbl(cases, date, ~last(.x) - first(.x), .before = lubridate::days(n)),
           elapse = max(date) - date,
           rem = as.numeric(elapse) %% n) %>%
    filter(rem == 0)

  if (!is.null(periods)) {
    x <- x %>%
      filter(date %in% (max(date) - lubridate::days(periods * n)))
  }
  x %>%
    mutate(pct_change = tsibble::difference(new_cases, order_by = date) / lag(new_cases),
           start_date = date - (n - 1)) %>%
    as_tibble() %>%
    select(-rem, -elapse)
}

calc_rolling_change <- function(n = 7) {
  calc_rolling_diff(n = n, periods = NULL) %>%
    mutate(week = tsibble::yearweek(date),
           direction = cut(pct_change, 
                           breaks = c(-Inf, -0.1, -5e-3, 5e-3, 0.1, Inf), 
                           labels = c("Decrease", "Slight decrease", "Constant", "Slight increase", "Increase"),
                           include.lowest = TRUE)) %>%
    filter(name == "Connecticut",
           week > min(full_week()$week),
           !is.na(pct_change), 
           is.finite(pct_change)) %>%
    mutate(week = as.Date(week))
}

calc_cws_trust <- function() {
  fetch_cws() %>%
    select(category, group, matches("^trust_")) %>%
    filter(category == "All adults") %>%
    tidyr::pivot_longer(-category:-group, names_to = "indicator") %>%
    mutate(group = fct_recode(group, "Share of adults" = "Total"),
           indicator = as_factor(indicator) %>%
             fct_relabel(stringr::str_remove, "^trust_") %>%
             fct_relabel(clean_titles))
}

calc_cws_leave_home <- function() {
  fetch_cws() %>%
    select(category, group, leave_for_work_very_often) %>%
    tidyr::pivot_longer(-category:-group, names_to = "indicator") %>%
    filter(category %in% c("All adults", "Race/Ethnicity", "Children in household", "Income")) %>%
    mutate(category = category %>%
             fct_relevel("Income", after = 1) %>%
             fct_recode(CT = "All adults", "By race/ethnicity" = "Race/Ethnicity", "By income" = "Income", "By presence of kids" = "Children in household")) %>%
    arrange(category)
}

# combine housing insecurity
calc_hhp_housing <- function() {
  fetch_hhp()[c("housing_insecurity", "rent_insecurity")] %>%
    setNames(c("all_adults", "renters")) %>%
    bind_rows(.id = "tenure") %>%
    filter(category %in% c("CT", "By race/ethnicity", "By presence of kids")) %>%
    mutate(tenure = as_factor(tenure) %>%
             fct_relabel(clean_titles))
}

# single indicator
calc_hhp_single <- function() {
  x <- fetch_hhp()
  x[!names(x) %in% c("housing_insecurity", "rent_insecurity")]
}