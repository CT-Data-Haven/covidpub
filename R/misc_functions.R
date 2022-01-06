## COLORS ----
#' @export
make_colors <- function() {
  qual_pal <- c("#888888", "#5D69B1", "#52BCA3", "#DAA51B", "#E58606", "#CC61B0", "#99C945", "#2F8AC4", "#24796C")
  div_pal3 <- c("#52BCA3", "#988E87", "#B8566D")
  div_pal5 <- c('#25b697', '#8bc3a3', '#cdcfb0', '#d58491', '#cd4a6e')
  tibble::lst(qual_pal, div_pal3, div_pal5)
}

named_pal <- function(x, pal, drop = TRUE) {
  if (is.factor(x)) {
    if (drop) {
      lvls <- levels(forcats::fct_drop(x))
    } else {
      lvls <- levels(x)
    }
  } else {
    lvls <- unique(x)
  }
  setNames(pal[seq_along(lvls)], lvls)
}

## GEOGRAPHY ----
# town_county is a package dataset now

## DATES ----
streak <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  durations <- rle(x)$lengths
  unlist(purrr::imap(durations, function(d, i) rep(i, times = d)))
}

#' @export
duration_wks <- function(x, count_first = FALSE) {
  out <- floor(as.numeric(diff(x), units = "weeks"))
  if (count_first) {
    out + 1
  } else {
    out
  }
}