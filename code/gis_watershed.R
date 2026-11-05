#' Organize RivTimeFish data

pacman::p_load(tidyverse,
               sf,
               terra,
               tidyterra,
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

## merge rasters

# set buffer for mask layer
sf_mask <- readRDS("data_fmt/sf_mask.rds") %>% 
  st_transform(crs = 4087) %>% # WGS 84 / World Equidistant Cylindrical
  st_buffer(dist = 10000) %>% 
  st_transform(crs = 4326)

# fnm <- list.files(path = "data_src",
#                   pattern = get_key(sf_mask[1, ]),
#                   full.names = TRUE)
# 
# spr_upa <- lapply(fnm[str_detect(fnm, "_upa")],
#                   FUN = rast) %>%
#   sprc() %>%
#   merge() %>%
#   crop(sf_mask[1, ])
# 
# ## visualize check
# ggplot() +
#   geom_sf(data = sf_mask[1, ],
#           fill = "red") +
#   geom_spatraster(data = spr_upa,
#                   alpha = 0.5)

list_upa <- lapply(X = 1:nrow(sf_mask),
                   function(i) {
                     fnm <- list.files(path = "data_src",
                                       pattern = get_key(sf_mask[i, ]),
                                       full.names = TRUE)
                     
                     spr_upa <- lapply(fnm[str_detect(fnm, "_upa")],
                                       FUN = rast) %>%
                       sprc() %>%
                       merge() %>%
                       crop(sf_mask[i, ])
                     
                     names(spr_upa) <- sf_mask$hybas_id[i]
                     
                     spr_upa
                   })

## visualize data check
ggplot() + 
  geom_spatraster(data = list_upa[[1]]) + 
  geom_spatraster(data = list_upa[[2]]) + 
  geom_spatraster(data = list_upa[[3]]) + 
  geom_spatraster(data = list_upa[[4]]) + 
  geom_sf(data = sf_mask,
          alpha = 0.5)

## create list_dir

## extract grid streams
# rs_upa <- rast("data_src/n30w080_upa.tif")
# rs_strg <- flow2grid(
#   f_acc = rs_upa, 
#   threshold = 1, 
#   output = "data_src/strg.tif"
# )

lapply(list_upa,
       function(x) {
         flow2grid(
           f_acc = x,
           threshold = 1,
           output = paste0("data_src/strg_", names(x), ".tif")
         )
       })

## from stream grid to stream vector
rs_dir <- rast("data_src/n30w080_dir.tif") %>% 
  arc2d8()

sf_str <- grid2stream(
  str_grid = rs_strg,
  f_dir = rs_dir,
  set_crs = TRUE
)

# combining raster files ------------------------------------------------

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

# watershed delineation ---------------------------------------------------
