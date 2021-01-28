# global.R

## For (pre)data wrangling
library(haven)
library(dplyr)
## For shinyapp
library(flexdashboard)
library(hrbrthemes)
library(tidyverse)
library(Hmisc)
library(lubridate) 
library(wordcloud) # maybe not needed
library(plotly)
library(survival) # maybe not needed
library(survminer) # maybe not needed

## EDIT THIS PATH! Set a location of prepared dataset imagefile
load(file="", verbose=T)

## disable scientific number formatting
options(scipen=999) 



