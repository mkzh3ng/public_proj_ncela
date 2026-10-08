pacman::p_load(tidyverse,
               sf,
               mapview)

df_ts <- read.csv("C:/Users/mitch/Desktop/I'm gitting/1873_12_1873_2_RivFishTIME_TimeseriesTable.csv")

df_nc <- df_ts %>% 
  filter(Region == "NORTH CAROLINA")

df_survey <- read.csv("C:/Users/mitch/Desktop/I'm gitting/1873_12_1873_2_RivFishTIME_SurveyTable.csv")

df_f <- left_join(df_nc, df_survey)

view(df_f)

df_year <- df_f %>% 
  group_by(Year) %>% 
  summarize(n_site = n_distinct(TimeSeriesID))

# maybe do 2004-2006, then 2014-2016?

df_map <- df_f %>% 
  select(Latitude, Longitude, TimeSeriesID) %>% 
  distinct(TimeSeriesID, Latitude, Longitude) %>% 
  st_as_sf(coords = c("Longitude", "Latitude"),
           crs = 4326)

sf_nc_county <- readRDS("C:/Users/mitch/Desktop/I'm gitting/sf_nc_county.rds")

mapview(df_map) +
  (sf_nc_county)


