
create_population <- function(data, 
                              variables = list(id = "idnum",                        # Id number
                                               birthday_date = "SYNTPV",               # Date of birth
                                               died_date = "kuolpv",                   # Date of person died
                                               diagnosed_date = "erko307_pv",          # Date when person got diagnosed
                                               gender_factor = "SP",                   # Gender in factor var
                                               censoring_date = as.Date("2015-12-31"), # Single date value when follow up study ended
                                               area_SHP_code = "SHP"  # Optional
                              )
){
  ### Pre-check
  stopifnot(is.data.frame(data))
  stopifnot(is.list(variables))
  stopifnot(all(names(variables) %in% c("id", "birthday_date", "died_date", "diagnosed_date", "gender_factor", "area_SHP_code", "censoring_date")) )
  
  ### Harmonize popdata dataset
  popdata <- data %>% 
    mutate(diagnosed = get(variables[["diagnosed_date"]]),
           diagnosed_age = as.numeric(get(variables[["diagnosed_date"]]) - get(variables[["birthday_date"]])) / 365.25,
           diagnosed_age_yrs = as.numeric(round(diagnosed_age)),
           diagnosed_yr = year(get(variables[["diagnosed_date"]])),  #  or = format(erko307_pv,"%Y")  # year of diagnosis
           censored = factor(ifelse(is.na(get(variables[["died_date"]])), 1, 0)),
           birthday = get(variables[["birthday_date"]]),
           died = get(variables[["died_date"]]),
           survived = ifelse(censored == 1, variables[["censoring_date"]] - diagnosed, died - diagnosed), #get(variables[["died_date) - diagnosed,
           id = get(variables[["id"]]),
           gender = get(variables[["gender_factor"]]),
           area_SHP = ifelse("area_SHP_code" %in% names(variables),  factor(get(variables[["area_SHP_code"]])), "" ), ### TODO CHECK IF OK IN FACTOR
           survived_yrs_cat = as.character(cut(as.integer(survived),
                                               breaks = c(-Inf, 180, 365, 730, 1095, Inf),
                                               labels = c("< half year", "0.5 - 1 year", "1-2 years", "2-3 years", "3+ years"))),
           survived_yrs_cat_censored = as.factor(ifelse(censored == 0, survived_yrs_cat, "Censored")), ## NOTE: if person is censored before he died, survived category is then "censored"
           survived_yrs_cat = as.factor(survived_yrs_cat) ## NOTE: if person was alive 2 years after diagnose and at the same time dataset is censored. Person survived 2yrs.
    ) %>% 
    select(id, gender, birthday, died, area_SHP, diagnosed, diagnosed_age, diagnosed_age_yrs, diagnosed_yr, survived, survived_yrs_cat, censored) 
  
  ### Remove optional vars ###
  if(! "area_SHP_code" %in% names(variables)) popdata$area_SHP <- NULL
  
  ### Data check and corrections ###
  ## RULE: If ID has diagnosed_day > died -> Recode diagnose day same as died day
  # popdata <- popdata[popdata$survived >= 0, ] # REMOVE
  popdata[popdata$survived < 0, "diagnosed"] <- popdata[popdata$survived < 0, "died"] # SAME AS DIED
  popdata[popdata$survived < 0, "survived"] <- 0 # SAME AS DIED
  
  # Return / Save to global env
  population <- popdata
}

