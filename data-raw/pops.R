# write to csv instead of exporting
pops <- cwi::multi_geo_acs("B01003", regions = cwi::regions[c("Greater New Haven")], year = 2019)

pops %>%
  dplyr::select(name, total_pop = estimate) %>%
  readr::write_csv("input_data/total_pop_2019.csv")