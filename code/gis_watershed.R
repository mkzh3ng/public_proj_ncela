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

list_raster <- lapply(X = 1:nrow(sf_mask),
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
                        list(upa = spr_upa, dir = spr_dir)
                      })

## extract grid streams
list_strg <- lapply(X = list_raster,
                    function(x) {
                      ## access flow accumulation layer
                      y <- x$upa
                      
                      ## convert from flow acc to stream grids
                      flow2grid(
                        f_acc = y,
                        threshold = 1,
                        output = paste0("data_src/strg_", names(y), ".tif")
                      )
                    })

## covert stream grids to stream vectors
list_channel <- lapply(X = seq_len(length(list_raster)),
                       function(i){
                         grid2stream(
                           str_grid = list_strg[[i]],
                           f_dir = list_raster[[i]]$dir,
                           set_crs = TRUE,
                         )
                       })

saveRDS(list_channel, "data_fmt/sf_channel.rds")

# watershed delineation ---------------------------------------------------

sf_site_nc <- readRDS("data_fmt/sf_site_nc.rds") %>% 
  rename(site = time_series_id)

## use wrapbox::wsd_unnested() for watershed delineation

