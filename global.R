# global.R

## For (pre)data wrangling
library(haven)
library(dplyr)
## For shinyapp
library(flexdashboard)
library(tidyverse)
library(Hmisc)
library(lubridate) 
library(wordcloud) # maybe not needed
library(plotly)
library(survival) # maybe not needed
library(survminer) # maybe not needed
library(shiny)
# library(shinydashboard)

## EDIT THIS PATH! Set a location of prepared dataset imagefile
load(file="", verbose=T)

## This is needed for shiny app
minmax_age <- c(min(population$diagnosed_age_yrs), max(population$diagnosed_age_yrs))

## ICD categories
icd_categories <- c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "V", "Z", "U")

## disable scientific number formatting
options(scipen=999) 





