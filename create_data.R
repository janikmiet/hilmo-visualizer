## Load population and create hilmo datasets
## Save file

library(haven)
library(tidyverse)
library(lubridate)
library(dplyr)   


## Define input datasets -----------------------

## !PREPARE: Input data folder location (can be also netword drive)
input_data_location <- "\\\\uefad.uef.fi\\DATA\\LOCALSITES\\SITES\\MEDALZ_analyysitila_374\\" ### SET DATA FOLDER LOCATION!
# list.files(input_data_location)

## !PREPARE: Population input data
input_population <- read_sas(paste0(input_data_location, "\\COMMON_shared_data\\MEDALZcohort\\kela_alzh_tapver_correct7.sas7bdat")) ## SET INPUT DATA NAME!
input_population$SP <- factor(input_population$SP, labels=c("Male", "Female"))


source("functions/create_population.R")
population <- create_population(data = input_population,
                                variables = list(id = "idnum",                        # Id number
                                                 birthday_date = "SYNTPV",               # Date of birth
                                                 died_date = "kuolpv",                   # Date of person died
                                                 diagnosed_date = "erko307_pv",          # Date when person got diagnosed
                                                 gender_factor = "SP",                   # Gender in factor var
                                                 censoring_date = as.Date("2015-12-31"), # Single date value when follow up study ended
                                                 area_SHP_code = "SHP" ) # Optional, not used yet.
                                )


## !PREPARE: SET THESE DATASET NAME AND VARIABLE NAMES!!!
## For Hilmo dataset
hilmo <- read_sas(paste0(input_data_location, "COMMON_shared_data\\Hilmo\\hilmo9415purettu.sas7bdat"))

## !PREPARE: CHECK IF YOU NEED TO DO THIS WRANGLING!!
## Dates, check if you need to do date wrangling!!
hilmo$tulopv <- as.Date(hilmo$tulopv, origin = "1960-01-01")
hilmo$lahtopv <- as.Date(hilmo$lahtopv, origin = "1960-01-01")
hilmo$toimpv <- as.Date(hilmo$toimpv, origin = "1960-01-01")

source("functions/create_diagnose_data.R")
create_diagnose_data(data = hilmo, 
                     population_data = population,
                     variables = list(id = "idnum", 
                                      main_diagnoses = c("pdgo", "pdge"),
                                      side_diagnoses = c("sdg1o", "sdg1e", "sdg2o", "sdg2e"),
                                      enter_date = "tulopv", 
                                      left_date = "lahtopv")
                     )



# Remove temp vars
rm(list = c("input_population", "hilmo", "create_diagnose_data", "create_population"))
# Save datasets
save.image(file=paste0(input_data_location, "hilmo-visualiser\\hilmo_datasets.RData"))

