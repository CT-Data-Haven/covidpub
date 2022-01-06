## INTERNAL USE ----
fmt_lt1 <- "
  function(value) {
    var fmt = value < 0.1 ? '.1%' : '.0%';
    return value < 0.01 ? '<1%' : d3.format(fmt)(value);
  }
"

gen_d3 <- function(x) {
  htmlwidgets::JS(sprintf("function(value, ratio, id, index) {
            return d3.format('%s')(value);
          }", x))
}
gen_d3time <- function(x) {
  htmlwidgets::JS(sprintf("function(value) {
            return d3.timeFormat('%s')(value);
          }", x))
}

d3_flag         <- gen_d3("+,d")
d3_percent      <- gen_d3("0.0%")
d3_percent_flag <- gen_d3("+0.0%")
d3_comma        <- gen_d3(",d")
d3_fix7         <- gen_d3("7,")
d3_fix9         <- gen_d3("9,")
d3_md           <- gen_d3("%m/%d")
d3_mdy          <- gen_d3time("%m/%d/%Y")
d3_bdy          <- gen_d3time("%b %d, %Y")

d3_lt1 <- htmlwidgets::JS(fmt_lt1)

# avoiding installing camiller
clean_titles <- function(x) {
  x %>%
    stringr::str_replace_all("_", " ") %>%
    stringr::str_to_sentence()
}

age_names <- function(x) {
  x <- stringr::str_replace_all(x, "(?<=\\d)_(?=\\d)", "-")
  x <- clean_titles(x)
  x <- stringr::str_replace(x, "plus", "+")
  x <- stringr::str_replace_all(x, "(?<=[A-Za-z])(\\d)", " \\1")
  x
}

## CALL DIRECTLY ----
#' @export
fmt_mdy <- function(x) {
  format(x, "%m/%d/%Y")
}

#' @export
fmt_bdy <- function(x) {
  format(x, "%b %e, %Y")
}

#' @export
fmt_Bdy <- function(x) {
  format(x, "%B %e, %Y")
}

#' @export
pct_sig2 <- function(x) {
  # percent formatting based on sigfigs
  paste0(signif(x * 100, digits = 2), "%")
}