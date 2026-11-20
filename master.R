# MASTER FILE

# SETUP ------

casd_project <- "CHOCLOW"

# CHECK R PACKAGES ----
requirements <- c("tidyverse", "data.table", "haven", "here", "arrow", "lfe", "fixest", "callr", "Hmisc")
if(!all(as.logical(lapply(requirements, requireNamespace, quietly=TRUE)))){
  stop("Some required package is missing")
} 


# FUNCTION TO CALL STATA ----
run_stata <- function(dofile){
  
  stata <- "C:/Program Files/Stata17/StataMP-64.exe"
  
  logfile <- stringr::str_replace(dofile, ".do", ".log") |>
    stringr::str_remove(".*/")
  
  system2(stata, args = c("/e", "do", shQuote(here::here("scripts", dofile))))
  
  if (stringr::str_detect(readr::read_file(logfile), stringr::fixed("/*END OF DOFILE*/"))) {
    file.remove(logfile)
    return(paste0("STATA finished: ", dofile))
  } else {
    stop("STATA exited before completion : check logs")
  }
  
}

# FUNCTION TO CALL SAS ----

run_sas <- function(sas_script, parameters = NULL, project = casd_project){
  
  sas_path <- "C:/Program Files/SASHome/SASFoundation/9.4/sas.exe"
  project_root <- getwd()
  
  job_name <- tools::file_path_sans_ext(basename(sas_script))
  if(!is.null(parameters)) job_name <- paste0(job_name, "_", gsub(" ", "_", parameters))
  logfile <- file.path(project_root, "logs/casd_import", paste0(job_name, ".log"))
  dir.create("logs/casd_import", recursive = TRUE, showWarnings = FALSE)
  dir.create("data/_tmp/sas_work", recursive = TRUE, showWarnings = FALSE)
  
  exit_code <- system2(sas_path, args = c(
    "-sysin", shQuote(file.path(project_root, "scripts", sas_script)),
    "-sasinitialfolder", shQuote(project_root),
    "-log", shQuote(logfile),
    "-print", shQuote(file.path(project_root, "logs/casd_import", paste0(job_name, ".lst"))),
    "-work", shQuote(file.path(project_root, "data/_tmp/sas_work")),
    "-set", "CASD_PROJECT", shQuote(project),
    if(!is.null(parameters)) c("-sysparm", shQuote(parameters))
  ))
  
  if (exit_code == 0) {
    return(paste0("SAS finished: ", sas_script))
  } else {
    stop("SAS exited before completion : check ", logfile)
  }
}

# RUN PIPELINE ------

## PREPARE OUTPUT DIRECTORIES AND CHECK STATA PACKAGES ----
pipeline_folders <- c("data/_tmp", "logs",
                      "data/interim/mlo30/sirenzepic2", "data/interim/lic_eco",
                      "data/interim/akm_fe", "data/interim/firm_outcomes",
                      "data/interim/elections_pro", "data/interim/panel_outcomes",
                      "results_building/main_samples", "results_building/elec_samples",
                      "results_building/origin_destination",
                      "results_analysis/event_studies-main_samples",
                      "results_analysis/event_studies-elec_samples",
                      "results_analysis/fig_a7-binned_scatter",
                      "results_analysis/misc-descriptive_statistics",
                      "results_analysis/ref_answers-productivity",
                      "results_analysis/tbl_a6-corr_akm",
                      "results_analysis/tbl2-origin_destination")
for(folder in pipeline_folders) dir.create(folder, recursive = TRUE, showWarnings = FALSE)

run_stata("stata_helpers/check_dependencies.do")

## 00. CASD IMPORTS ----

### 00.1 CREATE IMPORT OUTPUT DIRECTORIES ----

import_folders <- c("data/_tmp/sas_etablissements", "data/_tmp/sas_flux",
                    "data/external/sas_etablissements", "data/external/sas_flux",
                    "data/external/fhdads", "data/external/sas_fhdads",
                    "data/external/sas_paneldads", "data/interim/acco_ent",
                    "data/external/godechot_dads/ctrl",
                    "data/external/godechot_dads/pseudo_id",
                    "data/external/godechot_dads/pseudo_id_seniority",
                    "data/external/godechot_dads/pseudo_id_foreign_born",
                    "data/external/godechot_dads/dads_out")
