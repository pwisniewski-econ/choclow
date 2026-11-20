main_helper <- function(filename_k){
  
  library(tidyverse)
  library(data.table)
  library(fixest)
  fixest::setFixest_nthreads(1)
  library(arrow)
  arrow::set_cpu_count(1)
  
  premium_corr <- function(yval, xvals, fixed_effect = NULL, errors = "HC1", reg_id = 1, sample_name = "", weight, DATA){
    
    if(!all(str_detect(errors, "HC1"))){
      error_spec <- paste0("~", paste0(errors, collapse = "+"))
      error_fml <- as.formula(error_spec)
    }else{
      error_fml <- errors
    }
    
    if(!is.null(fixed_effect)){
      fixed_effect <- paste0(" | ", paste0(fixed_effect, collapse = "+"))
    } 
    
    xvals <- paste0(xvals, collapse = "+")
    fml <- paste0(yval, "~", xvals, fixed_effect)
    mod <- feols(as.formula(fml), data = SAMPLE, vcov = error_fml, weights = as.formula(paste0("~", weight)))
    
    r2_mod <- r2(mod)
    
    RESULTS <- as.data.frame(mod$coeftable) 
    names(RESULTS) <- c("beta", "std_error", "tval", "pval") 
    
    RESULTS |> 
      rownames_to_column(var = "variable") |>
      mutate(dep_var = yval, 
             errors = error_spec,
             reg_id = 12, 
             n_siren = length(unique(SAMPLE$siren)),
             n_obs = mod$nobs, 
             r2 = r2_mod["r2"], 
             ar2 = r2_mod["ar2"],
             wr2 = r2_mod["wr2"], 
             war2_adj = r2_mod["war2"],
             sample = sample_name,
             formula = fml
      )
    
  }
  
  logs_fun <- function(msg, cl=1){
    cat(paste0(cl, " | ", format(Sys.time(), "%Y/%m/%d: %H:%M:%S"), " | ", msg, "\n"), file = "logs/tbl_a6.log", append = T)
  }

  controls_list <- list(
    c("ln_emp"), 
    c("year_cre"), 
    c("ln_emp", "ln_va"), 
    c("ln_emp", "ln_apl"), 
    c("ln_emp", "prod_res"), 
    c("ln_emp", "tfp_cd"),
    c("ln_emp", "tfp_tl"),
    c("before1994"), 
    c("maxmfg"), 
    c("ln_emp", "prod_res", "before1994", "maxmfg"), 
    c("year_cre","ln_emp", "prod_res", "before1994", "maxmfg"), 
    c("ln_emp", "tfp_cd", "before1994", "maxmfg"),
    c("ln_emp", "tfp_tl", "before1994", "maxmfg")
  )
  
  acco_list <- list(
    c("wage_agreement_ind_0507"),
    c("wage_agreement_fail_0507"),
    c("wage_agreement_share_0507"),
    c("extwage_agreement_ind_0507")
  )
  
  elec_list <- list(
    c("shinscrit_carence_siren0912"), 
    c("participation_siren0912"), 
    c("shinscrit_sup10cgt_siren0912"),
    c("cgt_siren0912"),
    c("bnuls_siren0912")
  )
  
  
  yvars <- c("fe0215_god2", "fe0215_mlo_le", "fe0215_mlo", "fe0215_le")
  
  results <- list()
  k <- 0
  
  filename <- filename_k[[1]][1]
  regid_min <- as.numeric(filename_k[[1]][2])
  
  path <- paste0("results_building/main_samples/", filename, ".parquet")
  
  type_ls <- c("fixed", "acco", "acco_alt", "elec")
  
  for(t in 1:length(type_ls)){
    
    type <- type_ls[t]
    logs_fun(paste0(t, "/", length(type_ls), " (", type, ")"), filename)
    error_level <- "minmax_year"
    shared_vars <- c("siren", "ln_emp_mean_0215", "prod_res_mean_0215")
    
    if(type == "fixed"){
      type_controls <- lapply(controls_list, \(x) fifelse(!str_detect(x, "year_cre|before1994|maxmfg"), paste0(x, "_mean_0215"), x))
      fixed_effects <- c("minmax_year","naf2d_num_main")
    }else if(type == "acco"){
      type_controls <- acco_list
      fixed_effects <- c("minmax_year","naf2d_num_main")
    }else if(type == "acco_alt"){
      type_controls <- lapply(acco_list, \(x) paste0(x, "_alt"))
      fixed_effects <- c("minmax_year","naf2d_num_main")
    }else if(type == "elec"){
      type_controls <- elec_list
      fixed_effects <- c("minmax_year","naf2d_num_main")
    }
    
    all_cols <- unique(c(unlist(type_controls), yvars, fixed_effects, shared_vars))
    
    SAMPLE <- open_dataset(path) |>
      mutate(before1994 = if_else(year_cre < 1994, 1, 0), minmax_year = paste0(min_year, max_year)) |>
      select(all_of(c(all_cols))) |>
      collect() |> 
      setDT()
    
    SAMPLE <- SAMPLE[SAMPLE[, rowSums(is.na(.SD))==0, .SDcols = all_cols]]
    SAMPLE <- unique(SAMPLE[, .SD, .SDcols = all_cols])
    SAMPLE[, "one" := 1]
    
    weighting_var <- c("one", "exp(ln_emp_mean_0215)")
    
    for(w in weighting_var){
      for(yvar in yvars){
        for(xset in type_controls){
          k <- k + 1
          results[[length(results)+1]] <- premium_corr(yvar, xset, fixed_effects[1], error_level, k, paste0(filename, "-", type, "-", w), weight = w, DATA = SAMPLE)
          
          
          if(all(c("ln_emp_mean_0215", "before1994", "maxmfg")%in%xset)){
            k <- k + 1
            results[[length(results)+1]] <- premium_corr(yvar, xset, fixed_effects[1:2], error_level, k, paste0(filename, "-", type, "-", w), weight = w, DATA = SAMPLE)
          } else if(type%in%c("acco", "acco_alt", "elec")){
            k <- k + 1
            results[[length(results)+1]] <- premium_corr(yvar, c(xset[[1]], "ln_emp_mean_0215"), fixed_effects[1], error_level, k, paste0(filename, "-", type, "-", w), weight = w, DATA = SAMPLE)
            k <- k + 1
            results[[length(results)+1]] <- premium_corr(yvar, c(xset[[1]], "ln_emp_mean_0215", "prod_res_mean_0215"), fixed_effects[1], error_level, k, paste0(filename, "-", type, "-", w), weight = w, DATA = SAMPLE)
            k <- k + 1
            results[[length(results)+1]] <- premium_corr(yvar, xset, fixed_effects[1:2], error_level, k, paste0(filename, "-", type, "-", w), weight = w, DATA = SAMPLE)
          }
        }
      }
    }
  }
  
  write_csv(bind_rows(results), paste0("results_analysis/tbl_a6-corr_akm/", filename, ".csv"))
  
  return(0)
}





library(parallel)
cl <- makeCluster(3)

starting_id <- 60000
all_samples <- stringr::str_remove(list.files("results_building/main_samples"), ".parquet")

filename_k <- mapply(c, all_samples, seq(starting_id, starting_id + 200*(length(all_samples)-1), 200), SIMPLIFY = FALSE, USE.NAMES = FALSE)

parLapplyLB(cl, filename_k, main_helper)

