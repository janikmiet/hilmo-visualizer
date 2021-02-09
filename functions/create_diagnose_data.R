
create_diagnose_data <- function(data, 
                                 population_data = population,
                                 variables = list(id = "idnum", 
                                                  main_diagnoses = c("pdgo", "pdge"),
                                                  side_diagnoses = c("sdg1o", "sdg1e", "sdg2o", "sdg2e"),
                                                  enter_date = "tulopv", 
                                                  left_date = "lahtopv" )
){
  
  
  ### vars
  # get(variables[["id"]])
  # get(variables[["main_diagnoses"]])
  # get(variables[["side_diagnoses"]])
  # get(variables[["enter_date"]])
  # get(variables[["left_date"]])
  
  ## Main wrangle
  data %>%
    # hilmo %>% 
    mutate(id=get(variables[["id"]]),
           enter_date = get(variables[["enter_date"]]),
           left_date = get(variables[["left_date"]])
    ) %>% 
    filter(id%in% population_data$id) %>%
    left_join(population_data %>% select(id, diagnosed)) %>% 
    mutate(
      # Scaled enter and leave dates
      tulo_scaled = as.integer(get(variables[["enter_date"]]) - diagnosed),
      lahto_scaled = as.integer(get(variables[["left_date"]]) - diagnosed),
      days = as.integer(lahto_scaled - tulo_scaled + 1),
      # Scaled enter and leave years
      tulo_yr = round(tulo_scaled / 365, 2), 
      laht_yr = round(lahto_scaled / 365, 2)
    ) %>% 
    select(id, variables[["main_diagnoses"]], variables[["side_diagnoses"]], enter_date, left_date, days, tulo_scaled, lahto_scaled, tulo_yr, laht_yr) -> temp_hilmo_diags
  
  ## Diagnoses in 3 digit substr
  substr3func <- function(x){ substr(x, 1, 3)}
  temp_hilmo_diags[, c(variables[["main_diagnoses"]], variables[["side_diagnoses"]])] <- sapply(temp_hilmo_diags[, c(variables[["main_diagnoses"]], variables[["side_diagnoses"]])], substr3func)
  
  ## Hilmo 
  hilmo_diags <<- temp_hilmo_diags
  
  ## Main diagnoses
  temp_hilmo_diags %>% 
    pivot_longer(cols = variables[["main_diagnoses"]], names_to = "source", values_to = "main") %>% 
    filter(main != "") %>% 
    filter(!duplicated(.)) %>% 
    select(id, source, main, tulo_scaled, lahto_scaled, days, tulo_yr, laht_yr) %>% 
    mutate(ICD = substr(main, 1, 1))  ->> hilmo_maindiags
  
  ## Side diagnoses
  temp_hilmo_diags %>% 
    pivot_longer(cols = variables[["side_diagnoses"]], names_to = "source", values_to = "side") %>%
    filter(side != "") %>% 
    filter(!duplicated(.)) %>% 
    select(id, source, side, tulo_scaled, lahto_scaled, days, tulo_yr, laht_yr) %>% 
    mutate(ICD = substr(side, 1, 1)) ->> hilmo_sidediags
  
}