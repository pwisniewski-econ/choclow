library(haven)
library(data.table)
library(arrow)

left_joinDT <- function(DT1, DT2, variables){
  
  check_unique <- function(DT, variables){
    if(nrow(DT[, .(cnt=.N), by = variables][cnt>1])>0) return(1)
    return(0)
  }
  
  if(check_unique(DT2, variables)!=0){stop("Keys may not be unique.")}
  DT2[DT1, on = variables]
}

import_merge <- function(path, FIRM_OUTCOMES_FIXED, FIRM_OUTCOMES_MOVING, FIRM_OUTCOMES_PANEL, ELECTIONS_PRO, ACCO_ENT, HHI, HHI_COMP_SIR){
  
  outfile <- stringr::str_replace(path, ".dta", ".parquet") |>
    stringr::str_remove(".*/")
  
  outpath <- paste0("results_building/main_samples/", outfile)
  
  DATASET <- setDT(read_dta(path))

  DATASET[, siren := fifelse(employed == 1, sir, NA_real_)]
  
  front_cols <- names(DATASET)
  
  #if(stringr::str_detect(path, "mlo")){
  #  DATASET <- DATASET[dist<9]
  #}else{
    DATASET <- DATASET[dist<7]
  #}

  DATASET <- DATASET[, cs1_cl := substr(cs2_cl, 1, 1)]
  
  DATASET <- DATASET |> left_joinDT(FIRM_OUTCOMES_FIXED, c("siren"))
  DATASET <- DATASET |> left_joinDT(FIRM_OUTCOMES_MOVING, c("siren", "an"))
  DATASET <- DATASET |> left_joinDT(FIRM_OUTCOMES_PANEL, c("siren", "an"))
  DATASET <- DATASET |> left_joinDT(ELECTIONS_PRO, c("siren"))
  DATASET <- DATASET |> left_joinDT(ACCO_ENT, c("siren"))
  
  #FIXED PRE-DISPLACEMENT WINDOW MOVING AVERAGE
  df_ma3_dlag4 <- function(DT){
    
    localDT <- copy(DT)
    localDT[, c("an_cl", "an") := list(an + 4, NULL)]
    
    old_names <- names(localDT)
    new_names <- stringr::str_replace(names(localDT), "_ma3", "_ma3_dlag4")
    setnames(localDT, old_names, new_names)
    
    return(localDT)
    
  }
  
  DATASET <- DATASET |> left_joinDT(df_ma3_dlag4(FIRM_OUTCOMES_MOVING), c("siren", "an_cl"))
  DATASET <- DATASET |> left_joinDT(df_ma3_dlag4(FIRM_OUTCOMES_PANEL), c("siren", "an_cl"))
  
  acco_cols <- names(DATASET)[stringr::str_ends(names(DATASET), "07")]
  alt_acco <- paste0(acco_cols, "_alt")
  
  DATASET[, (acco_cols) := lapply(.SD, \(x) fifelse(is.na(x) & isin_acco, 0, x)), .SDcols = acco_cols]
  DATASET[, (alt_acco) := lapply(.SD, \(x) fifelse(is.na(x) & year_cre<2008 & max_year>2004, 0, x)), .SDcols = acco_cols]
  DATASET[, (c(acco_cols, alt_acco)) := lapply(.SD, \(x) fifelse(an_cl > 2007, x, NA_real_)), .SDcols = c(acco_cols, alt_acco)]
  #& nbsa_ent>100
  DATASET <- DATASET |> left_joinDT(HHI, c("ze10_cl", "an_cl", "cs1_cl"))
  DATASET <- DATASET |> left_joinDT(HHI_COMP_SIR, c("siren", "ze10_cl", "an_cl", "cs1_cl"))
  
  
  #DATASET[, hhi_zecs1_ma3_dlag4_q4 := dplyr::ntile(hhi_zecs1_ma3_dlag4, 4), by = .(an_cl)]
  #DATASET[, age_cl_q4 := dplyr::ntile(age_cl, 4), by = .(an_cl)]
  DATASET[, year_cre := fifelse(year_cre>1800&year_cre<2025, year_cre, NA_real_)]
  DATASET[, age_firm := an - year_cre]
  
  #WINSOR
  cols <- c("sbrhour")

  DATASET[, (cols) := lapply(.SD, function(x) {
    q <- quantile(x, c(0.01, 0.99), na.rm=TRUE)
    pmax(q[1], pmin(x, q[2]))
  }), .SDcols = cols]

  DATASET[, "lnsbrhour" := fifelse(sbrhour>0, log(sbrhour), NA_real_)]

  setcolorder(DATASET, c(front_cols, setdiff(names(DATASET), front_cols)))
  
  write_parquet(DATASET, outpath, compression = "zstd")
  
  return(0)
}


### FIRM LEVEL FIRM OUTCOMES ---
FIRM_OUTCOMES_FIXED <- setDT(read_dta("data/interim/firm_outcomes/firm_siren_avg_fixed.dta"))

q5_cols <- c("fe0215_god2", "fe0215_mlo_le", "fe0215_mlo", "fe0215_le")
FIRM_OUTCOMES_FIXED[, (paste0(q5_cols, "_q5_full")) := lapply(.SD, \(x) dplyr::ntile(x, 5)), .SDcols = q5_cols]

### DYNAMIC FIRM OUTCOMES ----
FIRM_OUTCOMES_MOVING <- setDT(read_dta("data/interim/firm_outcomes/firm_siren_avg_moving.dta")) #, n_max = 10e3
INDFH_AKMS <- setDT(read_parquet("data/interim/akm_fe/fh_akm_ma3.parquet"))
FIRM_OUTCOMES_MOVING <- INDFH_AKMS[FIRM_OUTCOMES_MOVING, on = .(siren, year)]
rm(INDFH_AKMS)

