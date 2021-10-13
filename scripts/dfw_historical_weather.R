#===============================================================================
# Title: get_weather_data.R
# Author: Victor Faner
# Date Modified: 2021-07-14
# Description: Script to pull latest Dallas area weather data. Should be run on
#   a semi-regular basis (e.g. weekly)
#===============================================================================
library(here)
library(rnoaa)
library(readr)
library(dplyr)
library(tidyr)

master_dataset <- read_csv(here("data/dfw_historical_weather.csv"),
                           guess_max = 25000)
station_info <- master_dataset |>
  distinct(STATION, NAME, LATITUDE, LONGITUDE, ELEVATION)

# Get new data
auth <- "VxWtcSXxBlxkqOYTazhzNdYGScqMJACs"   # API Token
start_date <- as.Date(max(master_dataset$DATE)) - 1  # Exclude prior data
end_date <- Sys.Date()

options(warn = 2)  # Force stop script if no data found
new_data <- ncdc(datasetid = "GHCND", locationid = "CITY:US480016",
                 startdate = start_date, enddate = end_date,  token = auth,
                 limit = 1000, add_units = T)
options(warn = 1)  # Revert to default

# Reformat to match master dataset
new_cleaned <- new_data$data |>
  mutate(
    ATTRIBUTES = paste(fl_m, fl_q, fl_so, fl_t, sep = ","),
    STATION = gsub("GHCND:", "", station),
    DATE = as.Date(date),
    # Normalize measurement units
    value = as.double(value),
    value = if_else(grepl("tenths", units), value / 10, value)
  ) |>
  select(-fl_m, -fl_q, -fl_so, -fl_t, -units, -date, -station) |>
  pivot_wider(
    names_from = datatype,
    values_from = c(value, ATTRIBUTES),
    names_glue = "{datatype}_{.value}"
  ) |>
  rename_with(~toupper(gsub("_value", "", .x))) |>
  left_join(station_info, by = c("STATION" = "STATION"))

# Combine and write to file
updated_master <- bind_rows(master_dataset, new_cleaned) |>
  distinct() |>
  arrange(DATE)
updated_master |> write_csv(here("data/dfw_historical_weather.csv"))
