library(data.table)
library(tidyverse)
library(haven)
library(fixest)
library(arrow)
library(parallel)

matching_description <- function(desc_dist, path){
  
  SAMPLE <- read_parquet(path)
  
  firm_vars <- names(SAMPLE)[str_detect(names(SAMPLE), "_ma3|0215")&!str_detect(names(SAMPLE), "hhi_zecs1|q4")]
  fevars <- names(SAMPLE)[str_detect(names(SAMPLE), "fe\\d{4}")&!str_detect(names(SAMPLE), "q5")]
  acco_vars <- names(SAMPLE)[str_detect(names(SAMPLE), "07")]
  elec_vars <- names(SAMPLE)[str_detect(names(SAMPLE), "09")]
  employee_vars <- c("nbheur", "sbr", "sbrhour", "employed", "age_cl") 
  desc_vars <- unique(c(firm_vars, fevars, acco_vars, elec_vars, employee_vars, "fe0215_mlo_le", "sx", "prod_res_ma3", "nbsa_ent", "year_cre", "age_firm"))
  #, "sbrhour2", "sbrhour3", "nbheur2", "nbheur3", nbsa_ent1
  
  if(is.null(SAMPLE$idfhda)){
    idvar <- "nninouv"
  } else {
    idvar <- "idfhda"
  }
  
  
  SAMPLE |>
    group_by(across(all_of(idvar))) |>
    #mutate(across(c(sbrhour, nbheur), ~ mean(.x[dist==-2]), .names = "{.col}2")) |>
    #mutate(across(c(sbrhour, nbheur), ~ mean(.x[dist==-3]), .names = "{.col}3")) |>
    #mutate(nbsa_ent1 = mean(nbsa_ent[dist==-1])) |>
    #filter(!any(is.na(c(sbrhour2, sbrhour3, nbheur2, nbheur3, age_cl, nbsa_ent1)))) |>
    filter(dist==desc_dist) |> 
    group_by(Treated = if_else(`T`==1, "Treated", "Control")) |> 
    summarise(
      across(all_of(desc_vars), ~ sd(.x, na.rm=TRUE), .names = "{.col}_sd"), 
      across(all_of(desc_vars), ~ sum(!is.na(.x)), .names = "{.col}_n"),
      across(all_of(desc_vars), ~ mean(.x, na.rm=TRUE))
    ) |>
    pivot_longer(-Treated) |>
    pivot_wider(id_cols = name, values_from = value, names_from = Treated) |>
    mutate(tmp = str_remove(name, "_sd")) |>
    arrange(tmp, name) |>
    group_by(tmp) |>
    mutate(sample = path, `Norm. Diff.` =  
      (Treated - Control) / (sqrt((lead(Control)^2 + lead(Treated)^2))/2)
    ) |>
    ungroup() |> 
    select(name, Treated, Control, `Norm. Diff.`, sample) |>
    mutate(ref_dist = desc_dist)
}

all_samples <- c(list.files("results_building/main_samples", full.names = TRUE), list.files("results_building/elec_samples", full.names = TRUE))

matching_balance <- vector("list", length(all_samples))

desc_helper <- function(fullpath){
  library(data.table)
  library(tidyverse)
  library(haven)
  library(fixest)
  library(arrow)
  lapply(-5:6, matching_description, fullpath) |>
    bind_rows()
} 

cl <- makeCluster(4)
clusterExport(cl, "matching_description")
MATCHING_BALANCE <- parLapply(cl, all_samples, desc_helper)|>
  bind_rows()
stopCluster(cl)
write_csv(MATCHING_BALANCE, "results_analysis/misc-descriptive_statistics/matching_balance.csv")

# DADS PANEL DESCRIPTION ----
PANEL_DESC <- read_dta("data/interim/panel_outcomes/descriptives_panel.dta") 

## SAMPLE MEANS ----
get_panel_means <- function(var, min_year, max_year, DATA){
  
  weight_name <- paste0("one_", var)
  eqtp_name <- paste0(var, "_nb")
  eqtp_weight <- paste0("nbheur_", var)
  
  if(var!="age"){
    DATA <- DATA |> mutate(
        "{var}" := .data[[var]] / .data[[weight_name]],
        "{eqtp_name}" := .data[[var]] /  .data[[eqtp_weight]]
      )
  }else{
    DATA <- DATA |> filter(age>0&age<110)
  }
  
  DATA |>
    filter(an>=min_year&an<=max_year) |>
    group_by(sample = paste0("DADS-", min_year, "_", max_year)) |>
    summarise(
      mean = weighted.mean(.data[[var]], n, na.rm=TRUE), 
      mean_eqtp = weighted.mean(.data[[var]], nbheur, na.rm=TRUE), 
      n_individuals = sum(n), 
      n_eqtp = sum(nbheur)
    ) |>
    mutate(variable = var)

}

