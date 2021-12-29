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
  xw <- geo_town_county()
  pops <- fetch_pops()
  bind_rows(
    fetch_county_cases() %>%
      select(level, name, date, cases),
    fetch_town_cases() %>%
      mutate(level = "town")
  ) %>%
    filter(date == d) %>%
    mutate(level = as_factor(level)) %>%
    left_join(xw, by = c("name" = "town")) %>%
    left_join(pops, by = "name") %>%
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
    mutate(across(race:measure, as_factor)) %>%
    filter(race %in% c("Average", "White", "Black", "Latino", "Asian")) %>%
    tidyr::pivot_wider(id_cols = c(date, race), names_from = measure, values_from = rate_10k,
                       names_glue = "{measure}_{.value}") %>%
    mutate(race = fct_recode(race, Total = "Average")) %>%
    arrange(race)
}

## AGGREGATE & CALC ----
# use tsibble to verify completeness of data
# TODO: add note that weekly aggs are end of week or avg
agg_weekly_cases <- function(eow = TRUE) {
  x <- fetch_county_cases() %>%
    tsibble::as_tsibble(key = c(level, name), index = date) %>%
    tsibble::group_by_key() %>%
    tsibble::index_by(week = ~tsibble::yearweek(., week_start = 1))
  if (eow) {
    summarise(x, across(cases:deaths, last))
  } else {
    summarise(x, across(cases:deaths, mean))
  }
}

agg_weekly_tests <- function() {
  fetch_state_tests() %>%
    tsibble::as_tsibble(key = name, index = date) %>%
    tsibble::group_by_key() %>%
    tsibble::index_by(week = ~tsibble::yearweek(., week_start = 1)) %>%
    summarise(weekly_tests = sum(daily_tests),
              positive_tests = sum(positive_tests),
              tests = last(tests))
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
    mutate(week = as.Date(week))
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