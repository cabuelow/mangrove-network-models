# take spatial data processed to mangrove typological units
# convert to presence-absence for climate risk model
# and combine into master dataframe

library(tidyverse)
library(sf)
library(tmap)
tmap_mode('view')

typ <- st_read('data/typologies/Mangrove_Typology_v3.14_Composite_valid_centroids.gpkg')
typ_area <- read.csv('data/processed-data/typology-area.csv')
dat <- list() # list to store wrangled dat

# do pressure classifications across a range of thresholds
sens <- c(30, 40, 50, 60, 70) #percentiles
sens_sub <- c(2, 3, 4, 5, 6) #subsidence probability intervals

# loop through pressure classifications and save in master dataframe
tmp <- list()
for(i in seq_along(sens)){
  
#### coastal squeeze

coast <- read.csv('data/processed-data/coastal-population.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  select(-sum.pop_size_lecz_2020) %>% 
  mutate_at(vars(sum.pop_size_lecz_2000:sum.pop_size_lecz_2100), ~./area_ha) %>% # divide by lecz area to get population density
  mutate(sum.pop_size_lecz_2000 = ifelse(area_ha == 0, max(.$sum.pop_size_lecz_2000, na.rm = T), sum.pop_size_lecz_2000),# assign max pop. density to units with 0 lecz area (indicates no space for mangroves to grow)
         sum.pop_size_lecz_2040 = ifelse(area_ha == 0, max(.$sum.pop_size_lecz_2040, na.rm = T), sum.pop_size_lecz_2040),
         sum.pop_size_lecz_2060 = ifelse(area_ha == 0, max(.$sum.pop_size_lecz_2060, na.rm = T), sum.pop_size_lecz_2060),
         sum.pop_size_lecz_2100 = ifelse(area_ha == 0, max(.$sum.pop_size_lecz_2100, na.rm = T), sum.pop_size_lecz_2100)) %>% 
  mutate(csqueeze = ifelse(log(sum.pop_size_lecz_2000) > quantile(log(.$sum.pop_size_lecz_2000[.$sum.pop_size_lecz_2000>0]), 0.66), 'High', NA)) %>% 
  mutate(csqueeze = ifelse(log(sum.pop_size_lecz_2000) < quantile(log(.$sum.pop_size_lecz_2000[.$sum.pop_size_lecz_2000>0]), 0.66) & log(sum.pop_size_lecz_2000) > quantile(log(.$sum.pop_size_lecz_2000[.$sum.pop_size_lecz_2000>0]), 0.33), 'Medium', csqueeze)) %>% 
  mutate(csqueeze = ifelse(log(sum.pop_size_lecz_2000) < quantile(log(.$sum.pop_size_lecz_2000[.$sum.pop_size_lecz_2000>0]), 0.33), 'Low', csqueeze)) %>% 
  mutate(csqueeze = ifelse(sum.pop_size_lecz_2000 == 0, 'None', csqueeze)) %>% 
  mutate(fut_csqueeze = ifelse(log(sum.pop_size_lecz_2060) > quantile(log(.$sum.pop_size_lecz_2060[.$sum.pop_size_lecz_2060>0]), 0.66), 'High', NA)) %>% 
  mutate(fut_csqueeze = ifelse(log(sum.pop_size_lecz_2060) < quantile(log(.$sum.pop_size_lecz_2060[.$sum.pop_size_lecz_2060>0]), 0.66) & log(sum.pop_size_lecz_2060) > quantile(log(.$sum.pop_size_lecz_2060[.$sum.pop_size_lecz_2060>0]), 0.33), 'Medium', fut_csqueeze)) %>% 
  mutate(fut_csqueeze = ifelse(log(sum.pop_size_lecz_2060) < quantile(log(.$sum.pop_size_lecz_2060[.$sum.pop_size_lecz_2060>0]), 0.33), 'Low', fut_csqueeze)) %>% 
  mutate(fut_csqueeze = ifelse(sum.pop_size_lecz_2060 == 0, 'None', fut_csqueeze)) %>% 
  select(Type, csqueeze, fut_csqueeze) %>% 
  mutate(fut_barriers = ifelse(csqueeze == 'Low' & fut_csqueeze == 'None', 'Low', fut_csqueeze), # here assuming that any coastal development in the past can't be reversed
         fut_barriers = ifelse(csqueeze == 'Medium' & fut_csqueeze == 'None', 'Medium', fut_barriers),
         fut_barriers = ifelse(csqueeze == 'High' & fut_csqueeze == 'None', 'High', fut_barriers),
         fut_barriers = ifelse(csqueeze == 'Medium' & fut_csqueeze == 'Low', 'Medium', fut_barriers),
         fut_barriers = ifelse(csqueeze == 'High' & fut_csqueeze == 'Low', 'High', fut_barriers),
         fut_barriers = ifelse(csqueeze == 'High' & fut_csqueeze == 'Medium', 'High', fut_barriers))

# map to check

typ2 <- typ %>% 
  left_join(coast)
qtm(typ2, dots.col = 'csqueeze') 
qtm(typ2, dots.col = 'fut_csqueeze')
qtm(typ2, dots.col = 'fut_barriers')
dat[[1]] <- coast # if happy add to dat list

#### sediment supply

sed <- read.csv('data/processed-data/free-flowing-rivers.csv') %>%
  filter(Type %in% typ$Type) %>% 
  left_join(select(st_drop_geometry(typ), Type, Class), by = 'Type') %>% 
  mutate(SED_weighted_average = ifelse(Class != 'Delta', 100, SED_weighted_average)) %>%
  mutate(sed_supp = ifelse(SED_weighted_average >= sens[i], 'Low', NA)) %>% 
  mutate(sed_supp = ifelse(SED_weighted_average < sens[i], 'High', sed_supp)) %>% 
  select(Type, sed_supp)
  
# map to check

typ2 <- typ %>% 
  left_join(sed)
qtm(typ2, dots.col = 'sed_supp')
dat[[2]] <- sed # if happy add to dat list

#### future dams

dams <- read.csv('data/processed-data/future-dams.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(fut_dams = factor(ifelse(number_future_dams >= 1, 1, 0))) %>%
  select(Type, fut_dams)

# map to check

typ2 <- typ %>% 
  left_join(dams)
qtm(typ2, dots.col = 'fut_dams')
dat[[3]] <- dams # if happy add to dat list

#### future sea level rise

fslr <- read.csv('data/processed-data/future-slr.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(fut_slr = ifelse(slr_m_2041_2060 > quantile(.$slr_m_2041_2060, sens[i]/100), 1, 0)) %>% 
  select(Type, fut_slr)
  
# map to check

typ2 <- typ %>% 
  left_join(fslr)
qtm(typ2, dots.col = 'fut_slr')
dat[[4]] <- fslr # if happy add to dat list

#### antecedent sea level rise

aslr <- read.csv('data/processed-data/antecedent-slr.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(ant_slr = ifelse(local_msl_trend > quantile(.$local_msl_trend, sens[i]/100), 1, 0)) %>% 
  select(Type, ant_slr)

# map to check

typ2 <- typ %>% 
  left_join(aslr)
qtm(typ2, dots.col = 'ant_slr')
dat[[5]] <- aslr # if happy add to dat list

#### future subsidence from groundwater extraction

fgw <- read.csv('data/processed-data/gw_subsid_2040.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(fut_gwsub = ifelse(mode >= sens_sub[i], 1, 0)) %>% 
  select(Type, fut_gwsub)

# map to check

typ2 <- typ %>% 
  left_join(fgw)
qtm(typ2, dots.col = 'fut_gwsub')
dat[[6]] <- fgw # if happy add to dat list

#### current subsidence from groundwater extraction

gw <- read.csv('data/processed-data/gw_subsid_2010.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(gwsub = ifelse(mode >= sens_sub[i], 1, 0)) %>% 
  select(Type, gwsub)

# map to check

typ2 <- typ %>% 
  left_join(gw)
qtm(typ2, dots.col = 'gwsub') 
dat[[7]] <- gw # if happy add to dat list

#### future drought

fdro <- read.csv('data/processed-data/future-stand-precip-index.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(fut_drought = ifelse(mean.spi_change_percent_2041_2060 < quantile(.$mean.spi_change_percent_2041_2060[.$mean.spi_change_percent_2041_2060 < 0] , 1-(sens[i]/100)), 1, 0)) %>% 
  select(Type, fut_drought)

# map to check

typ2 <- typ %>% 
  left_join(fdro)
qtm(typ2, dots.col = 'fut_drought') 
dat[[8]] <- fdro # if happy add to dat list

#### future extreme rainfall

frain <- read.csv('data/processed-data/future-stand-precip-index.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(fut_ext_rain = ifelse(mean.spi_change_percent_2041_2060 > quantile(.$mean.spi_change_percent_2041_2060[.$mean.spi_change_percent_2041_2060 > 0] , sens[i]/100), 1, 0)) %>% 
  select(Type, fut_ext_rain)

# map to check

typ2 <- typ %>% 
  left_join(frain)
qtm(typ2, dots.col = 'fut_ext_rain') 
dat[[9]] <- frain # if happy add to dat list

#### historical cyclones

cyc <- read.csv('data/processed-data/cyclone-tracks-wind_1996_2020.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(storms = ifelse(cyclone_tracks_1996_2020 > quantile(.$cyclone_tracks_1996_2020, sens[i]/100), 1, 0)) %>% 
  select(Type, storms)

# map to check

typ2 <- typ %>% 
  left_join(cyc)
qtm(typ2, dots.col = 'storms') 
dat[[10]] <- cyc # if happy add to dat list

#### historical drought

hdro <- read.csv('data/processed-data/historical-drought.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(hist_drought = ifelse(min_spei_1996_2020 < quantile(.$min_spei_1996_2020[.$min_spei_1996_2020 < 0], 1-(sens[i]/100)), 1, 0)) %>% 
  select(Type, hist_drought)

# map to check

typ2 <- typ %>% 
  left_join(hdro)
qtm(typ2, dots.col = 'hist_drought') 
dat[[11]] <- hdro # if happy add to dat list

#### historical extreme rainfall

hrain <- read.csv('data/processed-data/historical-drought.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  mutate(hist_ext_rain = ifelse(max_spei_1996_2020 > quantile(.$max_spei_1996_2020[.$max_spei_1996_2020 > 0], sens[i]/100), 1, 0)) %>% 
  select(Type, hist_ext_rain)

# map to check

typ2 <- typ %>% 
  left_join(hrain)
qtm(typ2, dots.col = 'hist_ext_rain') 
dat[[12]] <- hrain # if happy add to dat list

#### tidal range

tide <- read.csv('data/typologies/SLR_Data.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  select(Type, Tidal_Class)

# map to check

typ2 <- typ %>% 
  left_join(tide)
qtm(typ2, dots.col = 'Tidal_Class') 
dat[[13]] <- tide # if happy add to dat list

#### future cyclones

fils <- list.files('data/processed-data/', pattern = '10000yrs.csv', full.names = T)
fstorms <- lapply(fils, read.csv) %>% 
  lapply(select, Type, cyclone_occurrences_10000yrs) %>% 
  reduce(left_join, by = 'Type') %>% 
  pivot_longer(cols = cyclone_occurrences_10000yrs.x:cyclone_occurrences_10000yrs.y.y, names_to = 'model', values_to = 'cyclone_occurrences_10000yrs') %>% 
  group_by(Type) %>% 
  summarise(cyclone_occurrences_10000yrs = median(cyclone_occurrences_10000yrs)) %>% 
  mutate(fut_storms = 1 - (1 - (cyclone_occurrences_10000yrs/10000))^(2050-2023)) %>% 
  mutate(fut_storms = ifelse(fut_storms > quantile(.$fut_storms, sens[i]/100), 1, 0)) %>% 
  select(Type, fut_storms) %>% 
  filter(Type %in% typ$Type)

# map to check

typ2 <- typ %>% 
  left_join(fstorms)
qtm(typ2, dots.col = 'fut_storms') 
dat[[14]] <- fstorms # if happy add to dat list

#### propagule establishment distances

propest <- read.csv('data/processed-data/propagule-establishment-distances.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  left_join(typ_area) %>% 
  mutate(prop_establishment = ifelse(extant_loss_dist_mean_m == 'no_loss', NA, extant_loss_dist_mean_m)) %>% 
  mutate(prop_establishment = as.numeric(ifelse(prop_establishment == 'no_extant', NA, prop_establishment))) %>% 
  mutate(prop_establishment = prop_establishment/area_ha) %>% 
  mutate(prop_establishment = ifelse(is.na(prop_establishment), max(.$prop_establishment, na.rm = T), prop_establishment)) %>% 
  mutate(prop_estab = ifelse(prop_establishment > quantile(.$prop_establishment, 0.66), 'Low', NA),
         prop_estab = ifelse(prop_establishment < quantile(.$prop_establishment, 0.33), 'High', prop_estab),
         prop_estab = ifelse(is.na(prop_estab), 'Medium', prop_estab)) %>% 
  select(Type, prop_estab)
  

# map to check

typ2 <- typ %>% 
  left_join(propest)
qtm(typ2, dots.col = 'prop_estab') 
dat[[15]] <- propest # if happy add to dat list

#### landward vs. seaward loss

land <- read.csv('data/typologies/landward_change_96_20_gmw_v3.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  group_by(chng_type, Type) %>% 
  summarise(area_ha = sum(area_ha)) %>% 
  pivot_wider(names_from = 'chng_type', values_from = 'area_ha') %>% 
  mutate(gain = ifelse(is.na(gain), 0, gain),
         loss = ifelse(is.na(loss), 0, loss)) %>% 
  mutate(land_net_change_ha = gain - loss) %>% 
  select(Type, land_net_change_ha)
  
sea <- read.csv('data/typologies/seaward_change_96_20_gmw_v3.csv') %>% 
  filter(Type %in% typ$Type) %>% 
  group_by(chng_type, Type) %>% 
  summarise(area_ha = sum(area_ha)) %>% 
  pivot_wider(names_from = 'chng_type', values_from = 'area_ha') %>% 
  mutate(gain = ifelse(is.na(gain), 0, gain),
         loss = ifelse(is.na(loss), 0, loss)) %>% 
  mutate(sea_net_change_ha = gain - loss) %>% 
  select(Type, sea_net_change_ha)

# map to check

typ2 <- typ %>% 
  left_join(land) %>% 
  left_join(sea) %>% 
  mutate(sea_net_change = case_when(sea_net_change_ha >= 0 ~ 'Gain_neutrality',
                                    sea_net_change_ha < 0 ~ 'Loss',
                                    is.na(sea_net_change_ha) ~ 'Gain_neutrality'),
         land_net_change = case_when(land_net_change_ha >= 0 ~ 'Gain_neutrality',
                                    land_net_change_ha < 0 ~ 'Loss',  
                                    is.na(land_net_change_ha) ~ 'Gain_neutrality')) %>% 
  select(Type, sea_net_change:land_net_change)

qtm(typ2, dots.col = 'sea_net_change') 
qtm(typ2, dots.col = 'land_net_change') 
dat[[16]] <- st_drop_geometry(typ2) # if happy add to dat list

# arid vs. humid mangroves

arid <- read.csv('data/processed-data/aridity.csv') %>% 
  mutate(climate = ifelse(mean <= 0.5, 'arid', 'humid')) %>% 
  select(Type, climate)

# map to check

typ2 <- typ %>% 
  left_join(arid) 
qtm(typ2, dots.col = 'climate')
dat[[17]] <- arid

# merge into final master database

tmp[[i]] <- data.frame(pressure_def = i, Reduce(full_join, dat))

}
tempdat <- do.call(rbind, tmp)

mast.dat <- tempdat %>% 
  mutate(land_net_change_obs = ifelse(land_net_change == 'Gain_neutrality', 1, -1),
         sea_net_change_obs = ifelse(sea_net_change == 'Gain_neutrality', 1, -1)) %>% 
  mutate(csqueeze_1 = ifelse(csqueeze %in% 'None', 0, 1), # this is for coastal development pressure
         fut_csqueeze_1 = ifelse(fut_csqueeze %in% 'None', 0, 1), 
         cdev = csqueeze,
         fut_cdev = fut_csqueeze,
         csqueeze = recode(csqueeze, 'Medium' = 'M', 'High' = 'L', 'Low' = 'H', 'None' = 'H'), # note counterintuitive notation here
         fut_csqueeze = recode(fut_barriers, 'Medium' = 'M', 'High' = 'L', 'Low' = 'H', 'None' = 'H'), # note counterintuitive notation here
         sed_supp = recode(sed_supp, 'Medium' = 'M', 'Low' = 'L', 'High' = 'H'), 
         fut_dams = ifelse(fut_dams == 1, 'L', sed_supp), 
         prop_estab = recode(prop_estab, 'Medium' = 'M', 'High' = 'H', 'Low' = 'L'),
         Tidal_Class = recode(Tidal_Class, 'Micro' = 'H', 'Meso' = 'M', 'Macro' = 'L')) %>% 
  mutate(Geomorphology = sub("\\_.*", "", Type))

# save

write.csv(mast.dat, 'data/master-dat.csv', row.names = F)

# end here