REFERENCE <- bind_rows(lapply(c("sx", "sbr", "age"), get_panel_means, 2005, 2012, PANEL_DESC)) |>
  rbind(bind_rows(lapply(c("sx", "sbr", "age"), get_panel_means, 2005, 2015, PANEL_DESC)))

write_csv(REFERENCE, "results_analysis/misc-descriptive_statistics/panel_dads_means.csv")

## OCCUPATIONS IN DADS-PANEL
FH_DESC <- read_dta("data/interim/panel_outcomes/panel_fh0212.dta") 
PANEL_DADS <- read_dta("data/interim/panel_outcomes/descriptives_panel.dta") 

get_panel_class <- function(var, min_year, max_year, DATA){
  
  DATA |>
    filter(an>=min_year&an<=max_year) |>
    group_by(, 
      value = as.integer(.data[[var]]),
    ) |>
    summarise(
      n_individuals = sum(n),
      eqtp = sum(nbheur, na.rm=TRUE)/1820
    ) |>
    mutate(variable = var, sample = paste0("dads-", min_year, "_", max_year), treated = "2")
  
}

REF_PANEL <- bind_rows(lapply(c("cs1", "sec_a10"), get_panel_class, 2005, 2015, PANEL_DADS))
REF_FH <- bind_rows(lapply(c("cs1", "sec_a10", "dip_tot"), get_panel_class, 2005, 2012, FH_DESC))

## OCCUPATIONAL COMPARISONS
occup_helper <- function(sample){
  
  occupational_comp <- function(filename, var){
    open_dataset(paste0("results_building/main_samples/",filename,".parquet")) |> 
      filter(dist==-1)|>
      collect() |>
      group_by(value = as.integer(.data[[var]]), treated = as.character(`T`)) |>
      summarise(n_individuals=n(), eqtp = sum(nbheur, na.rm=TRUE)/1820, .groups = "drop") |>
      mutate(variable = var, sample = filename)
  }
  
  res <- bind_rows(occupational_comp(sample, "cs1")) |>
    rbind(bind_rows(occupational_comp(sample, "sec_a10")))
  
  if(str_detect(sample, "le5_")){
    res <- res |> rbind(bind_rows(occupational_comp(sample, "dip_tot")))
  }
  
  return(res)
  
}

all_samples <- str_remove(list.files("results_building/main_samples/"), ".parquet")

TREATED_BINS <- bind_rows(lapply(all_samples, occup_helper))

OCCUP_COMPARISONS <- rbind(REF_FH, REF_PANEL, TREATED_BINS) |> 
  arrange(sample, treated) |>
  filter(n_individuals>5)

write_csv(OCCUP_COMPARISONS, "results_analysis/misc-descriptive_statistics/cs1_sec10_samples.csv")


## ACCO ----

summ_acco <- function(filename){
  
  summstat <- function(DATA, suffix){
    RES <- DATA |> 
      summarise(across(ends_with(suffix), 
                       list(
                         mean = ~mean(.x, na.rm=TRUE), 
                         sd = ~sd(.x, na.rm=TRUE),
                         min = ~min(.x, na.rm=TRUE),
                         p25 = ~quantile(.x, .25, na.rm=TRUE),
                         p50 = ~quantile(.x, .50, na.rm=TRUE),
                         p75 = ~quantile(.x, .75, na.rm=TRUE),
                         max = ~max(.x, na.rm=TRUE), 
                         n_obs = ~n(), 
                         n_nonmiss = ~sum(!is.na(.x))
                       ), 
                       .names = "{.col}__{.fn}")) |>
      pivot_longer(everything()) |>
      mutate(var_name = str_remove(name, paste0(suffix, ".*")), summstat = str_remove(name, ".*__")) |>
      pivot_wider(id_cols = var_name, values_from = value, names_from = summstat) |>
      mutate(n_individuals_treated = length(unique(DATA[T==1]$id2)), n_individuals_control = length(unique(DATA[T==0]$id2)), n_firms = length(unique(DATA$siren)))
    
    return(RES)
  }
  
  DATA <- open_dataset(paste0("results_building/main_samples/",filename,".parquet")) |>
    select(id2, siren, `T`, ends_with("07_alt"), ends_with("_0507"), ends_with("0912")) |>
    collect()
  
  refvar <- c("_0507"="wage_agreement_ind_0507", "0507_alt"="wage_agreement_ind_0507_alt", "0912"="shinscrit_carence_siren0912")
  
  
  results <- list()
  
  for (i in 1:length(refvar)) {
    results[[length(results)+1]] <- DATA |> 
      filter(!is.na(.data[[refvar[i]]])) |>
      summstat(names(refvar[i])) 
  }
  
  return(mutate(bind_rows(results),  sample = filename))
  
}

