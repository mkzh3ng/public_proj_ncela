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
# extract grid streams
# vectorize
#
# functions:
# - flow2grid (flow accumulation layer)
# - grid2stream (flow accumulation + direction)
# - arc2d8 (convert flow direction from arc format to D8)

setwd("~/GitHub/public_proj_ncela/data_src")

n30w80rastflow <- raster("n30w080_upa.tif", crs = '+init=EPSG:4326')
n30w80rastdir <- raster("n30w080_dir.tif", crs = '+init=EPSG:4326')

n30w80flow <- flow2grid(n30w80rastflow, 1, "n30w080_upa.tif")
n30w80flow_d8 <- arc2d8(n30w80flow)


n30w80dir<- grid2stream(n30w80rastdir,n30w80flow_d8,
                        output = NULL, set_crs = TRUE)

# watershed delineation ---------------------------------------------------
