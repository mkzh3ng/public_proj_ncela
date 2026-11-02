#' Organize RivTimeFish data

pacman::p_load(tidyverse,
               sf,
               terra,
               wrapbox,
               mapview)

## whitebox::install_whitebox()

rm(list = ls())


# stream network delineation ----------------------------------------------
# data:
# flow accumulation layer (postfix, _upa)
# flow direction (postfix, _dir)
#
# steps:
# - merge raster layers
# - extract grid streams
# - vectorize
#
# functions:
# - flow2grid (flow accumulation layer)
# - grid2stream (flow accumulation + direction)
# - arc2d8 (convert flow direction from arc format to D8)

## extract grid streams
rs_upa <- rast("data_src/n30w080_upa.tif")
rs_strg <- flow2grid(
  f_acc = rs_upa, 
  threshold = 1, 
  output = "data_src/strg.tif"
)

## from stream grid to stream vector
rs_dir <- rast("data_src/n30w080_dir.tif") %>% 
  arc2d8()

sf_str <- grid2stream(
  str_grid = rs_strg,
  f_dir = rs_dir,
  set_crs = TRUE
)

# combining raster files --------------------------------------------------
## .upa files 
rs_n30w080 <- rs_upa
rs_n30w085 <- rast("data_src/n30w085_upa.tif")
rs_n35w080 <- rast("data_src/n35w080_upa.tif")
rs_n35w085 <- rast("data_src/n35w085_upa.tif")

rs_flow_acc <- merge(rs_n30w080,rs_n30w085,rs_n35w080,rs_n35w085)

rs_nc_strg <- flow2grid(
  f_acc = rs_flow_acc, 
  threshold = 1, 
  output = "data_src/nc_flow_strg.tif"
)

## .dir files
rs_dir_n30w080 <- rs_dir
rs_dir_n30w085 <- rast("data_src/n30w085_dir.tif")
rs_dir_n35w080 <- rast("data_src/n35w080_dir.tif")
rs_dir_n35w085 <- rast("data_src/n35w085_dir.tif")

rs_nc_dir <- merge(rs_dir_n30w080,
                   rs_dir_n30w085,
                   rs_dir_n35w080,
                   rs_dir_n35w085) %>% 
  arc2d8()

sf_nc_str <- grid2stream(
  str_grid = rs_nc_strg,
  f_dir = rs_nc_dir,
  set_crs = TRUE
)

## replace sf_site with polygon object (sf_hybas)
sf_hybas <- st_read("data_src/hybas_na_lev04_v1c.shp")

df_hybas <- st_coordinates(sf_hybas) %>% 
  as_tibble() 

sf_hybas_coord <- st_as_sf(df_hybas, coords = c("X", "Y"), crs = 4326)

sf_hybas_site <- sf_site %>% 
  st_join(sf_hybas_coord,
            by = "geometry", left = TRUE)

key <- wrapbox::get_key()

# watershed delineation ---------------------------------------------------
