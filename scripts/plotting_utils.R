font_add("source", regular = "SourceSansPro-Regular.ttf", bold = "SourceSansPro-Bold.ttf")
showtext_auto()

theme_din2 <- function(...) {
  theme_gray(base_size = 11, ...) + 
    theme(legend.text = element_text(size = rel(0.75)), 
          legend.key.size = unit(0.8, "lines"), 
          legend.title = element_text(size = rel(0.9)),
          panel.background = element_blank(),
          panel.grid.major.y = element_line(color = "gray70"),
          plot.title = element_text(size = rel(1.1)),
          plot.subtitle = element_text(size = rel(0.9)))
}

# update_geom_defaults("text", list(family = "source", fontface = "bold"))
theme_set(theme_din2())