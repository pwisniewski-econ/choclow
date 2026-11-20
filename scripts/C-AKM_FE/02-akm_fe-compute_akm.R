#DESCRIPTION: CREATES DATASETS FOR AKM FIXED EFFECT ESTIMATION
#             REMOVING POST-TREATMENT MLO30 *AND* LE OBSERVATIONS

#INPUT:   - GODECHOT PANEL DATA (dads`year`.dta) (for now just movers)
#         - LE AFFECTED INDIVIDUALS
#         - MLO AFFECTED INDIVIDUALS

#OUTPUT:  - AKM PANEL POST-MLO INDIVIDUALS FREE
#         - AKM PANEL POST-LE INDIVIDUALS FREE
#         - AKM PANEL POST-(MLO OR LE) FIRMS FREE


# PART I: PREPARE AND CLEAN DATA FOR AKM ESTIMATION

## DEFINE HELPER FUNCTION ----

import_movers <- function(){
  
  library(data.table)
  setDTthreads(3)
  library(tidyverse)
  library(haven)
  library(arrow)
  
  get_filters <- function(MOVERS_DATA, EVENTS_DATA, col_name){
    
    FILT <- EVENTS_DATA[MOVERS_DATA, on = .(siren, year)]
    
    FILT <- FILT[year==year_event&siren!=shift(siren, -1), .(ident_s, year_event)]
    #You could have that the next observation is a different individual in the same 
    #SIREN. This is fine, because this means that the event affected worker 
    #disappeared from the sample post event and will not affect our AKM estimation
    
    FILT <- FILT[, .(year_event = min(year_event)), by = .(ident_s)]
    #For the very unlucky workers that happen to live through multiple events  
    
    setnames(FILT, "year_event", col_name)
    
    return(FILT)
    
  }
  
  LE_EVENTS <- read_dta("data/interim/lic_eco/le2_alljobs.dta") |>
    select(siren = sir, year = and) |> 
    unique() |>
    mutate(year_event = year, siren = as.numeric(siren)) |> 
    remove_missing() |>
    setDT()
  
  MLO30_L51_IND <- read_dta("data/interim/mlo30/treatedpan.dta") |>
    select(siren = sir_cl, year = year_cl) |> 
    unique() |>
    mutate(year_event = year) |>
    setDT()
  
  MOVERS <- fread("data/interim/akm_fe/all_movers_2002_2018.csv", select = c(1,3,5:8))
  MOVERS <- MOVERS[year<2016]
  setnames(MOVERS, "ident_all", "ident_s")
  
  MOVERS[, c("lw", "siren") := list(log(hw), as.numeric(siren))]
  MOVERS <- MOVERS[!is.na(lw)&!is.na(siren)]
  
  setkey(MOVERS, ident_s, year)
  
  MOVERS[, siren.l1 := fifelse(
    year == shift(year)+1 & ident_s == shift(ident_s), shift(siren, 1), siren
  )]
  
  MOVERS[is.na(siren.l1), siren.l1:=siren] 
  #fifelse evaluate first row as NA
  
  FILT_MLO <- get_filters(MOVERS, MLO30_L51_IND, "year_mlo30")
  FILT_LE <- get_filters(MOVERS, LE_EVENTS, "year_le")
  
  MOVERS <- FILT_MLO[MOVERS, on = .(ident_s)]
  MOVERS[year>year_mlo30, filt_mlo30 := 1]
  MOVERS[is.na(filt_mlo30), filt_mlo30 := 0]
  rm(FILT_MLO, MLO30_L51_IND)
  
  MOVERS <- FILT_LE[MOVERS, on = .(ident_s)]
  MOVERS[year>year_le, filt_le := 1]
  MOVERS[is.na(filt_le), filt_le := 0]
  rm(FILT_LE, LE_EVENTS)
  
  gc()
  
  write_parquet(MOVERS, "data/_tmp/movers_filt.parquet", compression = "zstd", compression_level = 5)
  
  return(0)
  
}

## RUN PIPELINE IN NEW SESSION ----
callr::r(func = import_movers)

# PART II: COMPUTE AK FIXED EFFECTS ON DIFFERENT SAMPLES

## DEFINE HELPER FUNCTION ---- 

godechot_fe <- function(filt_expr, filename){
  
  library(data.table)
  setDTthreads(3)
  library(tidyverse)
  library(arrow)
  library(lfe)
  library(fixest)
  setFixest_nthreads(1)
  
  logmessage <- function(message){
    cat(paste0(Sys.time(), " - ", message, "\n"), file = "log.txt", append = T)
  }
  
  path <- paste0("data/interim/akm_fe/godechot-", filename, ".parquet")

  paste0("Starting work on ", filename, " ------------") |> logmessage()
  
  DATA <- open_dataset("data/_tmp/movers_filt.parquet") |> 
    filter(!!filt_expr) |>
    collect() |>
    setDT()
  
  paste0("Data imported with ", nrow(DATA), " rows. Computing connected set") |>
    logmessage()
  
  cf <- DATA[, compfactor(list(factor(siren), factor(siren.l1)))]
  DATA <- DATA[cf == 1]
  
  logmessage("Running regression")
  
  est <- feols(fml = lw ~ 0 | siren + ident_s + year, data = DATA)
  rm(DATA)
  gc()
  
  logmessage("Estimating Fixed-Effects")

  f0 <- fixef(est)$siren
  rm(est)
  gc()
  
  logmessage("Writing to disk")
  
  RESULTS <- data.table(siren=as.numeric(names(f0)), firm_fe = f0)
  
  write_parquet(RESULTS, path, compression = "zstd", compression_level = 12)
  
  return(0)
  
}

## ESTIMATE ON DIFFERENT SUBSETS ----
callr::r(godechot_fe, args = list(rlang::expr(filt_mlo30==0), "fe0215_mlo"))
callr::r(godechot_fe, args = list(rlang::expr(filt_le==0), "fe0215_le"))
callr::r(godechot_fe, args = list(rlang::expr(filt_mlo30==0&filt_le==0), "fe0215_mlo_le"))
callr::r(godechot_fe, args = list(rlang::expr(arrow::Expression$scalar(TRUE)), "fe0215_god2"))

callr::r(godechot_fe, args = list(rlang::expr(filt_mlo30==0&filt_le==0&year%in%2002:2005), "fe0205_mlo_le"))
callr::r(godechot_fe, args = list(rlang::expr(filt_mlo30==0&filt_le==0&year%in%2002:2010), "fe0210_mlo_le"))
callr::r(godechot_fe, args = list(rlang::expr(filt_mlo30==0&filt_le==0&year%in%2005:2010), "fe0510_mlo_le"))
callr::r(godechot_fe, args = list(rlang::expr(filt_mlo30==0&filt_le==0&year%in%2005:2015), "fe0515_mlo_le"))
callr::r(godechot_fe, args = list(rlang::expr(filt_mlo30==0&filt_le==0&year%in%2010:2015), "fe1015_mlo_le"))

file.remove("data/_tmp/movers_filt.parquet")
