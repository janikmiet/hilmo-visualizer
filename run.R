#run.R

## First specify the packages of interest
packages = c("tidyverse", "flexdashboard",
             "Hmisc", "lubridate", "wordcloud", "plotly", "survival", "survminer", "haven", "shiny", "")
## Now load or install&load all
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)
package.check

## Run application
rmarkdown::run("shinyapp.Rmd")