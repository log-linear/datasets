#===============================================================================
# Title: get_holiday_data.R
# Author: Victor Faner
# Date Modified: 2021-07-14
# Description: Script to pull US holiday dates from holidata.net
#===============================================================================

library(dplyr)
library(readr)
library(here)

# Parameters
start_year <- 2013  # Earliest year to pull
end_year <- as.integer(format(Sys.Date(), "%Y"))
years <- as.character(seq(start_year, end_year))
url <- "http://holidata.net/en-US/"

# Get holiday data as a list of csv's, one for each year
holidata <- list()
for (year in years) {
  holidata[[year]] <- read_csv(paste0(url, year, ".csv"))
}

# Data wrangling
holidays <- bind_rows(holidata) |>
  select(-region, -notes) |>
  filter(description != "Patriots' Day") |>
  bind_rows(
    # Add New Year's Eve
    list(
      locale = "en-US",
      date = as.Date(paste(years, "12", "31", sep = "-")),
      description = "New Year's Eve",
      type = "NF"
    )
  ) |>
  mutate(
    # Clean up odd names
    description = case_when(
      description == "Birthday of Martin Luther King, Jr." ~ "MLK Day",
      description == "Washington's Birthday"               ~ "President's Day",
      TRUE                                                 ~ description
    ),
    # Get day of week
    weekday = as.POSIXlt(date)$wday,
  )

# Add extra dates for when July 4 falls on a weekend
holidays <- holidays |>
  bind_rows(
    holidays |>
      filter(
        description == "Independence Day"
        & (weekday == 6 | weekday == 0)
      ) |>
      mutate(
        date = case_when(weekday == 6 ~ date - 1, weekday == 0 ~ date + 1),
        weekday = case_when(
          weekday == 6 ~ weekday - 1,
          weekday == 0 ~ weekday + 1
        ),
        description = "Independence Day (City Observation)"
      )
  ) |>
  mutate(
    # Denote city holidays
    city_holiday = case_when(
      description == "Columbus Day" ~ F,
      description == "New Year's Eve" ~ F,
      description == "Veterans Day" ~ F,
      weekday == 0 ~ F,
      weekday == 6 ~ F,
      TRUE ~ T
    )
  ) |>
  rename(holiday = description) |>
  arrange(date)

holidays |> write_csv(here("data/us_holidays.csv"))
