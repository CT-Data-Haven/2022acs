# reads utils/reg_puma_list.rds
# writes fetch_data/acs_basic_yr_fetch_all.rds
source("utils/pkgs_utils.R")
######################################## LOOKUPS ###############################----
# include pumas that aren't counties, all tracts, neighborhoods, us, msas
# nhood profiles have state, region, cities, neighborhoods
nhood_lookup <- tibble::lst(bridgeport_tracts, hartford_tracts, new_haven_tracts, stamford_tracts) %>%
  rlang::set_names(stringr::str_remove, "_tracts") %>%
  bind_rows(.id = "city") %>%
  mutate(city = camiller::clean_titles(city, cap_all = TRUE)) %>%
  tidyr::unite(name, city, name) %>%
  select(name, geoid_cog, weight)

# no longer need PUMAs as regions--cwi can call them
# also keep out COGs
reg_puma_list <- readRDS("utils/reg_puma_list.rds")
pumas <- names(reg_puma_list[grepl("^\\d+$", names(reg_puma_list))])  
regions <- reg_puma_list[!names(reg_puma_list) %in% pumas & !grepl("COG", names(reg_puma_list))]

######################################## FETCH #################################----
# drop medians for aggregated regions
fetch <- purrr::map(basic_table_nums, multi_geo_acs, year = yr, survey = "acs5",
           towns = "all", 
           regions = regions,
           pumas = pumas,
           neighborhoods = nhood_lookup,
           nhood_geoid = "geoid_cog",
           tracts = "all",
           us = TRUE,
           sleep = 1) %>%
  purrr::modify_at("median_income", mutate, 
                   across(estimate:moe, ~if_else(grepl("(region|neighborhood)", level), NA_real_, .)))

######################################## OUTPUT ###############################----

saveRDS(fetch, file.path("fetch_data", stringr::str_glue("acs_basic_{yr}_fetch_all.rds")))
