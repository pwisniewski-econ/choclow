reg_sample <- function(filename_k){
  
  library(tidyverse)
  library(fixest)
  fixest::setFixest_nthreads(1)
  library(arrow)
  arrow::set_cpu_count(1)
  
  logs_fun <- function(msg, cl=1){
    cat(paste0(cl, " | ", format(Sys.time(), "%Y/%m/%d: %H:%M:%S"), " | ", msg, "\n"), file = "logs/origin_destination.log", append = T)
  }
  
  reg_origins <- function(sample, yval, controls=FALSE, naf2_fe=FALSE, reg_id = 2000, weighted = FALSE){
    
    sample_filename <- names(sample)[[1]]
    
    if(str_detect(sample_filename, "moving")){
      main_fe <- "an"
      second_fe <- "naf2d_ma3"
      possible_controls <- c("ln_apl_ma3", "ln_emp_ma3")
      clustvar <- "sir+an"
      weightvar <- "exp(ln_emp_ma3)"
    } else {
      main_fe <- "minmax_year"
      second_fe <- "naf2d_num_main"
      possible_controls <- c("ln_apl_mean_0215", "ln_emp_mean_0215")
      clustvar <- "minmax_year"
      weightvar <- "exp(ln_emp_mean_0215)"
    }
    
    
    if(controls){
      add_controls <- paste0(" + ", paste0(possible_controls, collapse = " + "))
    } else {
      add_controls <- NULL
    }
    
    if(naf2_fe){
      add_naf2fe <- paste0(" + ", second_fe)
    } else {
      add_naf2fe <- NULL
    }
    
    fml <- paste0(yval, " ~ destination + origin", add_controls, " | ", main_fe, add_naf2fe)
    
    if(weighted){
      mod <- feols(as.formula(fml), data = sample[[1]], cluster = as.formula(paste0("~", clustvar)), weights = as.formula(paste0("~", weightvar)))
    }else{
      mod <- feols(as.formula(fml), data = sample[[1]], cluster = as.formula(paste0("~", clustvar)))
    }
    
    
    nobs <- mod$nobs
    r2_mod <- r2(mod)
    
    b <- coef(mod)
    V <- vcov(mod)
    
    od_t <- (b["destinationTRUE"] - b["originTRUE"]) /
      sqrt(V["destinationTRUE", "destinationTRUE"] + V["originTRUE", "originTRUE"] - 2*V["destinationTRUE", "originTRUE"])
    
    p_od <- unname(
      2 * pt(-abs(od_t), df = degrees_freedom(mod, "t"))
    )
    
    RESULTS <- as.data.frame(mod$coeftable) 
    names(RESULTS) <- c("beta", "std_error", "tval", "pval") 
    
    RESULTS |> 
      rownames_to_column(var = "variable") |>
      mutate(dep_var = yval, 
             clustering = clustvar,
             weighted = weighted,
             model_id = reg_id, 
             n_obs = mod$nobs, 
             ar2 = unname(r2_mod["ar2"]), 
             p_origin_destination = p_od,
             r2 = r2_mod[2], 
             r2_proj = r2_mod[6],
             sample = names(sample)[[1]],
             controls = controls, 
             naf2_fe = naf2_fe
      )
    
  }
  
  filename <- filename_k[1]
  regid_min <- as.numeric(filename_k[2])
  
  path <- paste0("results_building/origin_destination/", filename, ".parquet")
  sample <- read_parquet(path) 
  
  sample <- setNames(list(sample), filename) 
  
  reg_helper <- function(var, controls, naf2_fe, k, using_weights, data = sample, min_k = regid_min){
    reg_origins(data, var, controls, naf2_fe, reg_id = min_k + k, weighted = using_weights)
  }
  
  dep_vars <- names(sample[[1]])[!str_detect(names(sample[[1]]), "sir|^an|minmax_year|naf2d|origin|destination|_va_")]
  
  MEANS <- sample[[1]] |>
    group_by(origin, destination) |>
    summarise(across(all_of(dep_vars), \(x) mean(x, na.rm=T)), n_siren = n_distinct(sir), nobs = n())
  
  
  results <- list()
  k <- 0
  
  for(i in 1:length(dep_vars)){
    
    logs_fun(paste0(i, "/", length(dep_vars)), filename)
    var <- dep_vars[i]
    
    k <- k+1
    results[[k]] <- reg_helper(var, F, F, k, F)
    k <- k+1
    results[[k]] <- reg_helper(var, F, T, k, F) 
    
    k <- k+1
    results[[k]] <- reg_helper(var, F, F, k, T)
    k <- k+1
    results[[k]] <- reg_helper(var, F, T, k, T) 
    
    if(!str_detect(var, "ln_apl|ln_emp")){
      k <- k+1
      results[[k]] <- reg_helper(var, T, F, k, F)
      k <- k+1
      results[[k]] <- reg_helper(var, T, T, k, F)
    }
    
  }
  
  write_csv(bind_rows(results), paste0("results_analysis/tbl2-origin_destination/tbl2-", filename, ".csv"))
  write_csv(bind_rows(MEANS), paste0("results_analysis/tbl2-origin_destination/means-", filename, ".csv"))
  
  return(0)
  
}

library(parallel)
cl <- makeCluster(3)

starting_id <- 30000
all_samples <- outer(
  c("le5_panelsize0","panelpanSIZE2"), #"le5_panelsize10", "panelpanSIZE3"
  c("-fixed_all", "-fixed_wpanel"), 
  paste0
) |> as.vector() |> sort()

filename_k <- mapply(c, all_samples, seq(starting_id, starting_id + 200*(length(all_samples)-1), 200), SIMPLIFY = FALSE, USE.NAMES = FALSE)


parLapplyLB(cl, filename_k, reg_sample)
