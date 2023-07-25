### Qualitative forecasts of mangrove extent change

This repository provides code for reproducing results and figures in Buelow et al. (*in prep*), 'Forecasting mangrove futures under climate change'.

The codebase draws heavily from the excellent R package [{QPress}](https://github.com/SWotherspoon/QPress).

Link to documents describing all spatial data processing:

-   [Part 1 here](https://mangrove-climate-risk-mapping.netlify.app/)
-   [Part 2 here](https://mangrove-climate-risk-mapping-2.netlify.app/)

##### TODO

-   [ ] If going to exclude areas with loss from commodities and erosion, update drivers data with CB estimates

#### Scripts

1.  01_wrangle-dat.R: wrangles processed data into a master dataframe

2.  02_model-scenarios.R: a script to simulate scenarios and plot probability of predicted outcomes

3.  03_plot-scenarios.R: plot the scenario results

4.  04_spatial-model-hindcast-validation.R: make spatial hindcasts, calibrate and cross-validate

5.  05_spatial-model-forecast.R: make calibrated forecasts

6.  06_map-spatial.R: map the hindcasts and forecasts

7.  07_plot-sensitivity.R: plot sensitivity analyses

8.  helpers/models.R: a script that builds different models

9.  helpers/helpers.R: a script with helper functions for simulating models

10. helpers/spatial-helpers.R: a script with helper functions for simulating models spatially

