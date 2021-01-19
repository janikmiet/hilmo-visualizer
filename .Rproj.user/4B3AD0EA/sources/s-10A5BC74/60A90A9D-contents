## README

This Shiny-app visualises common Hilmo datasets. It is made for researchers to visualize patients timeline data. Most common application is to visualize persons with certain diagnose (ex. Alzheimer) and to see what has happened before and after the diagnose. Required input datasets are commented down below.

## How to use this program?

First you need to prepare your datasets if not already. Use R scripts `prepare_data.R` for that. Got thru the script finding `!PREPARE:`-section (use find function) and edit the script file. Set input data folder path and dataset names. Make sure that you also write the variable names. Script will wrangle a new dataset for you to new location.

Set path for this new datasets image file in `global.R` script and you're ready to go. Run the Shiny-app by command:

```
source("run.R")
```

## Input dataset definitions

You can use your own datasets, but you need to reshape them for equivalent as here described. Script `prepare_data.R` does this for you.


### Population

Needed variables:

```
id              # Id number
birthday_date   # Date of birth
diagnosed_date  # Date when person got diagnosed
gender_factor   # Gender in factor var
died_date       # Date of person died
censoring_date  # Date when follow up study ended
area_SHP_code   # Hospital area Code
```

Output dataset created with variables:

```
id
gender
birthday
died
area_SHP
diagnosed
diagnosed_age
diagnosed_age_yrs
diagnosed_yr
survived
survived_yrs
survived_yrs_cat
censored
```

### Hilmo (Doctoral visits)

Needed variables

```
id
date ()
diagnose (main)
diagnose (main)
diagnose (side)
diagnose (side)
diagnose (side)
```

### Medicines 

Needed variables

```
id
date ()
atc_code
```


### Timeline


## Notes

This application can be a bit slow, because of it can use for big datasets and it wrangles them on the fly. Be patient, thanks!