for(folder in import_folders) dir.create(folder, recursive = TRUE, showWarnings = FALSE)

### 00.2 COLLECTIVE AGREEMENTS AND DADS PANEL ----
#output:  data/interim/acco_ent/2005_2015.dta
#         data/external/sas_paneldads/<source member>.dta

run_sas("00-CASD_IMPORT/01-acco-import.sas")
run_sas("00-CASD_IMPORT/Export_Panel.sas")

### 00.3 ESTABLISHMENT COUNTS, HOURS AND FULL-TIME EQUIVALENTS ----
#output:  data/external/sas_etablissements/DADS1993..2015_{exh,nov}.dta

run_sas("00-CASD_IMPORT/compatibility/01_exp1993_exh.sas")
run_sas("00-CASD_IMPORT/compatibility/01_exp1993_nov.sas")
establishment_periods <- data.frame(first = c(1994, 2000, 2002, 2009, 2010, 2011, 2012, 2014),
                                    last = c(1999, 2001, 2008, 2009, 2010, 2011, 2013, 2015))
for(i in seq_len(nrow(establishment_periods))){
  for(mode in c("exh", "nov")){
    run_sas("00-CASD_IMPORT/02-import_establishments.sas",
            paste(establishment_periods$first[i], establishment_periods$last[i], mode))
  }
}

### 00.4 WORKER FLOWS ----
#output:  data/external/sas_flux/DADS2002..2015_pic.dta

flow_periods <- data.frame(first = c(2002, 2009, 2010, 2011, 2012, 2014),
                            last = c(2008, 2009, 2010, 2011, 2013, 2015))
for(i in seq_len(nrow(flow_periods))){
  run_sas("00-CASD_IMPORT/03-import_flows.sas",
          paste(flow_periods$first[i], flow_periods$last[i]))
}

### 00.5 FH-DADS FULL EXPORTS AND ANALYSIS EXTRACTS ----
#output:  data/external/fhdads/fhdads_19962001.dta, fhdads_2002..2012.dta
#         data/external/sas_fhdads/fhdads_{inf2002,sup2002}.dta, fh_de.dta,
#         extra_fhdads_{inf2002,sup2002}.dta

run_sas("00-CASD_IMPORT/importing_fh.sas")
for(extract in c("matching", "de", "extra")){
  run_sas("00-CASD_IMPORT/04-import_fh_extracts.sas", extract)
}

### 00.6 COMPRESS AND LOWERCASE THE FH-DADS EXPORTS ----

run_stata("00-CASD_IMPORT/compress_dta.do")

### 00.7 GODECHOT IDENTIFIERS AND ANALYSIS FILES ----

run_sas("00-CASD_IMPORT/godechot/pseudo_id.sas")
run_sas("00-CASD_IMPORT/godechot/pseudo_id_use.sas")

## A. MASS LAYOFFS EVENTS ----

### A.1. CREATE TEMPORARY PANEL OF ALL SIRETS (END OF YEAR) ----
#input:   DADS`i'_nov.dta (from SAS)
#output:  temp_AllSiret_$sample.dta

run_stata("A-MLO30/01-mlo30-import_dads.do")

### A.2. COMPUTE FULL TIME EQUIVALENTS FOR ALL SIRETS (FULL YEAR) ----
#input:   DADS`i'_exh.dta (from SAS)
#output:  temp_ETP.dta

run_stata("A-MLO30/02-mlo30-import_dads_eqtp.do")

### A.3. ADD ZE TO PANELS AND DETECT MLO EVENTS ----
#input:   temp_AllSiret_$sample.dta
#         temp_ETP.dta
#         01_AUZE_Commune.dta (from 'shared')
#output:  sirenze_panel.dta
#         sirenze_events_mlo30.dta
          
run_stata("A-MLO30/03-mlo30-dads_cleaning.do")
file.remove(paste0("data/interim/mlo30/", c("temp_ETP.dta", "temp_AllSiret_100.dta")))


### A.4. CREATE WORKER FLOW DATA ----
#input:   DADS`y'_pic.dta (from SAS, flux)
#         01_AUZE_Commune.dta ('from shared')
#output:  sirenzepic2_`y'.dta

run_stata("A-MLO30/04-mlo30-picart_flows.do")


