library(dplyr)

xwalk <- cwi::xwalk %>%
  distinct(county, town)

readr::write_csv(xwalk, "input_data/county2town.csv")