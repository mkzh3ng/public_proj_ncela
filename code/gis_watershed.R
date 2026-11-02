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
sf_mask <- readRDS("data_fmt/sf_mask.rds")

fnm <- list.files(path = "data_src",
                  pattern = get_key(sf_mask[1, ]),
                  full.names = TRUE)

spr_upa <- lapply(fnm[str_detect(fnm, "_upa")],
                  FUN = rast) %>% 
  sprc() %>% 
  merge() %>% 
  crop(sf_mask[1, ])

# list_upa <- lapply(X = 1:nrow(sf_mask),
#                    function(i) {
#                      fnm <- list.files(path = "data_src",
#                                        pattern = get_key(sf_mask[i, ]),
#                                        full.names = TRUE)
#                      
#                      spr_upa <- lapply(fnm[str_detect(fnm, "_upa")],
#                                        FUN = rast) %>%
#                        sprc() %>%
#                        merge() %>%
#                        crop(sf_mask[i, ])
#                      
#                      names(spr_upa) <- sf_mask$hybas_id[i]
#                      
#                      spr_upa
#                    })

## create list_dir

## extract grid streams
rs_upa <- rast("data_src/n30w080_upa.tif")
rs_strg <- flow2grid(
  f_acc = rs_upa, 
  threshold = 1, 
  output = "data_src/strg.tif"
)

# lapply(list_spr,
#        function(x) {
#          
#          flow2grid(
#            f_acc = x,
#            threshold = 1,
#            output = paste0("data_src/strg_", names(x), ".tif")
#          )
#        })

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
