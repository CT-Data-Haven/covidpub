## CHARTS & TABLES ----

#' @export
make_1d_cases_table <- function(d) {
  x <- fetch_1d_cases(d)
  DT::datatable(x, 
            options = list(searching = FALSE, rowGroup = list(dataSrc = 0, emptyDataGroup = "State / counties")),
            rownames = FALSE, style = "bootstrap", class = "table table-sm table-hover", 
            plugins = c("simple_incremental_bootstrap")) %>%
    DT::formatRound("Cases", digits = 0) %>%
    DT::formatRound(4, digits = 0)
}

#' @export
make_age_adj_race_charts <- function(pal) {
  x <- fetch_age_adj() %>%
    rename(`Rate per 10k` = rate_10k) %>%
    mutate(measure = fct_relabel(measure, stringr::str_to_sentence)) %>%
    split(.$measure)
  purrr::imap(x, function(df, indicator) {
    billboarder(data = df, height = 350) %>%
      bb_barchart(mapping = bbaes(x = race, y = `Rate per 10k`), width = list(ratio = 0.5)) %>%
      bb_bar_color_manual(pal) %>%
      bb_legend(hide = TRUE) %>%
      bb_y_axis(label = list(text = indicator, position = "outer-top"),
                tick = list(format = d3_comma))
  })
}

#' @export
make_county_trend_chart <- function(pal) {
  x <- calc_county_cases_trend() %>%
    mutate(name = fct_relabel(name, stringr::str_remove, " County$")) %>%
    arrange(week, name)
  pal <- pal[names(pal) != "Connecticut"]
  
  billboarder(list(data = list(order = "asc")), data = x, height = 400) %>%
    bb_barchart(mapping = bbaes(x = week, y = cases, group = name), stacked = TRUE, width = list(ratio = 0.8)) %>%
    bb_x_axis(label = list(text = NULL, position = "outer-left"), type = "timeseries",
              tick = list(format = "%b %Y")) %>%
    bb_y_axis(label = list(text = "Cases", position = "outer-top"),
              tick = list(format = d3_comma),
              padding = list(bottom = 0)) %>%
    bb_colors_manual(pal) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_tooltip(grouped = FALSE,
               format = list(title = d3_bdy)) %>%
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
          tick = list(format = "%b %Y"),
          # tick = list(format = htmlwidgets::JS("d3.format('%m %d')")),
          label = list(text = NULL, position = "outer-left"),
          type = "timeseries",
          padding = list(left = 0)
        )
      ) %>%
      bb_grid(x = list(show = TRUE), y = list(show = TRUE, ticks = 5)) %>%
      bb_colors_manual(pal) %>%
      bb_title(position = "top-center", text = title) %>%
      bb_legend(show = has_legend) %>%
      bb_tooltip(linked = list(name = "trend-tip"), 
                 format = list(title = d3_bdy))
  })

  plts
}

#' @export
make_test_pos_chart <- function(pal) {
  x <- calc_test_pos()
  
  pal <- named_pal(x$measure, pal)
  
  billboarder(data = x, height = 300) %>%
    bb_linechart(mapping = bbaes(x = week, y = value, group = measure)) %>%
    bb_x_axis(label = list(text = NULL, position = "outer-left"), type = "timeseries",
              tick = list(format = "%b %Y")) %>%
    bb_y_axis(label = list(text = "Percent positive", position = "outer-top"),
              tick = list(format = d3_percent),
              padding = list(bottom = 0),
              min = 0) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_colors_manual(pal) %>%
    bb_legend(show = FALSE) %>%
    bb_tooltip(format = list(value = d3_lt1, title = d3_bdy))
}

#' @export
make_hosp_change_chart <- function(pal) {
  x <- calc_hospital_change()
  
  pal <- named_pal(x$direction, pal, drop = FALSE)
  
  billboarder(data = x, height = 300) %>%
    bb_barchart(mapping = bbaes(x = week, y = change, group = direction),
                width = list(ratio = 0.6), stack = TRUE) %>%
    bb_x_axis(label = list(text = NULL, position = "outer-left"), type = "timeseries",
              tick = list(format = "%b %Y")) %>%
    bb_y_axis(label = list(text = "Change in # hospitalized", position = "outer-top"),
              tick = list(format = d3_flag)) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_colors_manual(pal) %>%
    bb_tooltip(format = list(value = d3_flag, title = d3_bdy))
}

#' @export
make_period_change_table <- function(n = 7) {
  x <- calc_rolling_diff(n = n)
  
  x_wide <- x %>%
    mutate(across(c(date, start_date), format, "%m/%d/%Y"),
           period = paste(start_date, date, sep = " to ")) %>%
    tidyr::pivot_wider(id_cols = c(name), names_from = period, values_from = c(new_cases, pct_change))
  
  x_wide[ , colSums(!is.na(x_wide)) > 0] %>%
    rename_with(clean_titles) %>%
    rename_with(~stringr::str_replace(., "(?<=[a-z])(\\s)(?=\\d)", ", ")) %>%
    rename("Pct change in weekly new cases" = 4) %>%
    DT::datatable(options = list(searching = FALSE, paging = FALSE, info = FALSE),
                  rownames = FALSE, style = "bootstrap", class = "table table-sm table-hover") %>%
    DT::formatRound(2:3, digits = 0) %>%
    DT::formatPercentage(4)
}

