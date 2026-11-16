#' Organize RivTimeFish data

pacman::p_load(tidyverse,
               sf,
               terra,
               tidyterra,
               wrapbox,
               mapview)

## remotes::install_github("aterui/wrapbox@v0.2.1")
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

v_hybas <- sort(unique(sf_mask$hybas_id))

lapply(X = 1:nrow(sf_mask),
       function(i) {
         fnm <- list.files(path = "data_src",
                           pattern = get_key(sf_mask[i, ]),
                           full.names = TRUE)
         
         ## flow accumulation layer
         spr_upa <- lapply(fnm[str_detect(fnm, "_upa")],
                           FUN = rast) %>%
           sprc() %>%
           merge() %>%
           crop(sf_mask[i, ])
         
         names(spr_upa) <- sf_mask$hybas_id[i]
         
         ## flow direction layer
         spr_dir_arc <- lapply(fnm[str_detect(fnm, "_dir")],
                               FUN = rast) %>%
           sprc() %>%
           merge() %>%
           crop(sf_mask[i, ])
         
         ## convert arc-based flow dir to D8 flow dir
         spr_dir <- arc2d8(spr_dir_arc)
         
         names(spr_dir) <- sf_mask$hybas_id[i]
         
         ## return named list
         writeRaster(x = spr_upa, 
                     filename = paste0("data_src/spr_upa_", 
                                       sf_mask$hybas_id[i], 
                                       ".tif"),
                     overwrite = TRUE,
                     wopt = list(datatype = "FLT4S"))
         
         writeRaster(x = spr_dir, 
                     filename = paste0("data_src/spr_dir_", 
                                       sf_mask$hybas_id[i], 
                                       ".tif"),
                     overwrite = TRUE,
                     wopt = list(datatype = "INT4S"))
       })

## extract grid streams
list_strg <- lapply(X = v_hybas,
                    FUN = function(x) {
                      ## access flow accumulation layer
                      y <- rast(
                        paste0("data_src/spr_upa_", x, ".tif")
                      )
                      
                      ## convert from flow acc to stream grids
                      flow2grid(
                        f_acc = y,
                        threshold = 1,
                        output = paste0("data_src/spr_strg_", names(y), ".tif")
                      )
                    })

## covert stream grids to stream vectors
list_channel <- lapply(X = v_hybas,
                       FUN = function(x){
                         grid2stream(
                           str_grid = rast(paste0("data_src/spr_strg_", x, ".tif")),
                           f_dir = rast(paste0("data_src/spr_dir_", x, ".tif")),
                           set_crs = TRUE,
                         )
                       })

saveRDS(list_channel, "data_fmt/sf_channel.rds")

# watershed delineation ---------------------------------------------------
## use wrapbox::wsd_unnested() for watershed delineation

sf_hybas <- readRDS("data_fmt/sf_mask.rds")

sf_site_nc <- readRDS("data_fmt/sf_site_nc.rds") %>% 
  rename(site = time_series_id) %>% 
  st_join(sf_hybas)

lapply(X = v_hybas,
       FUN = function(x) {
         outlet_x <- sf_site_nc %>% 
           filter(hybas_id == x)
         
         dir_x <- rast(
           paste0("data_src/spr_dir_", x, ".tif")
         )
         
         strg_x <- rast(
           paste0("data_src/spr_strg_", x, ".tif")
         )
         
         sf_wsd_x <- wsd_unnested(
           outlet = outlet_x,
           id_col = "site",
           f_dir = dir_x,
           str_grid = strg_x, 
           snap = TRUE, 
           snap_dist = 5
         )
         
         saveRDS(
           sf_wsd_x, 
           file = paste0("data_fmt/sf_wsd_", x, ".rds")
         )
       })

## read and combine
sf_wsd <- list.files(
  "data_fmt", 
  pattern = "sf_wsd_\\d*\\.rds",
  full.names = TRUE
) %>% 
  lapply(FUN = readRDS) %>% 
  bind_rows()

mapview(sf_wsd, map.types = "OpenStreetMap")
