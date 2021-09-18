library(dplyr)

clean_titles <- function(x) {
  x <- stringr::str_replace_all(x, "_", " ")
  x <- stringr::str_to_sentence(x)
  x
}

set.seed(1)
vivid <- c("#888888", rcartocolor::carto_pal(9, "Vivid")[sample.int(8)])
seq_pal <- rcartocolor::carto_pal(5, "SunsetDark")
# div_pal <- chroma::interp_colors(5, colors = c(pal[7], "#b8566d"))
div_pal <- c("#52BCA3", "#7EA595", "#988E87", "#AA747A", "#B8566D")
div_pal2 <- c('#25b697', '#8bc3a3', '#cdcfb0', '#d58491', '#cd4a6e')

billboarder::set_theme("insight")

d3_flag <- "function(value, ratio, id, index) {
  return d3.format('+,')(value);
}"

d3_percent <- "function(value, ratio, id, index) {
  return d3.format('0.0%')(value);
}"

d3_percent_flag <- "function(value, ratio, id, index) {
  return d3.format('+0.0%')(value);
}"

lt1 <- "
  function(value) {
    // return value < 0.01 ? '<1%' : d3.format('0.0%')(value);
    var fmt = value < 0.1 ? '.1%' : '.0%';
    return value < 0.01 ? '<1%' : d3.format(fmt)(value);
  }
"



age_names <- function(x) {
  x <- stringr::str_replace_all(x, "(?<=\\d)_(?=\\d)", "-")
  x <- clean_titles(x)
  x <- stringr::str_replace(x, "plus", "+")
  x <- stringr::str_replace_all(x, "(?<=[A-Za-z])(\\d)", " \\1")
  x
}

####### mapping
# town_sf <- cwi::town_sf %>%
#   sf::st_transform(4326)
# saveRDS(town_sf, "input_data/town_sf.rds")
town_sf <- readRDS("input_data/town_sf.rds")
bbox <- town_sf %>%
  sf::st_buffer(1e-2) %>%
  sf::st_bbox() %>%
  as.numeric()