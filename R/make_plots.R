#' @export
make_1d_cases_table <- function(d) {
  x <- fetch_1d_cases(d)
  DT::datatable(x, 
            options = list(searching = FALSE, rowGroup = list(dataSrc = 0, emptyDataGroup = "State / counties")),
            rownames = FALSE, style = "bootstrap", class = "table table-striped", 
            plugins = c("simple_incremental_bootstrap")) %>%
    DT::formatRound("Cases", digits = 0) %>%
    DT::formatRound(4, digits = 0)
}

#' @export
make_race_cases_chart <- function(pal) {
  x <- fetch_age_adj()
  billboarder(data = x, height = 350) %>%
    bb_barchart(mapping = bbaes(x = race, y = cases_rate_10k), width = list(ratio = 0.5)) %>%
    bb_bar_color_manual(pal) %>%
    bb_legend(hide = TRUE) %>%
    bb_y_axis(label = list(text = "Cases per 10k", position = "outer-top"),
              tick = list(format = d3_comma))
}

#' @export
make_race_deaths_chart <- function(pal) {
  x <- fetch_age_adj()
  billboarder(data = x, height = 350) %>%
    bb_barchart(mapping = bbaes(x = race, y = deaths_rate_10k), width = list(ratio = 0.5)) %>%
    bb_bar_color_manual(pal) %>%
    bb_legend(hide = TRUE) %>%
    bb_y_axis(label = list(text = "Deaths per 10k", position = "outer-top"),
              tick = list(format = d3_comma))
}

#' @export
make_county_trend_chart <- function(pal) {
  x <- calc_county_cases_trend() %>%
    mutate(name = fct_relabel(name, stringr::str_remove, " County$")) %>%
    arrange(week, name)
  pal <- pal[names(pal) != "Connecticut"]
  
  billboarder(list(data = list(order = "asc")), data = x, height = 400) %>%
    bb_barchart(mapping = bbaes(x = week, y = cases, group = name), stacked = TRUE, width = list(ratio = 0.8)) %>%
    bb_x_axis(label = list(text = NULL), type = "timeseries",
              tick = list(format = "%m/%d/%y")) %>%
    bb_y_axis(label = list(text = "Cases", position = "outer-top"),
              tick = list(format = d3_comma),
              padding = list(bottom = 0)) %>%
    bb_colors_manual(pal) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_tooltip(grouped = FALSE) %>%
    bb_title(padding = list(bottom = 20, top = 10), position = "top-left")
}

#' @export
make_metrics_trend_chart <- function(pal) {
  x <- calc_metrics_trend() %>%
    tidyr::pivot_longer(c(-level, -name, -week), names_to = "measure") %>%
    mutate(measure = as_factor(measure) %>%
             fct_relevel("tests", "cases", "hospitalizations") %>%
             fct_recode("detected cases" = "cases", "tests completed" = "tests", "current hospitalizations" = "hospitalizations") %>%
             fct_relabel(stringr::str_to_sentence)) %>%
    filter(!is.na(value)) %>%
    arrange(measure) %>%
    mutate(type = fct_collapse(measure, "Hospitalizations & deaths" = c("Current hospitalizations", "Deaths")))
  x_split <- x %>%
    split(.$type)
  
  params <- tibble::enframe(x_split, name = "title", value = "df") %>%
    mutate(h = c(170, 170, 190), 
           has_legend = c(FALSE, FALSE, TRUE))
  
  pal <- named_pal(x$measure, pal)
  
  plts <- purrr::pmap(params, function(title, df, h, has_legend) {
    y_range <- c(0, max(df$value))
    brks <- scales::breaks_extended(n = 5)(y_range)
    billboarder(bb_opts = list(padding = list(left = 100)), data = df, height = h) %>%
      bb_linechart(mapping = bbaes(x = week, y = value, group = measure)) %>%
      bb_axis(
        y = list(
          tick = list(values = brks, format = d3_comma),
          label = list(text = "Count", position = "outer-top"),
          padding = list(bottom = 0)
        ),
        x = list(
          tick = list(format = "%m/%d/%y"),
          # tick = list(format = htmlwidgets::JS("d3.format('%m %d')")),
          label = list(text = NULL),
          type = "timeseries",
          padding = list(left = 0)
        )
      ) %>%
      bb_grid(x = list(show = TRUE), y = list(show = TRUE, ticks = 5)) %>%
      bb_colors_manual(pal) %>%
      bb_title(position = "top-center", text = title) %>%
      bb_legend(show = has_legend) %>%
      bb_tooltip(linked = list(name = "trend-tip"))
  })

  purrr::walk(plts, print)
}

#' @export
make_test_pos_chart <- function(pal) {
  x <- calc_test_pos() %>%
    tidyr::pivot_longer(-name:-positive_tests, names_to = "measure") %>%
    mutate(measure = fct_relabel(measure, clean_titles))
  
  pal <- named_pal(x$measure, pal)
  
  billboarder(data = x, height = 300) %>%
    bb_linechart(mapping = bbaes(x = week, y = value, group = measure)) %>%
    bb_x_axis(label = list(text = NULL), type = "timeseries",
              tick = list(format = "%m/%d/%y")) %>%
    bb_y_axis(label = list(text = "Percent positive", position = "outer-top"),
              tick = list(format = d3_percent),
              padding = list(bottom = 0),
              min = 0) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_colors_manual(pal) %>%
    bb_legend(show = FALSE) %>%
    bb_tooltip(format = list(value = d3_lt1))
}

#' @export
make_hosp_change_chart <- function(pal) {
  x <- calc_hospital_change()
  
  pal <- named_pal(x$direction, pal)
  
  billboarder(data = x, height = 300) %>%
    bb_barchart(mapping = bbaes(x = week, y = change, group = direction),
                width = list(ratio = 0.6), stacked = TRUE) %>%
    bb_x_axis(label = list(text = NULL), type = "timeseries",
              tick = list(format = "%m/%d/%y")) %>%
    bb_y_axis(label = list(text = "Change in # hospitalized", position = "outer-top"),
              tick = list(format = d3_flag)) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_colors_manual(pal) %>%
    bb_legend(hide = c("Constant")) %>%
    bb_tooltip(format = list(value = d3_flag))
}

#' @export
make_hosp_streak_txt <- function() {
  # give most recent decrease of more than 1 week
  calc_hosp_streak() %>%
    slice_max(end_week)
}