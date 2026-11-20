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
    cat(paste0(cl, " | ", format(Sys.time(), "%Y/%m/%d: %H:%M:%S"), " | ", msg, "\n"), file = "logs/event_studies-elections_acco.log", append = T)
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
    
    if(str_detect(sample_name,"le5_panelsize20")){
      fixed_effects <- c("an")
    }else{
      fixed_effects <- c("id2", "an")
    }
    
    if(str_detect(yval, "0912")){
      possible_controls <- c("+ log(nbsa09_ent)")
      possible_bin <- c("+ nbsa09_ent_bins")
    }else{
      possible_controls <- c("+ log(nbsa0507_ent)")
      possible_bin <- c("nbsa0507_ent_bins")
    }
    
    if(more_info=="controls: log(nbsa_ent) + bins" & !is.na(more_info)){
      controls <- possible_controls
      fixed_effects <- c(fixed_effects, possible_bin)
    } else if(more_info=="controls: log(nbsa_ent)" & !is.na(more_info)){
      controls <- possible_controls
    } else {
      controls <- ""
      #DATA <- DATA[nbsa_ent>100]
    }
    
    model_fml <- as.formula(paste0(base_fml, controls, "|", paste0(fixed_effects, collapse = "+")))
    
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
  
  path <- paste0("results_building/elec_samples/", filename, ".parquet")
  
  regdata <- open_dataset(path) 
  
  firm_vars <- names(regdata)[str_detect(names(regdata), "_ma3")&!str_detect(names(regdata), "hhi_zecs1|q4")]
  fevars <- names(regdata)[str_detect(names(regdata), "fe02")&!str_detect(names(regdata), "q5")]
  acco_vars <- names(regdata)[str_detect(names(regdata), "07")&!str_detect(names(regdata), "nbsa")]
  elec_vars <- names(regdata)[str_detect(names(regdata), "09")&!str_detect(names(regdata), "nbsa")]
  employee_vars <- c("nbheur", "lnnbheur", "sbr", "lnsbr", "lnsbrhour", "employed") 
  added_vars <- c("age_firm", "year_cre")
  
  regression_vars <- unique(c(firm_vars, fevars, acco_vars, elec_vars, employee_vars, added_vars))
  heterogeneity_vars <- hetvars
  
  col_select <- c("id2", "idpair", "an", "T", "dist", "idcluster", regression_vars, heterogeneity_vars)
  
  regdata <- regdata |>
    select(all_of(col_select), starts_with("nbsa"))
  
  sample <- setNames(list(collect(regdata)), filename)
  
  results <- list()
  k <- 0
  
  for(i in 1:length(regression_vars)){
    
    var <- regression_vars[i]
    logs_fun(paste0(i, "/", length(regression_vars), " (", var, ")"), filename)
    
    k <- k+1
    results[[length(results)+1]] <- event_study(sample, var, reg_id = k + min_k)
    
    if(var%in%c(acco_vars, elec_vars)){
      
      k <- k+1
      results[[length(results)+1]] <- event_study(sample, var, reg_id = k + min_k, more_info = "controls: log(nbsa_ent)")
      
      k <- k+1
      results[[length(results)+1]] <- event_study(sample, var, reg_id = k + min_k, more_info = "controls: log(nbsa_ent) + bins")
      
      for(hvar in heterogeneity_vars){
        k <- k+1
        results[[length(results)+1]] <- event_study(sample, var, hvar, reg_id = k + min_k)
      }
      
    }
    

    
  }
  
  
  if(filename == "le5_panelsize0-election"){
    
    pre_event <- open_dataset(
      "results_building/main_samples/le5_panelsize0.parquet"
    ) |>
      filter(`T`==1, dist == -1, !is.na(sir_cl)) |>
      select(id2, idpair, idcluster, sir_cl, an, nbsa_ent)
    
    layoff_counts <- pre_event |>
      group_by(sir_cl, an) |>
      summarise(
        n_laid_off = n_distinct(idcluster), 
        .groups = "drop"
      )
    
    election_ids <- sample[[1]] |>
      filter(T==1)|>
      pull(id2) |>
      unique()
    
    pair_shares <- pre_event |>
      inner_join(layoff_counts, by = c("sir_cl", "an")) |>
      filter(id2 %in% election_ids, nbsa_ent>0) |>
      mutate(layoff_share = n_laid_off / nbsa_ent) |>
      filter(is.finite(layoff_share)) |>
      select(idpair, layoff_share) |>
      collect()
    
    cutoff <- quantile(pair_shares$layoff_share, 0.25, na.rm=TRUE)
    
    keep_pairs <- pair_shares |>
      filter(layoff_share <= cutoff) |>
      distinct(idpair)
    
    small_sample <- sample 
    small_sample[[1]] <- sample[[1]] |>
      semi_join(keep_pairs, by = "idpair")
    
    k <- k+1
    results[[length(results)+1]] <- event_study(
      small_sample, 
      "participation_siren0912", 
      reg_id=min_k+k, 
      more_info = paste0("sample: lowest quartile of layoff share, at cutoff", unname(cutoff))
    ) 
    
  }
  
  write_csv(bind_rows(results), paste0("results_analysis/event_studies-elec_samples/", filename, "-res.csv"))
  
  return(0)
  
}

library(parallel)
cl <- makeCluster(2)

starting_id <- 20000
all_samples <- stringr::str_remove(list.files("results_building/elec_samples/"), ".parquet")
filename_k <- mapply(c, all_samples, seq(starting_id, starting_id + 200*(length(all_samples)-1), 200), SIMPLIFY = FALSE, USE.NAMES = FALSE)

hetvars <- c("sx") #"hhi_zecs1_ma3_dlag4_q4", "age_cl_q4", "an_cl"  

parLapplyLB(cl, filename_k, main_helper, hetvars)
