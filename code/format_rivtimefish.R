#' Organize RivTimeFish data

pacman::p_load(tidyverse,
               sf,
               mapview)

rm(list = ls())


# read data ---------------------------------------------------------------

## read data, janitor::clean_names() fix column names to snake case
df_ts <- read_csv("data_src/data_rtf_ts.csv") %>% 
  janitor::clean_names()

df_survey <- read_csv("data_src/data_rtf_survey.csv") %>% 
  janitor::clean_names()

## subset and join data
df_f <- df_ts %>% 
  filter(region == "NORTH CAROLINA") %>% 
  left_join(df_survey)

view(df_f)

df_year <- df_f %>% 
  group_by(year) %>% 
  summarize(n_site = n_distinct(time_series_id))

# maybe do 2004-2006, then 2014-2016?
df_map <- df_f %>% 
  distinct(
    time_series_id,
    latitude,
    longitude) %>% 
  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326
  )

sf_nc_county <- readRDS("C:/Users/mitch/Desktop/I'm gitting/sf_nc_county.rds")

mapview(df_map) +
  (sf_nc_county)


