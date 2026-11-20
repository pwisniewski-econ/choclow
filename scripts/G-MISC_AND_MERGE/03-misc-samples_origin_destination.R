library(tidyverse)
library(arrow)
library(haven)
library(data.table)

col2keep <- c(
  "siren","naf2d_num_main", "max_year", "min_year", "year_cre",
  "ln_lshare_mean_0215","ln_va_mean_0215", "ln_emp_mean_0215", "ln_apl_mean_0215",
  "prod_res_mean_0215", "fe0215_god2","fe0215_mlo_le", "fe0215_mlo","fe0215_le"
)


get_origins <- function(filename, FIRM_DATA, outname, filt = FALSE){
  
  SAMPLE <- open_dataset(paste0("results_building/main_samples/", filename, ".parquet"))
  
  ORIGIN <- SAMPLE |> 
    filter(dist==-1&`T`==1) |> 
    select(sir, an_cl) |>
    mutate(origin = TRUE) |>
    collect() |>
    group_by(sir) |>
    filter(an_cl==min(an_cl)&!is.na(sir)) |>
    unique()
  
  DESTINATION <- SAMPLE |> 
    filter(dist%in%c(4,5)&`T`==1) |> 
    select(sir) |>
    mutate(destination = TRUE) |>
    collect() |>
    remove_missing() |>
    unique()
  
  FIRM_DATA |>
    left_join(ORIGIN, by = c("sir")) |>
    left_join(DESTINATION, by = c("sir")) |>
    mutate(across(c(origin, destination), ~if_else(is.na(.x), FALSE, .x))) |>
    filter(if(filt){an<an_cl|!origin}else{!filt})|>
    write_parquet(sink = paste0("results_building/origin_destination/", filename, "-", outname, ".parquet"), compression = "zstd")
  
  return(0)
  
}

all_samples <- c("le5_panelsize0", "le5_panelsize10", "panelpanSIZE2", "panelpanSIZE1")

FIRM_OUTCOMES_FIXED <- setDT(read_dta("data/interim/firm_outcomes/firm_siren_avg_fixed.dta", col_select = col2keep)) 
#WARNING: Using an external vector in selections was deprecated in tidyselect 1.1.0. (it's from the haven package - careful in the future)
FIRM_OUTCOMES_FIXED <- FIRM_OUTCOMES_FIXED[FIRM_OUTCOMES_FIXED[, rowSums(is.na(.SD))==0, .SDcols = c("fe0215_mlo_le", "ln_apl_mean_0215", "prod_res_mean_0215")]]
FIRM_OUTCOMES_FIXED[, c("minmax_year", "min_year", "max_year") := list(paste0(min_year, max_year), NULL, NULL)]
setnames(FIRM_OUTCOMES_FIXED, "siren", "sir")
FIRM_OUTCOMES_FIXED[,  year_cre := fifelse(year_cre>1800&year_cre<2025, year_cre, NA_real_)]

lapply(all_samples, get_origins, FIRM_OUTCOMES_FIXED, "fixed_all")

FIRM_OUTCOMES_PANEL <- setDT(read_dta("data/interim/panel_outcomes/firm_dads.dta"))
ISIN_PANEL <- unique(FIRM_OUTCOMES_PANEL[, .(sir)])

FIRM_OUTCOMES_FIXED <- FIRM_OUTCOMES_FIXED[ISIN_PANEL, on = "sir", nomatch=NULL]

lapply(all_samples, get_origins, FIRM_OUTCOMES_FIXED, "fixed_wpanel")

FIRM_OUTCOMES_FIXED <- FIRM_OUTCOMES_FIXED[, .(sir, fe0215_god2, fe0215_mlo_le, fe0215_mlo, fe0215_le, year_cre)]

moving_outcomes <- c("siren","year","ln_lshare_ma3","ln_va_ma3","ln_emp_ma3","ln_apl_ma3","prod_res_ma3","tfp_cd_ma3","tfp_tl_ma3","naf2d_ma3")
FIRM_OUTCOMES_MOVING <- setDT(read_dta("data/interim/firm_outcomes/firm_siren_avg_moving.dta", col_select = moving_outcomes))

setnames(FIRM_OUTCOMES_MOVING, c("siren", "year"), c("sir", "an"))

FIRM_OUTCOMES_MOVING <- FIRM_OUTCOMES_FIXED[FIRM_OUTCOMES_MOVING, on = "sir", nomatch=NULL]
FIRM_OUTCOMES_MOVING <- FIRM_OUTCOMES_MOVING[FIRM_OUTCOMES_PANEL, on = c("sir", "an"), nomatch = NULL]
FIRM_OUTCOMES_MOVING <- FIRM_OUTCOMES_MOVING[FIRM_OUTCOMES_MOVING[, rowSums(is.na(.SD))==0, .SDcols = c("fe0215_mlo_le", "ln_apl_ma3", "prod_res_ma3")]]
FIRM_OUTCOMES_MOVING[, age_firm := an - year_cre]

lapply(all_samples, get_origins, FIRM_OUTCOMES_MOVING, "moving_wpanel")
lapply(all_samples, get_origins, FIRM_OUTCOMES_MOVING, "moving_wpanel_pre", filt = TRUE)


