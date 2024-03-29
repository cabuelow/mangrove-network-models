library(tidyverse)
library(scales)
library(patchwork)
library(ggh4x)
source('scripts/helpers/models.R')

# plot scenario outcomes

dat <- readRDS('outputs/simulation-outcomes/outcomes.rds')

# calculate proportion of stable model outcomes that have a positive, negative, or neutral landward/seaward mangrove response

dat2 <- dat %>% 
  filter(model == 'mangrove_model') %>% 
  filter(var %in% c('SeawardMang', 'LandwardMang') & 
           constraint_scenario %in% c('Macrotidal, High propagule establishment capacity, High coastal squeeze',
                                      'Microtidal, High propagule establishment capacity, High coastal squeeze',
                                      'Macrotidal, High propagule establishment capacity, Low coastal squeeze',
                                      'Microtidal, High propagule establishment capacity, Low coastal squeeze')) %>% #& 
  group_by(model_scenario, constraint_scenario, pressure, var) %>% 
  summarise(Prob_gain_neutral = ((sum(outcome>0) + sum(outcome==0))/n())*100,
            Prob_loss = (sum(outcome<0)/n())*-100) %>%  
  mutate(tide = strsplit(constraint_scenario, ', ')[[1]][1],
         coastalsqueeze = strsplit(constraint_scenario, ', ')[[1]][3],
         var = recode(var, 'LandwardMang' = 'Landward mangrove', 'SeawardMang' = 'Seaward mangrove'),
         tide = recode(tide, 'Microtidal' = 'Micro- tidal', 'Mesotidal' = 'Meso- tidal', 'Macrotidal' = 'Macro- tidal')) %>% 
  mutate(tide = factor(tide, levels = c('Micro- tidal', 'Meso- tidal', 'Macro- tidal')),
         pressure = ifelse(pressure == 'Sea-level rise & Coastal development', paste0(pressure, ' (', coastalsqueeze, ')'), pressure),
         pressure = ifelse(pressure == 'Sea-level rise & Intense storms & Coastal development', paste0(pressure, ' (', coastalsqueeze, ')'), pressure),
         pressure = ifelse(pressure == 'Sea-level rise & Groundwater extraction', 'Sea-level rise & Subsidence (Groundwater extraction)', pressure),
         pressure = ifelse(pressure == 'Groundwater extraction', 'Subsidence (Groundwater extraction)', pressure)) %>% 
  mutate(pressure = factor(pressure, levels = c('Sea-level rise & Coastal development (High coastal squeeze)',
                                                'Sea-level rise & Coastal development (Low coastal squeeze)',
                                                'Sea-level rise & Intense storms & Coastal development (Low coastal squeeze)',
                                                'Sea-level rise & Intense storms & Coastal development (High coastal squeeze)',
                                                'Sea-level rise & Subsidence (Groundwater extraction)',
                                                'Sea-level rise & Intense storms',
                                                'Sea-level rise & Extreme rainfall',
                                                'Sea-level rise & Erosion',
                                                'Sea-level rise & Drought',
                                                'Sea-level rise',
                                                'Coastal development',
                                                'Subsidence (Groundwater extraction)',
                                                'Intense storms',
                                                'Extreme rainfall',
                                                'Erosion',
                                                'Drought'))) %>% 
  filter(!pressure %in% c('Sea-level rise & Intense storms & Coastal development (Low coastal squeeze)',
                                                'Sea-level rise & Intense storms & Coastal development (High coastal squeeze)'))

# plot

a <- ggplot(filter(dat2, var == 'Seaward mangrove'), 
            aes(tide, pressure, fill = Prob_gain_neutral)) +
  geom_tile(color = 'black') +
  scale_fill_distiller(palette = 'Spectral', 
                       name = 'Probability of Loss (red) or Gain/Stability (blue)',
                       direction = 1,
                       breaks = c(0, 25, 50, 75, 100),
                       limit = c(0, 100),
                       labels = c("-100", "-75", "50", '75', '100')) +
  facet_nested(~factor(model_scenario)) +
  #facet_nested(~factor(model_scenario) + factor(coastalsqueeze)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  theme_classic() +
  theme(legend.position = 'bottom',
        legend.justification = 'left',
        strip.text.x = element_text(size = 9),
        title = element_text(size = 8),
        axis.title = element_blank()) +
  ggtitle('A) Seaward mangrove') +
  guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5))

b <- ggplot(filter(dat2, var == 'Landward mangrove' & model_scenario == 'High Sediment Supply'), 
            aes(tide, pressure, fill = Prob_gain_neutral)) +
  geom_tile(color = 'black') +
  scale_fill_distiller(palette = 'Spectral', 
                       name = 'Probability of Loss (red) or Gain/Stability (blue)', 
                       direction = 1,
                       breaks = c(0, 25, 50, 75, 100),
                       limit = c(0, 100),
                       labels = c("-100", "-75", "50", '75', '100')
                       ) +
  #facet_wrap(~factor(coastalsqueeze)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  theme_classic() +
  theme(legend.position = 'none',
        legend.justification = 'left',
        axis.text.y =  element_blank(),
        strip.text.x = element_text(size = 9),
        title = element_text(size = 8),
        axis.title = element_blank()) +
  ggtitle('B) Landward mangrove') +
  guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5))
b

c <- a+b+plot_layout(widths = c(2, 1))
c 
ggsave('outputs/heatmap_outputs/mangrove_model_heatmap.png', width = 8, height = 4)

