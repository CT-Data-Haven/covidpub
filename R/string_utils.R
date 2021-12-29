.fmt_lt1 <- "
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
  htmlwidgets::JS(sprintf("function(value, ratio, id, index) {
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
d3_mdy          <- gen_d3("%m/%d/%y")

d3_lt1 <- htmlwidgets::JS(.fmt_lt1)

# avoiding installing camiller
clean_titles <- function(x) {
  x %>%
    stringr::str_replace_all("_", " ") %>%
    stringr::str_to_sentence()
}