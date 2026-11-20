main_helper <- function(file_k, hetvars){
  
  library(data.table)
  data.table::setDTthreads(1)
  library(tidyverse)
  library(haven)
  library(fixest)
  fixest::setFixest_nthreads(1)
  library(arrow)
  arrow::set_cpu_count(1)
  
  logs_fun <- function(msg, cl=1){
    cat(paste0(cl, " | ", format(Sys.time(), "%Y/%m/%d: %H:%M:%S"), " | ", msg, "\n"), file = "logs/event_studies-main_samples.log", append = T)
  }
  
  event_study <- function(sample, yval, inter_group = NULL, reg_id = 1, more_info = NA_character_, ref_level = -2){
    
    DATA <- sample[[1]]
    sample_name <- names(sample)[[1]]
    
    if(!is.null(inter_group)){DATA <- DATA |> filter(!is.na(.data[[inter_group]]))}
    DATA <- DATA |> mutate(y = .data[[yval]], inter_group = if(is.null(inter_group)) "none" else paste0(inter_group,":",.data[[inter_group]]))
    
    RAWMEANS <- DATA |>
      group_by(`T`, inter_group, dist) |>
      summarise(mean_yval = mean(.data[[yval]], na.rm=TRUE), .groups = "drop") |>
      mutate(`T` = if_else(`T`==1, "treated", "control")) |>
      pivot_wider(names_from = `T`, values_from = mean_yval, names_prefix = "mean_")
    
    
    base_fml <- paste0('y ~ `T`:i(dist, inter_group, ref="', ref_level, '") + i(dist, inter_group, ref = "', ref_level-1, '")')
    
    if(str_detect(sample_name, "le5_panelsize20")){
      fixed_effects <- c("an")
    }else{
      fixed_effects <- c("id2","an")
    }
    
    model_fml <- as.formula(paste0(base_fml, "|", paste0(fixed_effects, collapse = "+")))
    
    model <- feols(fml = model_fml, cluster = ~ idcluster, data = DATA) 
    
    nobs <- model$nobs
    n_treated <- length(unique(filter(DATA, `T`==1)$id2))
    n_ind <- length(unique(DATA$id2))
    r2_mod <- r2(model)
    
    DF <- as.data.frame(model$coeftable) 
    names(DF) <- c("beta", "std_error", "tval", "pval") 
    
    DF |>
      rownames_to_column(var = "distance") |>
      filter(str_detect(distance, "dist")) |>
      mutate(
        treatment_path = if_else(str_starts(distance, "T:"), TRUE, FALSE),
        interaction_group = str_extract(distance, "(?<=inter_group::).*"),
        distance = as.integer(str_extract(distance, "(?<=::).*(?=:inter_group)")), 
        dep_var = yval, 
        model_id = reg_id, 
        n_obs = model$nobs, 
        n_treated = length(unique(filter(DATA, `T`==1)$id2)), 
        n_ind = length(unique(DATA$id2)), 
        r2 = r2_mod["r2"], 
        ar2 = r2_mod["ar2"],
        wr2 = r2_mod["wr2"], 
        war2_adj = r2_mod["war2"],
        sample = sample_name,
        description = more_info
      ) |>
      group_by(across(-all_of(c("distance","beta", "std_error", "tval", "pval", "treatment_path")))) |>
      group_modify(~add_row(.x, distance = ref_level, beta = 0, treatment_path = TRUE)) |>
      ungroup()|>
      arrange(interaction_group, -treatment_path, distance) |>
      left_join(RAWMEANS, by = c("distance" = "dist", "interaction_group" = "inter_group")) |>
      select(distance, treatment_path, mean_treated, mean_control, beta, std_error, tval, pval, everything()) 
  }
  
  
  filename <- file_k[1]
  
  min_k <- as.numeric(file_k[2])
  
  path <- paste0("results_building/main_samples/", filename, ".parquet")
  
  regdata <- open_dataset(path) 
  
  firm_vars <- names(regdata)[str_detect(names(regdata), "_ma3_dlag4|mean_0215")&!str_detect(names(regdata), "hhi_zecs1|q4")]
  fevars <- names(regdata)[str_detect(names(regdata), "fe\\d{4}")&!str_detect(names(regdata), "q5")]
  #acco_vars <- names(regdata)[str_detect(names(regdata), "07")]
  #elec_vars <- names(regdata)[str_detect(names(regdata), "09")]
  employee_vars <- c("nbheur", "lnnbheur", "sbr", "lnsbr", "lnsbrhour", "employed") 
  added_vars <- c("age_firm", "year_cre")
  
  regression_vars <- unique(c(firm_vars, fevars, employee_vars, added_vars))
  heterogeneity_vars <- hetvars
  
  col_select <- c("id2", "an", "T", "dist", "idcluster", regression_vars, heterogeneity_vars)
  
  REG_SAMPLE <- regdata |>
    select(all_of(col_select)) |>
    collect() |>
    setDT()
  
  results <- list()
  k <- 0
  
  for(i in 1:length(regression_vars)){
    
    if(i%%3==0){gc(verbose = FALSE)}
    
    var <- regression_vars[i]
    logs_fun(paste0(i, "/", length(regression_vars), " (", var, ")"), filename)
    
    k <- k+1
    results[[length(results)+1]] <- setNames(list(REG_SAMPLE), filename) |>
      event_study(var, reg_id = k + min_k)
    
    for(hvar in heterogeneity_vars){
      if(!stringr::str_detect(hvar, var)){
        k <- k+1
        results[[length(results)+1]] <- setNames(list(REG_SAMPLE), filename) |>
          event_study(var, hvar, reg_id = k + min_k)
      }
    }
    
    if(var!="employed"){
      k <- k+1
      results[[length(results)+1]] <- setNames(list(REG_SAMPLE[!is.na(prod_res_ma3_dlag4)&!is.na(fe0215_mlo_le)]), filename) |>
        event_study(var, reg_id = k + min_k, more_info = "sample_nonmiss_full")
    }
    
    if(stringr::str_detect(var, "prod_res_mean_0215")){
      k <- k+1
      results[[length(results)+1]] <- setNames(list(REG_SAMPLE[!is.na(prod_res_ma3_dlag4)]), filename) |> 
        event_study(var, reg_id = k + min_k, more_info = "sample_nonmiss_ma3_dlag4")
    }
    
    
  }
  
  write_csv(bind_rows(results), paste0("results_analysis/event_studies-main_samples/", filename, "-res.csv"))
  
  return(0)
  
}

library(stringr)
library(parallel)
cl <- makeCluster(4)

all_samples <- list(
  c("le5_panelsize0", 10000), 
  c("le5_panelsize10", 11000), 
  c("panelpanSIZE1", 12000),
  c("panelpanSIZE2", 13000)
)

hetvars <- c("sx") #"hhi_zecs1_ma3_dlag4_q4", "age_cl_q4", "an_cl"

parLapplyLB(cl, all_samples, main_helper, hetvars)

