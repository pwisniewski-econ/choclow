library(tidyverse)
library(arrow)
library(haven)
library(data.table)
library(fixest)

run_prod_analysis <- function(sample_name, var_def, FIRM_DATA, EVENTS, regid_min = 9000){
  
  SIREN_LE <- open_dataset(paste0("results_building/main_samples/", sample_name, ".parquet")) |> 
    select(siren = sir) |> 
    collect() |>
    mutate(isin_le = T) |>
    unique()
  
  MODAL_DISP <- EVENTS |>
    group_by(siren) |>
    mutate(
      all_disp = sum(n), 
      and_concentration = if_else(!(n == max(n) & n > .8 * all_disp), 9999, and), 
      and_first = min(and), 
    ) |>
    summarise(and = min(if(var_def=="first"){and_first}else if(var_def=="concentrated"){and_concentration}))
  
  CANDIDATES <- FIRM_DATA |>
    left_join(SIREN_LE, by = "siren") |> 
    filter(isin_le&!is.na(prod_res_ma3)) |> 
    complete(siren, year = full_seq(year, 1)) |>
    left_join(MODAL_DISP, by = c("siren")) |> 
    filter(is.na(and) | and != 9999) |> 
    mutate(
      treated = if_else(year >= and, 1, 0), 
      treated = if_else(is.na(treated), 0, treated)
    ) |>
    arrange(siren, year) |>
    group_by(siren) |>
    mutate(d_treated = treated - lag(treated)) |>
    ungroup() |>
    setDT()
  
  lp_did <- function(h_shift, yvar, DATA, desc, reg_id, ref_level = -2){
    
    diff_v1 <- function(col, i, lag_level){
      shift(col, type = "lead", n = i) - shift(col, type = "lag", n = lag_level)
    }
    
    DATA[, yval := diff_v1(get(yvar), h_shift, -ref_level), by=.(siren)]
    #DATA[, clean := shift(treated, type = "lead", n=max(0, h_shift)), by=.(siren)]
    DATA[, clean_control := is.na(and) | and > year + max(0, h_shift + 1)]
    DATA <- DATA[!is.na(d_treated) & (d_treated==1 | clean_control), .(siren, year, yval, d_treated)]
    
    model <- feols(yval ~ d_treated | year, cluster = ~siren, data=DATA)
    
    r2_mod <- r2(model)
    
    DF <- as.data.frame(model$coeftable) 
    names(DF) <- c("beta", "std_error", "tval", "pval")
    
    DF |>
      rownames_to_column(var = "coefficient") |>
      mutate(
        coefficient = paste0(coefficient, "_{h=",h_shift, "}"),
        dep_var = yvar,
        model_id = reg_id, 
        n_obs = model$nobs, 
        n_trated = length(unique(filter(DATA, d_treated==1)$siren)),
        n_ind = length(unique(DATA$siren)), 
        r2 = r2_mod["r2"], 
        ar2 = r2_mod["ar2"],
        wr2 = r2_mod["wr2"], 
        war2_adj = r2_mod["war2"],
        sample = sample_name,
        description = paste0("LE-event def: ", desc)
      ) 
    
  }
  
  k <- regid_min
  results <- list()
  
  for(i in c(-4,-3,-1:6)){
    k <- k + 1
    results[[length(results)+1]] <- lp_did(i, "prod_res_ma3", CANDIDATES, var_def, k)
    k <- k + 1
    results[[length(results)+1]] <- lp_did(i, "tfp_cd_ma3", CANDIDATES, var_def, k)
    k <- k + 1
    results[[length(results)+1]] <- lp_did(i, "tfp_tl_ma3", CANDIDATES, var_def, k)
  }
  
  return(bind_rows(results))
}

# MAIN PIPELINE ----

FIRM_OUTCOMES_MOVING <- 
  read_dta("data/interim/firm_outcomes/firm_siren_avg_moving.dta", 
           col_select = c("siren", "year", "prod_res_ma3", "tfp_tl_ma3", "tfp_cd_ma3")) |>
  filter(year>2001)

#YEAR 2001-2014

MODAL_DISP <- read_dta("data/interim/lic_eco/le2_alljobs.dta") |>
  mutate(siren = as.numeric(sir)) |>
  filter(!is.na(siren)) |>
  group_by(siren, and) |>
  summarise(n=n()) 

reg_count <- 80000
main_results <- list()

for(sample in c("le5_panelsize0", "le5_panelsize10")){
  for(def in c("first", "concentrated")){
    main_results[[length(main_results)+1]] <- run_prod_analysis(sample, def, FIRM_OUTCOMES_MOVING, MODAL_DISP, reg_count)
    reg_count <- reg_count + 100
  }
}
  

write_csv(bind_rows(main_results), "results_analysis/ref_answers-productivity/productivity-post_le_es.csv")
