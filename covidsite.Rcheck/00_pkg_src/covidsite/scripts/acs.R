library(tidyverse)
library(cwi)

pops <- multi_geo_acs("B01003", regions = cwi::regions[c("Greater New Haven")]) %>%
  janitor::clean_names()

pops %>%
  select(level, name, total_pop = estimate) %>%
  write_csv("input_data/total_pop_2018.csv")