## Needed variables in dataset:
# idnum
# pdgo, pdge
# sdg1o, sdg1e, sdg2o, sdg2e
# tulopv, lahtopv



create_hilmoagg <- function(data, 
                            population_data = population,
                            variables = list(id = "idnum",                
                                             pdgo = "pdgo",            
                                             pdge = "pdge",               
                                             sdg1o = "sdg1o",          
                                             sdg1e = "sdg1e",                  
                                             sdg2o = "sdg2o",
                                             sdg2e = "sdg2e",
                                             enter_date = "tulopv", 
                                             left_date = "lahtopv" 
                            )){
  ### Pre-check
  stopifnot(is.data.frame(data))
  stopifnot(is.list(variables))
  stopifnot(all(names(variables) %in% c("id", "pdgo", "pdge", "sdg1o", "sdg1e", "sdg2o", "sdg2e", "enter_date", "left_date")) )
  
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
  
  return(hilmo_agg1)
  
}
