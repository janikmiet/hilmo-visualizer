


create_hilmotl <- function(data = hilmo_agg1, 
                           timeline = seq(-20, 20, by = 1)){
  ### Pre-check
  stopifnot(is.data.frame(data))
  
  ## Hilmo timeline dataset: 20 year of timeline of pdgo
  ## TODO add column (list) including id's which are then used in shiny app to filter right population
  ## TODO also add to shiny app percentage calculation correcting "the new pop"
  ## NOTE: i is end of the time interval. Ex. i=1 means that events that has happened between 0.01 - 1
  ## NOTE: calculation is approx because real years are not counted. Year is defined as 365 days.
  hilmo_tl <- NULL
  for(i in timeline){
    if(is.null(hilmo_tl)){
      hilmo_agg1 %>% 
        filter( ( tulo_yr <= i & laht_yr > i - 1) ) %>% 
        group_by(ICD) %>% 
        summarise(
          time = i,
          patients = length(unique(id)) ,
          cases = n(),
          ## Formula 1.1: This formula is explained in documentation
          hospital_days = sum(case_when(tulo_yr > (i - 1) & laht_yr <= (i) ~ as.double(days),
                                        tulo_yr < (i - 1) & laht_yr >= (i) ~ 365,
                                        tulo_yr < (i - 1) & laht_yr < (i) & laht_yr > (i - 1) ~ abs(abs((i - 1) * 365) - abs(lahto_scaled)),
                                        tulo_yr > (i - 1) & tulo_yr < (i) & laht_yr > (i + 1) ~ ifelse(i<0, 
                                                                                                       abs(tulo_scaled) - (abs(i * 365)),
                                                                                                       abs(abs(i * 365) - abs(tulo_scaled))
                                        )  
                                        
          ), na.rm = T)
          
        )   -> hilmo_tl
    }else{
      hilmo_tl <- hilmo_tl %>% 
        rbind(
          hilmo_agg1 %>% 
            filter( ( tulo_yr <= i & laht_yr > i - 1) ) %>% 
            group_by(ICD) %>% 
            summarise(
              time = i,
              patients = length(unique(id)) ,
              cases = n(),
              ## Formula 1.1: This formula is explained in documentation
              hospital_days = sum(case_when(tulo_yr > (i - 1) & laht_yr <= (i) ~ as.double(days),
                                            tulo_yr < (i - 1) & laht_yr >= (i) ~ 365,
                                            tulo_yr < (i - 1) & laht_yr < (i) & laht_yr > (i - 1) ~ abs(abs((i - 1) * 365) - abs(lahto_scaled)),
                                            tulo_yr > (i - 1) & tulo_yr < (i) & laht_yr > (i + 1) ~ ifelse(i<0, 
                                                                                                           abs(tulo_scaled) - (abs(i * 365)),
                                                                                                           abs(abs(i * 365) - abs(tulo_scaled))
                                            )  
                                            
              ), na.rm = T)
              
            ) 
        )
    }
  }
  return(hilmo_tl)
}




