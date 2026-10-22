#' Organize RivTimeFish data

pacman::p_load(tidyverse,
               sf,
               terra,
               wrapbox,
               mapview)

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


# watershed delineation ---------------------------------------------------