### A.5. VALIDATE MLO AGAINST WORKER FLOWS (TO AVOID ADMIN CHANGES) ----
#input:   sirenze_events_mlo30.dta
#         sirenzepic2_`y'.dta
#output:  events_corr.dta
#         events_fh.dta

run_stata("A-MLO30/05-mlo30-picart_mlo.do")

### A.6. CREATE SIREN*ZE PANEL FOR POTENTIAL CONTROLS  ----
#input:   DADS`i'_exh.dta (from SAS)
#         01_AUZE_Commune.dta ('from shared')
#output:  sirenze_ctrl

run_stata("A-MLO30/06-mlo30-control_firms_panel.do")

### A.7. COMPUTE TENURE RESTRICTIONS FROM PANEL-DADS----
#input:   PAN17_`i'(from SAS)
#output:  mlo30_tenure.dta

run_stata("A-MLO30/07-mlo30-tenure_computation.do")

### A.8. CREATE PANEL OF WORKERS' MAIN JOBS FROM PANEL-DADS----
#input:   PAN17_`i'(from SAS)
#         01_AUZE_Commune.dta ('from shared')
#output:  pansmall_main.dta

run_stata("A-MLO30/08-mlo30-workers_panel.do")

### A.9. MERGE ENTRY AND EXIT DATES WITH DADS PANEL ----
#input:   PAN17_`i'(from SAS)
#         01_AUZE_Commune.dta ('from shared')
#         mlo30_tenure.dta
#output:  pan_min.dta

run_stata("A-MLO30/09-mlo30-panel_min.do")

### A.10. CREATE PANEL OF DISPLACED WORKERS ----
#input:   events_fh.dta
#         pansmall_main.dta
#         pan_min.dta
#         naf2003_naf2008.dta
#output:  treatedpan.dta

run_stata("A-MLO30/10-mlo30-disp_sample.do")

### A.11. FIND POTENTIAL CONTROLS ----
#input:   PAN17_`i'(from SAS)
#         pan_min.dta
#         sirenze.dta
#         naf2003_naf2008.dta
#         01_AUZE_Commune.dta
#output:  ctrpoolpan.dta

run_stata("A-MLO30/11-mlo30-control_group.do")
file.remove(list.files("data/interim/mlo30/", full.names = TRUE)[stringr::str_detect(list.files("data/interim/mlo30/"), "^ctrpool_pan_")])
  
### A.12. MATCHING ON T-2 AND T-3 OUTCOMES ----
#input:   treatedpan.dta
#         ctrpoolpan.dta
#output:  disppan_matchSIZE2.dta

run_stata("A-MLO30/12-mlo30-matching.do")

### A.13. RECOVER DATA ON ALL YEARS FOR MLO WORKERS ----
#input:   treatedpan.dta
#         ctrpoolpan.dta
#output:  panelpanSIZE2.dta

run_stata("A-MLO30/13-mlo30-panel_displaced.do")

## B. LICENCIEMENTS ECONOMIQUES ----

### B.1. COMPUTE TENURE LENGTHS FOR WORKERS  ----
#input:   de.dta
#         di.dta
#output:  le1_dedi.dta

run_stata("B-LIC_ECO/01-lic_eco-tenure_computation.do")

### B.1. IDENTIFY LE AND MATCH WITH POLE EMPLOI ----
#input:   de.dta
#         di.dta
#output:  le1_dedi.dta

run_stata("B-LIC_ECO/02-lic_eco-di_de.do")

### B.2. MATCH LE WITH DADS ----
#input:   le1_dedi.dta
#         dads_sup2002_`i'.dta (SAS DADS-PANEL)
#output:  le2_lastjob.dta

run_stata("B-LIC_ECO/03-lic_eco-dads.do")

### B.3. CREATE FULL TREATED PANEL ----
#input:   le2_lastjob.dta
#         dads_sup2002_`i'.dta (SAS DADS-PANEL)
#         01_AUZE_Commune.dta
#         sirenze_panel.dta
#         naf2003_naf2008.dta
#output:  le3_treated_dads.dta

run_stata("B-LIC_ECO/04-lic_eco-treated_panel.do")

### B.4. IMPORT FHDADS FOR POTENTIAL CONTROLS ----
#input:   fhdads_inf2002.dta
#         fhdads_sup2002.dta
#output:  03_tmp_fh.dta

