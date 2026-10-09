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

# figure out how many matching sites between 2004-2006 and 2014-2016
df_2004 <- df_f |>
  select(c(waterbody,year)) |> 
  filter(year %in% c(2004,2005,2006))

table(df_2004$waterbody)

df_2014 <- df_f |>
  select(c(waterbody,year)) |> 
  filter(year %in% c(2014,2015,2016))

table(df_2014$waterbody)

# Extract unique values from each column
val1 <- unique(df_2004$waterbody)
val2 <- unique(df_2014$waterbody)

# Values in df1$ID that are NOT in df2$ID
only_in_2004 <- setdiff(val1, val2)

# Values present in both columns
shared_vals <- intersect(val1, val2)
length(shared_vals)
