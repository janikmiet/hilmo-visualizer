## Create datasets for the application

library(haven)
library(tidyverse)
library(lubridate)
library(dplyr)   


## Define input datasets -----------------------

## !PREPARE: Input data folder location (can be also netword drive)
input_data_location <- "" ### SET DATA FOLDER LOCATION!
# list.files(input_data_location)

## !PREPARE: Population input data
input_population <- read_sas(paste0(input_data_location, "")) ## SET INPUT DATA NAME!
input_population$SP <- factor(input_population$SP, labels=c("Male", "Female"))

## !PREPARE: SET THESE DATASET NAME AND VARIABLE NAMES!!!
## For Hilmo dataset
hilmo <- read_sas(paste0(input_data_location, ""))

## !PREPARE: CHECK IF YOU NEED TO DO THIS WRANGLING!!
## Dates, check if you need to do date wrangling!!
hilmo$tulopv <- as.Date(hilmo$tulopv, origin = "1960-01-01")
hilmo$lahtopv <- as.Date(hilmo$lahtopv, origin = "1960-01-01")
hilmo$toimpv <- as.Date(hilmo$toimpv, origin = "1960-01-01")



## Part  1: population dataset -----
source("functions/create_population.R")
population <- create_population(data = input_population)

## Part 2: Create hilmo dataset ----
hilmo %>% 
  filter(pdgo != "") %>% 
  filter(idnum %in% population$id) %>%  # This because of there some id rows in Hilmo which are not in pop. # hilmo_agg1[is.na(as.integer(hilmo_agg1$tulo_diag)),]
  select(idnum, pdgo, pdge, sdg1o, sdg1e, sdg2o, sdg2e, tulopv, lahtopv) %>% 
  rename(id=idnum) %>% 
  left_join(population %>% select(id, diagnosed)) %>% 
  mutate(
    # Scaled enter and leave dates
    tulo_scaled = as.integer(tulopv - diagnosed),
    lahto_scaled = as.integer(lahtopv - diagnosed),
    days = as.integer(lahto_scaled - tulo_scaled + 1),
    # Scaled enter and leave years
    tulo_yr = round(tulo_scaled / 365, 2), 
    laht_yr = round(lahto_scaled / 365, 2),
    # diagnoses with 3 digits accurance
    pdgo = substr(pdgo,1,3),
    pdge = substr(pdge,1,3),
    sdg1o = substr(sdg1o,1,3),
    sdg1e = substr(sdg1e,1,3),
    sdg2o = substr(sdg2o,1,3),
    sdg2e = substr(sdg2e,1,3)
  ) -> hilmo_diags

#### Main diagnoses
hilmo_diags %>% 
  pivot_longer(cols = c("pdgo", "pdge"), names_to = "source", values_to = "main") %>% 
  filter(main != "") %>% 
  select(id, source, main, tulo_scaled, lahto_scaled, days, tulo_yr, laht_yr, tulopv) %>% 
  filter(!duplicated(.)) %>% 
  mutate(ICD = substr(main, 1, 1)) -> hilmo_maindiags

#### Side diagnoses
hilmo_diags %>% 
  pivot_longer(cols = c("sdg1o", "sdg1e", "sdg2o", "sdg2e"), names_to = "source", values_to = "side") %>%
  filter(side != "") %>% 
  select(id, source, side, tulo_scaled, lahto_scaled, days, tulo_yr, laht_yr, tulopv) %>% 
  filter(!duplicated(.)) %>% 
  mutate(ICD = substr(side, 1, 1)) -> hilmo_sidediags


## Part 3: Save dataset -----

# Remove temp vars
rm(list = c("input_population", "hilmo", "hilmo_timeline", "hilmo_tl", "i"))
# Save datasets
save.image(file=paste0(input_data_location, "hilmo-visualiser\\hilmo_datasets.RData"))
