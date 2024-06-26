### Probabilistic forecasts of the direction of future change in mangrove extent using network models

This repository provides code for reproducing results and figures in Buelow et al. (*in prep*), 'Forecasting uncertainties in ecosystem persistence under climate change'.

The codebase draws heavily from the R package [{QPress}](https://github.com/SWotherspoon/QPress).

Links to webpages where you can interactively view all spatial data underpinning the analysis and read the steps taken to process the spatial data are here:

-   [Part 1 here](https://mangrove-climate-risk-mapping.netlify.app/)
-   [Part 2 here](https://mangrove-climate-risk-mapping-2.netlify.app/)

[Graphical analyis workflow](#graphical-analysis-workflow) | [System requirements](#system-requirements) | [Installation guide](#installation-guide) | [Demo and instructions for use](#demo-and-instructions-for-use) | [Scripts](#scripts)

#### Graphical analysis workflow

![](images/workflow.png)

#### System requirements

The code was written and tested in R version 4.2.2.

#### Installation guide

Install the following packages to run the code and reproduce results.

`install.packages(c('tidyverse', 'doParallel', 'foreach', 'ggh4x', 'patchwork', 'sf', 'tmap', 'caret'))`

`devtools::install_github("SWotherspoon/QPress",ref="Constrain")`

#### Instructions for use

1. Download or clone the github repo and double click the `mangrove-network-models.Rproj` file to open RStudio.  

2. The master data frame and spatial data required to reproduce manuscript figures and results is provided in the 'data' folder of the repository (see wrangling steps to produce the master dataframe in script `01_wrangle-dat.R`).

3. To run the analysis, start with script `02_model-scenarios.R` and run the rest in sequential order.

4. The cross-validation uses uses 5 cores for parallel processing.

#### Scripts

1.  01_wrangle-dat.R: wrangles processed data into a master dataframe

2.  02_model-scenarios.R: a script to simulate scenarios and plot probability of predicted outcomes

3.  03_plot-scenarios.R: plot the scenario results

4.  04_spatial-model-hindcast-validation.R: fit and cross-validate spatial hindcasts

5.  05_spatial-model-hindcast-uncertainty.R: quantify uncertainty in cross-validation accuracy estimators

6.  06_map-hindcast-validation.R: map the hindcasts

7.  07_spatial-model-forecast.R: make forecasts and map

8.  08_spatial-model-forecast-uncertainty.R: quantify 95% confidence intervals around forecast classes

9.  09_plot-sensitivity.R: plot sensitivity analyses

10. helpers/models.R: a script that builds different models

11. helpers/helpers.R: a script with helper functions for simulating models

12. helpers/spatial-helpers.R: a script with helper functions for simulating models spatially

13. misc-plotting.R: miscellaneous plotting and mapping
