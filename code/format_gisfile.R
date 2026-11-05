#' Organize RivTimeFish data

pacman::p_load(tidyverse,
               sf,
               mapview,
               wrapbox,

rm(list = ls())

# read data ---------------------------------------------------------------

## read mask layer
sf_hybas <- st_read("data_src/hybas_na_lev04_v1c.shp") %>% 
  janitor::clean_names() %>% 
  st_make_valid() %>% 
  dplyr::select(hybas_id)

## read data, janitor::clean_names() fix column names to snake case
df_ts <- read_csv("data_src/data_rtf_ts.csv") %>% 
  janitor::clean_names()

df_survey <- read_csv("data_src/data_rtf_survey.csv") %>% 
  janitor::clean_names()

## subset and join data
sf_site <- df_ts %>% 
  filter(region == "NORTH CAROLINA") %>% 
  left_join(df_survey) %>% 
  distinct(
    time_series_id,
    latitude,
    longitude) %>% 
  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326
  )

## find hybas polygons with sampling sites
sf_mask <- sf_site %>% 
  st_join(sf_hybas) %>% 
  pull(hybas_id) %>% 
  unique() %>% 
  { filter(sf_hybas, hybas_id %in% .) }

saveRDS(sf_mask, file = "data_fmt/sf_mask.rds")

key <- wrapbox::get_key(sf_mask)

## change file path depending on the computer you use
path0 <- here::here()
# path <- file.path("C:/Users/Mitch/OneDrive - UNCG/Akira Terui's files - gis")
# path <- file.path("C:/Users/a_terui/OneDrive - UNCG/Documents/shared_folder/gis")
path <- file.path("C:/Users/mitch/OneDrive - UNCG/Akira Terui's files - gis")

## set working directry where data is located
setwd(path)

list_r <- list.files(path,
                     pattern = key, full.names = TRUE) %>% 
  lapply(FUN = function(x) {
    rasterfile <- terra::rast(x)
  })

## go back to original directory
setwd(path0)

lapply(list_r,
       function(x) {
         fnm <- names(x)
         terra::writeRaster(
           x,
           filename = paste0("data_src/", fnm, ".tif"),
           overwrite = TRUE
         )
       })