setnames(FIRM_OUTCOMES_MOVING, "year", "an")


### DYNAMIC FIRM OUTCOMES FROM PANEL DADS ----
FIRM_OUTCOMES_PANEL <- setDT(read_dta("data/interim/panel_outcomes/firm_dads.dta")) #, n_max = 10e3
setnames(FIRM_OUTCOMES_PANEL, c("sir","an"), c("siren","an"))

### ELECTION DATA ----
ELECTIONS_PRO <- setDT(read_dta("data/interim/elections_pro/elections_siren_year_0912.dta"))
ELECTIONS_PRO <- ELECTIONS_PRO[, bnuls_siren0912 := fifelse(bnuls_siren0912 < 0, NA_real_, bnuls_siren0912)]

### ACCO DATA ----
ACCO_ENT <- setDT(read_dta("data/interim/acco_ent/accords0513.dta"))[, isin_acco := T] 

### HHI DATA ----
HHI <- setDT(read_dta("data/interim/panel_outcomes/hhi_zecs1.dta"))[, .(an_cl = an + 4, ze10_cl = ze10, cs1_cl = cs1, hhi_zecs1_ma3)]
setnames(HHI, "hhi_zecs1_ma3", "hhi_zecs1_ma3_dlag4")
#HHI[, hhi_zecs1_ma3_dlga4_q4_full := dplyr::ntile(hhi_zecs1_ma3_dlag4, 4), by = .(an_cl)]

HHI_COMP_SIR <- setDT(read_dta("data/interim/panel_outcomes/firm_hhi_dads.dta"))
HHI_COMP_SIR[, c("an_cl", "an") := list(an + 4,NULL)]
setnames(HHI_COMP_SIR, c("sir", "ze10", "cs1", "hhi_comp_sirze_eqtp_ma3", "hhi_comp_sirzecs1_ma3"), c("siren", "ze10_cl", "cs1_cl", "hhi_comp_sirze_eqtp_ma3_dlag4", "hhi_comp_sirzecs1_ma3_dlag4"))

### MERGE EVERYTHING ----
samples <- paste0("data/interim/", c(paste0("mlo30/panelpanSIZE",c(1,2),".dta"), paste0("lic_eco/le5_panelsize", c(0,10), ".dta")))

lapply(samples, import_merge, FIRM_OUTCOMES_FIXED, FIRM_OUTCOMES_MOVING, FIRM_OUTCOMES_PANEL, ELECTIONS_PRO, ACCO_ENT, HHI, HHI_COMP_SIR)

### ADDITIONNAL SAMPLES (ACCO, ACCO_ALT AND ELECTIONS) ----

main_samples <- c("le5_panelsize0", "panelpanSIZE2")

elec_samples <- function(filename){
  DATA <- setDT(read_parquet(paste0("results_building/main_samples/", filename, ".parquet")))
  colnames <- names(DATA)
  acco_cols <- colnames[stringr::str_detect(colnames, "_0507$")]
  acco_alt_cols <- colnames[stringr::str_detect(colnames, "_alt$")]
  elec_cols <- colnames[stringr::str_detect(colnames, "_09")]
  elec_path <- "results_building/elec_samples/"
  
  DATA[!is.na(siren), nbsa09_ent := mean(nbsa_ent[an == 2009], na.rm = TRUE), by = .(siren)]

  # Average reports within each firm-year, retaining their observed frequencies,
  # then give each observed year equal weight in the period means.
  DATA[!is.na(siren), nbsa_ent_year := mean(nbsa_ent, na.rm = TRUE), by = .(siren, an)]
  DATA[!is.na(siren), nbsa0507_ent := mean(unique(.SD[an %in% 2005:2007])$nbsa_ent_year, na.rm = TRUE), by = .(siren), .SDcols = c("an", "nbsa_ent_year")]
  DATA[!is.na(siren), nbsa_ent_mean := mean(unique(.SD[!is.na(an)])$nbsa_ent_year, na.rm = TRUE), by = .(siren), .SDcols = c("an", "nbsa_ent_year")]
  DATA[, nbsa_ent_year := NULL]
  
  DATA[, paste0(c("nbsa0507_ent", "nbsa09_ent"), "_bins") := lapply(.SD, \(x) fcase(
    x <= 10, "size1", 
    x <= 49, "size2", 
    x <= 299, "size3", 
    x > 299, "size4"
  )), .SDcols = c("nbsa0507_ent", "nbsa09_ent")]
  
  write_parquet(DATA[(!is.na(shinscrit_carence_siren0912)&nbsa09_ent>=1)|employed==0][, c(acco_cols, acco_alt_cols) := NULL], 
                paste0(elec_path, filename, "-election.parquet"), compression = "zstd")
  
  write_parquet(DATA[(!is.na(wage_agreement_ind_0507)&nbsa_ent_mean>=50)|employed==0][, c(acco_alt_cols, elec_cols) := NULL],
                paste0(elec_path, filename, "-acco_isin.parquet"), compression = "zstd")
  
  write_parquet(DATA[(!is.na(wage_agreement_ind_0507_alt)&nbsa_ent_mean>=50)|employed==0][, c(acco_cols, elec_cols) := NULL],
                paste0(elec_path, filename, "-acco_alt.parquet"), compression = "zstd")
  
  return(0)
}

lapply(main_samples, elec_samples)