run_stata("B-LIC_ECO/05-lic_eco-control_panel.do")

### B.5. CREATE PANEL OF CONTROL WORKERS ----
#input:   dads_sup2002_`i'.dta (SAS DADS-PANEL)
#         03_tmp_fh.dta
#         01_AUZE_Commune.dta
#         sirenze_full.dta 
#         naf2003_naf2008.dta
#output:  ctrpool.dta

run_stata("B-LIC_ECO/06-lic_eco-control_group.do")
file.remove(list.files("data/interim/lic_eco/", full.names = TRUE)[stringr::str_detect(list.files("data/interim/lic_eco/"), "^ctrpool_\\d")])

### B.6. MATCHING ON T-2 AND T-3 OUTCOMES ----
#input:   le3_treated_dads.dta
#         ctrpool.dta
#output:  le4_matchsize.dta 

run_stata("B-LIC_ECO/07-lic_eco-matching.do")

### B.7. BUILD PANEL FROM MATCHED DATA ----
#input:   le4_matchsize.dta
#         dads_sup2002_`i'.dta (SAS DADS-PANEL)
#         01_AUZE_Commune.dta
#         naf2003_naf2008.dta
#output:  le5_panelsize.dta

run_stata("B-LIC_ECO/08-lic_eco-clean_postmatch.do")

## C. AKM FIXED EFFECTS ----

### C.1. GET ONLY DADS-GODECHOT MOVERS ----
#input:   
#output:  

run_stata("C-AKM_FE/01-akm_fe-movers_only.do")

### C.2. COMPUTE AKM FE ON GODECHOT ----
#input:   
#output:  

callr::rscript("scripts/C-AKM_FE/02-akm_fe-compute_akm.R")

### C.3. COMPUTE AKM FE ON PANEL DADS (LE) ----
#input:   
#output:  

callr::rscript("scripts/C-AKM_FE/03-akm_fe-panel_dads.R")

### C.4. COMPUTE AKM FE ON PANEL DADS (LE) ----
#input:   
#output:  

callr::rscript("scripts/C-AKM_FE/04-akm_fe-clean.R")

## D. FIRM LEVEL OUTCOMES ----

### D.1. CONVERT GRASSI'S PARQUET TO CSV ----
#input:   ficusfare_profil_wof_19942019_v0222.parquet
#output:  ficusfare_profil_wof_19992015_v0222_light.csv

callr::rscript("scripts/D-FIRM_OUTCOMES/01-firm_outcomes-grassi2csv.R")

### D.2. CONVERT GRASSI'S CSV TO DTA ----
#input:   ficusfare_profil_wof_19992015_v0222_light.csv
#output:  ficusfare_profil_wof_19992015_v0222_light.dta

run_stata("D-FIRM_OUTCOMES/02-firm_outcomes-export_basic_dataset.do")

### D.3. CREATE CLEAN FIRM PANEL FOR ANALYSIS ----
#input:   ficusfare_profil_wof_19992015_v0222_light.dta
#output:  01_ficusfare_base_1999_2015.dta

run_stata("D-FIRM_OUTCOMES/03-build_base_ficusfare_panel.do")

### D.4. COMPUTE PRODUCTIVITY AS REG RESIDUAL ----
#input:   01_ficusfare_base_1999_2015.dta
#output:  N_naf2_coef.dta
#         naf2_`s'_coef.dta
#         02_ficusfare_with_prodres_1999_2015.dta

run_stata("D-FIRM_OUTCOMES/04-firm_outcomes-compute_prodres.do")

### D.5. PRODUCTION FUNCTION ESTIMATES ----
#input:   01_ficusfare_base_1999_2015.dta
#output:  03_dgm_coefficients_byind_revenue.dta

run_stata("D-FIRM_OUTCOMES/05-firm_outcomes-estimate_pf_coefficients_dgm_revenue.do")

### D.6. MARKUPS AND TFP ESTIMATION ----
#input:   01_ficusfare_base_1999_2015.dta
#         03_dgm_coefficients_byind_revenue.dta
#output:  04_ficusfare_with_markup_tfp_1999_2015.dta

run_stata("D-FIRM_OUTCOMES/06-firm_outcomes-compute_markup_tfp.do")

