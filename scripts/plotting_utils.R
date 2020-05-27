clean_titles <- function(x) {
  x <- stringr::str_replace_all(x, "_", " ")
  x <- stringr::str_to_sentence(x)
  x
}

set.seed(1)
vivid <- c("gray20", rcartocolor::carto_pal(9, "Vivid")[sample.int(8)])
seq_pal <- rcartocolor::carto_pal(5, "SunsetDark")
# div_pal <- chroma::interp_colors(5, colors = c(pal[7], "#b8566d"))
div_pal <- c("#52BCA3", "#7EA595", "#988E87", "#AA747A", "#B8566D")

billboarder::set_theme("insight")

# not currently using ggplot
# font_add("source", regular = "SourceSansPro-Regular.ttf", bold = "SourceSansPro-Bold.ttf")
# showtext_auto()
# 
# theme_din2 <- function(...) {
#   theme_gray(base_size = 11, ...) + 
#     theme(legend.text = element_text(size = rel(0.75)), 
#           legend.key.size = unit(0.8, "lines"), 
#           legend.title = element_text(size = rel(0.9)),
#           panel.background = element_blank(),
#           panel.grid.major.y = element_line(color = "gray70"),
#           plot.title = element_text(size = rel(1.1)),
#           plot.subtitle = element_text(size = rel(0.9)))
# }

# update_geom_defaults("text", list(family = "source", fontface = "bold"))
# theme_set(theme_din2())
