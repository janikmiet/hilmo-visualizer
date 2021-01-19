## Data set wrangler script
## Give datasets and this will produce RData dataset for dataviz application
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

## Load all ready prepared dataset image file
# load(file=paste0(nw,"hilmo-visualiser\\dataviz.RData"), verbose=T) 


## POPULATION wrangle -----

## !PREPARE:DEFINE THESE VARS!! 
id <- "idnum"                           # Id number
birthday_date <- "SYNTPV"               # Date of birth
diagnosed_date <- "erko307_pv"          # Date when person got diagnosed
gender_factor <- "SP"                   # Gender in factor var
died_date <- "kuolpv"                   # Date of person died
censoring_date <- as.Date("2015-12-31") # Date when follow up study ended
area_SHP_code <- "SHP"


### AUTOMATION

### Harmonize population dataset ###
population <- input_population %>% 
  mutate(diagnosed = get(diagnosed_date),
         diagnosed_age = as.numeric(get(diagnosed_date) - get(birthday_date)) / 365.25,
         diagnosed_age_yrs = as.numeric(round(diagnosed_age)),
         diagnosed_yr = year(get(diagnosed_date)),  #  or = format(erko307_pv,"%Y")  # year of diagnosis
         censored = factor(ifelse(is.na(get(died_date)), 1, 0)),
         birthday = get(birthday_date),
         died = get(died_date),
         survived = ifelse(censored == 1, censoring_date - diagnosed, died - diagnosed), #get(died_date) - diagnosed,
         id = get(id),
         gender = get(gender_factor),
         area_SHP = factor(get(area_SHP_code)), ### TODO CHECK IF OK IN FACTOR
         survived_yrs_cat = as.character(cut(as.integer(survived),
                                             breaks = c(-Inf, 180, 365, 730, 1095, Inf),
                                             labels = c("< half year", "0.5 - 1 year", "1-2 years", "2-3 years", "3+ years"))),
         survived_yrs_cat_censored = as.factor(ifelse(censored == 0, survived_yrs_cat, "Censored")), ## NOTE: if person is censored before he died, survived category is then "censored"
         survived_yrs_cat = as.factor(survived_yrs_cat) ## NOTE: if person was alive 2 years after diagnose and at the same time dataset is censored. Person survived 2yrs.
  ) %>% 
  select(id, gender, birthday, died, area_SHP, diagnosed, diagnosed_age, diagnosed_age_yrs, diagnosed_yr, survived, survived_yrs_cat, censored) 

### Data check and corrections ###
## RULE: If ID has diagnosed_day > died -> Recode diagnose day same as died day
# population <- population[population$survived >= 0, ] # REMOVE
population[population$survived < 0, "diagnosed"] <- population[population$survived < 0, "died"] # SAME AS DIED
population[population$survived < 0, "survived"] <- 0 # SAME AS DIED

## Min and max age
minmax_age <- c(min(population$diagnosed_age_yrs), max(population$diagnosed_age_yrs))


## HILMO Wrangle ----

## !PREPARE: SET THESE DATASET NAME AND VARIABLE NAMES!!!
## For Hilmo dataset
hilmo <- read_sas(paste0(input_data_location, ""))

## !PREPARE: CHECK IF YOU NEED TO DO THIS WRANGLING!!
## Dates, check if you need to do date wrangling!!
#as.Date(d$tulopv, origin = "1960-01-01") # im not sure if origin date 100% accurate.
hilmo$tulopv <- as.Date(hilmo$tulopv, origin = "1960-01-01")
hilmo$lahtopv <- as.Date(hilmo$lahtopv, origin = "1960-01-01")
hilmo$toimpv <- as.Date(hilmo$toimpv, origin = "1960-01-01")


## Creates this kind of dataset
# year, diagnose, hosp_visit, hosp_days, uniq_ids, ids
hilmo %>% 
  filter(pdgo != "") %>% 
  filter(idnum %in% population$id) %>%  # This because of there some id rows in Hilmo which are not in pop. # hilmo_agg1[is.na(as.integer(hilmo_agg1$tulo_diag)),]
  select(idnum, pdgo, pdge, sdg1o, sdg1e, sdg2o, sdg2e, tulopv, lahtopv) %>% 
  rename(id=idnum) %>% 
  left_join(population %>% select(id, diagnosed)) %>% 
  mutate(tulo_scaled = as.integer(tulopv - diagnosed),
         lahto_scaled = as.integer(lahtopv - diagnosed),
         days = as.integer(lahto_scaled - tulo_scaled + 1),
         tulo_yr = round(tulo_scaled / 365, 2), # allign with years
         laht_yr = round(lahto_scaled / 365, 2),
         pdgo = substr(pdgo,1,3), # 3 digits accurance
         pdge = substr(pdge,1,3),
         sdg1o = substr(sdg1o,1,3),
         sdg1e = substr(sdg1e,1,3),
         sdg2o = substr(sdg2o,1,3),
         sdg2e = substr(sdg2e,1,3),
         source = "hilmo"
  ) %>% 
  select(id, pdgo, pdge, sdg1o, sdg1e, sdg2o, sdg2e, tulo_scaled, lahto_scaled, days, tulo_yr, laht_yr, source,  tulopv) %>% 
  ## RULE: 20 years in timeline before diagnose
  filter(lahto_scaled > 20 * -365) -> hilmo_agg1

