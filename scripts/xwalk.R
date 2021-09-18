library(dplyr)

xwalk <- cwi::xwalk %>%
  mutate(county_code = substr(town_fips, 3, 5)) %>%
  distinct(county_code, town) %>%
  left_join(tidycensus::fips_codes %>% filter(state == "CT"), by = "county_code") %>%
  select(county, town)

readr::write_csv(xwalk, "input_data/county2town.csv")