#' @export
make_period_change_chart <- function(pal, n = 7) {
  x <- calc_rolling_change(n = n) %>%
    arrange(pct_change)
  
  pal <- named_pal(x$direction, pal)
  
  billboarder(data = x, height = 300) %>%
    bb_barchart(mapping = bbaes(x = date, y = new_cases, group = direction),
                width = list(ratio = 0.6), stack = TRUE) %>%
    bb_x_axis(label = list(text = NULL), type = "timeseries",
              tick = list(format = "%b %Y")) %>%
    bb_y_axis(label = list(text = "# new cases", position = "outer-top"),
              tick = list(format = d3_flag),
              max = max(x$new_cases)) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_colors_manual(pal) %>%
    bb_tooltip(format = list(value = d3_comma, title = d3_bdy))
}

#' @export
make_excess_deaths_chart <- function(pal) {
  x <- fetch_excess_deaths()
  
  pal <- c(named_pal(x$range, pal), list(avg_expected = "#44444f"))
  
  billboarder(data = x, height = 360) %>%
    bb_barchart(mapping = bbaes(x = date, y = observed, group = range),
                width = list(ratio = 1), stacked = TRUE) %>%
    bb_linechart(mapping = bbaes(x = date, y = avg_expected), show_point = FALSE) %>%
    bb_x_axis(label = list(text = NULL, position = "outer-left"), type = "timeseries",
              tick = list(format = "%b %Y")) %>%
    bb_y_axis(label = list(text = "# deaths", position = "outer-top"),
              tick = list(format = d3_comma),
              max = max(x$observed)) %>%
    bb_x_grid(show = TRUE) %>%
    bb_y_grid(show = TRUE) %>%
    bb_colors_manual(pal) %>%
    bb_legend(hide = "bb-x") %>%
    bb_tooltip(format = list(title = d3_bdy)) %>%
    bb_data(names = list(avg_expected = "Avg. expected"))
}

#' @export
make_cws_trust_chart <- function(pal) {
  x <- calc_cws_trust() %>%
    arrange(-value)
  
  pal <- named_pal(x$group, pal)
  
  billboarder(data = x, height = 350) %>%
    bb_barchart(mapping = bbaes(x = indicator, y = value, group = group)) %>%
    bb_legend(hide = TRUE) %>%
    bb_y_axis(label = list(text = "% who trust", position = "outer-top"),
              tick = list(format = d3_percent,
                          values = seq(0, 1, by = 0.1))) %>%
    bb_colors_manual(pal)
}

#' @export
make_cws_leave_home_chart <- function(pal) {
  x <- calc_cws_leave_home()
  
  # pal <- named_pal(x$category, pal, drop = FALSE)
  
  billboarder(data = x, height = 350) %>%
    bb_barchart(mapping = bbaes(x = group, y = value, group = category), 
                width = list(ratio = 0.5), stack = TRUE) %>%
    bb_colors_manual(pal) %>%
    bb_y_axis(label = list(text = "% workers who leave for work", position = "outer-top"),
              tick = list(format = d3_percent,
                          values = seq(0, 1, by = 0.1)),
              max = max(x$value)) %>%
    bb_legend(hide = TRUE)
}

#' @export
make_hhp_single_chart <- function(pal) {
  x <- calc_hhp_single()
  
  # pal <- named_pal(x[[1]]$category, pal, drop = FALSE)
  
  x %>%
    purrr::imap(function(df, indicator) {
      title <- stringr::str_replace_all(indicator, "_", " ")
      billboarder(data = df, height = 350) %>%
        bb_barchart(mapping = bbaes(x = group, y = share, group = category),
                    width = list(ratio = 0.5), stack = TRUE) %>%
        bb_colors_manual(pal) %>%
        bb_y_axis(label = list(text = paste("%", title), position = "outer-top"),
                  tick = list(format = d3_percent),
                  max = max(df$share)) %>%
        bb_legend(hide = TRUE)
    })
}

#' @export
make_hhp_housing_chart <- function(pal) {
  x <- calc_hhp_housing()
  
  pal <- named_pal(x$tenure, pal, drop = FALSE)
  
  billboarder(data = x, height = 350) %>%
    bb_barchart(mapping = bbaes(x = group, y = share, group = tenure), 
                width = list(ratio = 0.6), stack = FALSE, padding = 4) %>%
    bb_colors_manual(pal) %>%
    bb_y_axis(label = list(text = "% housing insecure", position = "outer-top"),
              tick = list(format = d3_percent),
              values = seq(0, 1, by = 0.1)) %>%
    bb_tooltip(grouped = FALSE)
}


