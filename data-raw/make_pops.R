acs_base <- "https://api.census.gov/data/2019/acs/acs5"
acs_vars <- paste(c("NAME", "B01003_001E"), collapse = ",")
acs_for <- paste("county subdivision", "*", sep = ":")
acs_in <- paste(c("state", "county"), c("09", "*"), sep = ":", collapse = "&")
pop_read <- httr::GET(acs_base, 
          query = list(
            get = acs_vars,
            "for" = acs_for,
            "in" = acs_in,
            key = Sys.getenv("CENSUS_API_KEY")
          )) %>%
  httr::content(as = "text") %>%
  jsonlite::fromJSON(simplifyDataFrame = TRUE)

town_pops <- as.data.frame(pop_read[-1,]) %>%
  stats::setNames(pop_read[1,]) %>%
  dplyr::as_tibble() %>%
  dplyr::select(name = NAME, total_pop = 2) %>%
  dplyr::filter(!grepl("County subdivisions", name)) %>%
  tidyr::separate(name, into = c("name", "county", NA), sep = ", ") %>%
  dplyr::mutate(total_pop = readr::parse_number(total_pop),
                name = stringr::str_remove(name, "\\stown$"))

pops <- list(
  state = town_pops %>% dplyr::mutate(name = "Connecticut"),
  county = town_pops %>% dplyr::mutate(name = county),
  town = town_pops
) %>%
  dplyr::bind_rows(.id = "level") %>%
  dplyr::group_by(level = forcats::as_factor(level), name) %>%
  dplyr::summarise(total_pop = sum(total_pop)) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(town_pops %>% dplyr::select(-total_pop), by = "name")

usethis::use_data(pops, overwrite = TRUE)

town_county <- pops %>%
  dplyr::filter(!is.na(county)) %>%
  dplyr::select(town = name, county)

usethis::use_data(town_county, overwrite = TRUE)