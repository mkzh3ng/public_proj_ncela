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

# watershed delineation ---------------------------------------------------