### D.7. CLEAN AND EXPORT FINAL PANEL ----
#input:   01_ficusfare_base_1999_2015.dta
#         02_ficusfare_with_prodres_1999_2015
#         03_dgm_coefficients_byind_revenue.dta
#output:  04_ficusfare_with_markup_tfp_1999_2015.dta

run_stata("D-FIRM_OUTCOMES/07-firm_outcomes-build_final_panels.do")

## E. FIRM LEVEL AGREEMENTS ----

### E.32 CONVERT CASD DATA TO STATA ----
#input:   2005_2015.dta 
#output:  accords0513.dta

run_stata("E-ACCO_ENT/01-acco-stata_clean.do")

## F. PRO ELECTIONS ----

run_stata("F-ELECTIONS/01-elections-import_clean.do")

## G. FINAL DATASET CONSTRUCTION ----

### G.1 GET FIRM LEVEL DADS OUTCOMES ----

run_stata("G-MISC_AND_MERGE/01-misc-dads_outcomes_firm.do")

### G.2 MERGE MAIN DATASETS ----

callr::rscript("scripts/G-MISC_AND_MERGE/02-misc-merge_clean.R")

### G.3 ORIGIN/DESTINATION DATASET ----

callr::rscript("scripts/G-MISC_AND_MERGE/03-misc-samples_origin_destination.R")

### G.4 SECTOR DESCRIPTION FOR FHDADS ----

run_stata("G-MISC_AND_MERGE/04-misc-fh_descriptives.do")

### G.5 OTHER DSCRIPTIVES DATASET FOR FHDADS ----

run_stata("G-MISC_AND_MERGE/05-misc-dads_descriptives.do")

## H. ANALYSIS ----

### H.1 MAIN EVENT STUDIES ----

callr::rscript("scripts/H-ANALYSIS/01-analysis-event_studies.R")

### H.2 ELECTION AND ACCO EVENT STUDIES ----

callr::rscript("scripts/H-ANALYSIS/02-analysis-event_study_elections_acco.R")

### H.3 ORIGIN/DESTINATION FIRM COMPARISON ----

callr::rscript("scripts/H-ANALYSIS/03-analysis-origin_destination.R")

### H.4 BINNED SCATTER PLOTS ----

callr::rscript("scripts/H-ANALYSIS/04-analysis-binned_plot.R")

### H.5 PRODUCTIVITY ANALYSIS PRE/POST EVENT ----

callr::rscript("scripts/H-ANALYSIS/05-analysis-prod_analysis.R")

### H.6 AKM QUANTILES ----

callr::rscript("scripts/H-ANALYSIS/06-analysis-quantiles_desc.R")

### H.7 BROAD DESCRIPTIVE STATISTICS ----

callr::rscript("scripts/H-ANALYSIS/07-analysis-stat_desc.R")

### H.8 PREMIUM CORRELATIONS ----

callr::rscript("scripts/H-ANALYSIS/08-analysis-tbl_a6.R")

## I. PLOTS AND TABLES ----

#input:   results_analysis CSV exports
#output:  results_paper/figures/<script>/ (PDF)
#         results_paper/tables/<script>/ (LaTeX)
#         results_paper/build/ (build records)

### I.1 LOAD DATA AND SHARED PLOTTING FUNCTIONS ----
source("scripts/I-PLOTS_AND_TABLES/00_shared.R", encoding = "UTF-8")

### I.2 EVENT-STUDY FIGURES ----
source("scripts/I-PLOTS_AND_TABLES/01_event_figures.R", encoding = "UTF-8")

### I.3 DESCRIPTIVE FIGURES ----
source("scripts/I-PLOTS_AND_TABLES/02_descriptive_figures.R", encoding = "UTF-8")

### I.4 AKM ESTIMATION-WINDOW FIGURE ----
source("scripts/I-PLOTS_AND_TABLES/03_akm_periods.R", encoding = "UTF-8")

### I.5 TABLES ----
source("scripts/I-PLOTS_AND_TABLES/04_tables.R", encoding = "UTF-8")

### I.6 FIRM-DISPERSION TABLE ----
source("scripts/I-PLOTS_AND_TABLES/05_firm_dispersion.R", encoding = "UTF-8")

### I.7 BUILD RECORDS ----
source("scripts/I-PLOTS_AND_TABLES/06_build_report.R", encoding = "UTF-8")


