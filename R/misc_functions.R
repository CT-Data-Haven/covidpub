## COLORS ----
#' @export
make_colors <- function() {
  qual_pal <- c("#888888", "#5D69B1", "#52BCA3", "#DAA51B", "#E58606", "#CC61B0", "#99C945", "#2F8AC4", "#24796C")
  div_pal3 <- c("#52BCA3", "#988E87", "#B8566D")
  div_pal5 <- c('#25b697', '#8bc3a3', '#cdcfb0', '#d58491', '#cd4a6e')
  tibble::lst(qual_pal, div_pal3, div_pal5)
}

named_pal <- function(x, pal) {
  if (is.factor(x)) {
    lvls <- levels(x)
  } else {
    lvls <- unique(x)
  }
  setNames(pal[seq_along(lvls)], lvls)
}

## GEOGRAPHY ----
geo_town_county <- function() {
  cwi::xwalk %>%
    distinct(county, town)
}

## DATES ----
streak <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  durations <- rle(x)$lengths
  unlist(purrr::imap(durations, function(d, i) rep(i, times = d)))
}