all_samples <- str_remove(list.files("results_building/main_samples/"), ".parquet")

lapply(all_samples, summ_acco) |> 
  bind_rows() |>
  write_csv("results_analysis/misc-descriptive_statistics/desc_sample-acco_elec.csv")


### TENURE LENGTHS BY COHORTS 
TENURE <- read_dta("data/interim/panel_outcomes/tenure_panel.dta")

TENURE <- TENURE |> 
  filter(annai%%2==0&annai>1944&an-annai>24) |>
  mutate(tenure = if_else(tenure>10, 10, tenure)) |> 
  group_by(an, annai, tenure) |>
  summarise(across(c(n, nbheur), ~sum(.x))) |>
  arrange(n) |>
  mutate(n_individuals = n, n_eqtp = nbheur/1820) |>
  filter(n_individuals > 5) |>
  select(an, annai, tenure, n_individuals, n_eqtp)


write_csv(TENURE, "results_analysis/misc-descriptive_statistics/desc_tenure_per_cohorts.csv")

### GET IQ RANGES FOR FIRM OUTCOMES
FIRM_OUTCOMES_FIXED <- setDT(read_dta("data/interim/firm_outcomes/firm_siren_avg_fixed.dta"))

FIRM_OUTCOMES_FIXED <- FIRM_OUTCOMES_FIXED |>
  filter(!is.na(ln_emp_mean_0215)) |>
  mutate(emp_0215 = exp(ln_emp_mean_0215)) |>
  group_by(max_year, min_year) |>
  mutate(across(c("prod_res_mean_0215", "ln_apl_mean_0215", "fe0215_mlo_le", "ln_lshare_mean_0215"), ~ .x - mean(.x, na.rm = TRUE))) |>
  ungroup()

FIRM_OUTCOMES_DESC <- FIRM_OUTCOMES_FIXED |>
  summarise(across(c("prod_res_mean_0215", "ln_apl_mean_0215", "fe0215_mlo_le", "ln_lshare_mean_0215"),
    list(
      mean = ~mean(.x, na.rm=TRUE),
      mean_w = ~weighted.mean(.x, emp_0215, na.rm=TRUE),
      sd = ~sd(.x, na.rm=TRUE),
      sd_w = ~sqrt(Hmisc::wtd.var(.x, emp_0215, na.rm=TRUE)),
      min = ~min(.x, na.rm=TRUE),
      p25 = ~quantile(.x, .25, na.rm=TRUE),
      p25_w = ~Hmisc::wtd.quantile(.x, emp_0215, .25, na.rm=TRUE),
      p50 = ~quantile(.x, .50, na.rm=TRUE),
      p50_w = ~Hmisc::wtd.quantile(.x, emp_0215, .50, na.rm=TRUE),
      p75 = ~quantile(.x, .75, na.rm=TRUE),
      p75_w = ~Hmisc::wtd.quantile(.x, emp_0215, .75, na.rm=TRUE),
      max = ~max(.x, na.rm=TRUE),
      n_obs = ~n(),
      n_nonmiss = ~sum(!is.na(.x))
    ),
    .names = "{.col}__{.fn}")) |>
  pivot_longer(everything()) |>
  mutate(var_name = str_remove(name, "__.*"), summstat = str_remove(name, ".*__")) |>
  pivot_wider(id_cols = var_name, values_from = value, names_from = summstat) |>
  mutate(IQ = p75 - p25, IQ_W = p75_w - p25_w)

write_csv(FIRM_OUTCOMES_DESC, "results_analysis/misc-descriptive_statistics/desc_firm_outcomes.csv")
