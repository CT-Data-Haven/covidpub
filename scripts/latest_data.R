# get latest date of statewide, print to console to show in build tools
county <- read.csv("input_data/covid_county.csv")
dates <- as.Date(county$date)
date_range <- format(range(dates), "%m/%d")
cat("***********************************************\n")
cat("Statewide data:", date_range[1], "to", date_range[2], "\n")
cat("***********************************************\n")