## REMOVE possible duplicates (tulopv included in dataset to make sure only duplicated events are erased)
hilmo_agg1 <- hilmo_agg1[!duplicated(hilmo_agg1), ]
hilmo_agg1$ICD <- substr(hilmo_agg1$pdgo, 1, 1)

## Hilmo timeline dataset ----
## 20 year of timeline of pdgo
## TODO add column (list) including id's which are then used in shiny app to filter right population
## TODO also add to shiny app percentage calculation correcting "the new pop"
# pop_n <- length(unique(population$id))
hilmo_tl <- NULL
for(i in seq(from = -20, to = 20, by = 1)){
  if(is.null(hilmo_tl)){
    hilmo_agg1 %>% 
      # filter( (laht_yr > i-1 & laht_yr <= i) | (tulo_yr < i & tulo_yr > i-1) ) %>% 
      filter( ( tulo_yr <= i + 0.5 & laht_yr > i - 0.5) ) %>% 
      group_by(ICD) %>% 
      summarise(
        time = i,
        patients = length(unique(id)) ,
        ## TODO calculate manually on compare if its correct formula
        hospital_days = sum(case_when(tulo_yr > (i - 0.5) & laht_yr <= (i + 0.5) ~ as.double(days),
                                      tulo_yr < (i - 0.5) & laht_yr >= (i + 0.5) ~ 365,
                                      tulo_yr < (i - 0.5) & laht_yr < (i + 0.5) & laht_yr > (i - 0.5) ~ abs((i - 0.5) * 365 - abs(lahto_scaled)),
                                      tulo_yr > (i - 0.5) & tulo_yr < (i + 0.5) & laht_yr > (i + 0.5) ~ abs(abs(tulo_scaled) - (i + 0.5) * 365) 
                                      
        ), na.rm = T)
        
      )   -> hilmo_tl
  }else{
    hilmo_tl <- hilmo_tl %>% 
      rbind(
        hilmo_agg1 %>% 
          filter( (laht_yr > i-1 & laht_yr <= i) | (tulo_yr < i & tulo_yr > i-1) ) %>% 
          group_by(ICD) %>% 
          summarise(
            time = i,
            patients = length(unique(id)) ,
            ## TODO calculate manually on compare if its correct formula
            hospital_days = sum(case_when(tulo_yr > (i - 0.5) & laht_yr <= (i + 0.5) ~ as.double(days),
                                          tulo_yr < (i - 0.5) & laht_yr >= (i + 0.5) ~ 365,
                                          tulo_yr < (i - 0.5) & laht_yr < (i + 0.5) & laht_yr > (i - 0.5) ~ abs((i - 0.5) * 365 - abs(lahto_scaled)),
                                          tulo_yr > (i - 0.5) & tulo_yr < (i + 0.5) & laht_yr > (i + 0.5) ~ abs(abs(tulo_scaled) - (i + 0.5) * 365) 
                                          
            ), na.rm = T)
            
          ) 
      )
  }
}
# hilmo_tl$ICDMAIN <- substr(hilmo_tl$pdgo, 1, 1)
# hospital_days = ifelse( (tulo_yr >= i & laht_yr <= i + 1),
#                         sum(days),
#                         ifelse(tulo_yr < i,
#                                (lahto_scaled - i * 365),
#                                ((i + 1) * 365 - tulo_scaled )) )


## Tarkastetaan
ggplot(data = hilmo_tl) +
  geom_bar(aes(x = time, y = patients, group = ICD, fill = ICD), stat= "identity")
ggplot(data = hilmo_tl) +
  geom_bar(aes(x = time, y = hospital_days, group = ICD, fill = ICD), stat= "identity")

# yrs <- seq(-3650, 3650, by = 365)

## Gather diagnose variable to one MAIN / SIDE

## Summarize by year and diagnose
## Gather information id, 

# ### Hilmo aggregated diagnose info ###
# hilmo %>% 
#   filter(pdgo != "") %>% 
#   mutate(diagnose = substr(pdgo, 1, 3)) %>% 
#   group_by(diagnose) %>% 
#   summarise(n=n(),
#             patients = length(unique(idnum))) -> hilmo_pdgo
# 
# hilmo %>% 
#   filter(pdge != "") %>% 
#   mutate(diagnose = substr(pdge, 1, 3)) %>% 
#   group_by(diagnose) %>% 
#   summarise(n=n(),
#             patients = length(unique(idnum))) -> hilmo_pdge



## Clean and save image -----

# Remove temp vars
rm(list = c("input_population", "id", "birthday_date", "diagnosed_date", "gender_factor", "died_date", "censoring_date", "area_SHP_code", "hilmo"))
# Save datasets
save.image(file=paste0(input_data_location, "hilmo-visualiser\\dataviz.RData"))
