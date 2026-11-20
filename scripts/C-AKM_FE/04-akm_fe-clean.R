#DESCRIPTION: CONSOLIDATE ALL ESTIMATED AKMs

#INPUT:   - AKM POSTES POST-MLO RAW
#         - AKM POSTES POST-MLO CORRECTED
#         - AKM POSTES POST-LE CORRECTED
#         - AKM POSTES POST-(MLO OR LE) CORRECTED
#         - AKM PANEL POST-LE INDIVIDUALS CORRECTED
#         - AKM PANEL POST-(MLO OR LE) CORRECTED

#OUTPUT:  - PANEL OF ALL FIXED EFFECTS

library(tidyverse)
library(arrow)
library(data.table)

akm_files <- list.files("data/interim/akm_fe", full.names = TRUE)

## FIRM LEVEL PREMIA ----
firm_akms <- akm_files[str_detect(akm_files, "godechot-fe|fhdads-firm")&str_detect(akm_files, ".parquet")]

import_akm <- function(path){
  spec_name <- path |> 
    str_extract("(?<=akm_fe/)[^.]+(?=\\.)") |> 
    str_remove("godechot-")
  
  read_parquet(path) |>
    rename({{spec_name}} := "firm_fe")
} 

ALL_SPECS <- import_akm(firm_akms[1])

for(spec in firm_akms[-1]){
  ALL_SPECS <- import_akm(spec) |>
    full_join(ALL_SPECS, by = "siren") 
}

## SIREN AVERAGE WORKER PREMIA ----
all_workers <- open_dataset("data/_tmp/siren_workers.parquet.tmp")
ind_akm <- open_dataset(akm_files[str_detect(akm_files, "fhdads-ind")]) 

SIREN_INDFE <- all_workers |>
  inner_join(ind_akm, by = c("idfhda"="fhdads")) |>
  group_by(siren) |>
  summarise(fe0212_idfhda= mean(fhdads_fe, na.rm=T)) |> 
  collect()

ALL_SPECS <- ALL_SPECS |>
  full_join(SIREN_INDFE, by = "siren") |> 
  rename("fe0212_siren" = "fhdads-firm") 

data.table::fwrite(ALL_SPECS, "data/interim/akm_fe/ffe_firm_0215_godechot.csv")

SIREN_INDFE_MA3 <- all_workers |>
  inner_join(ind_akm, by = c("idfhda"="fhdads")) |>
  group_by(siren, year) |>
  summarise(fe0212_year= mean(fhdads_fe, na.rm=T)) |> 
  collect() 

SIREN_INDFE_MA3 <- setDT(SIREN_INDFE_MA3)[order(siren, year)]
SIREN_INDFE_MA3[, "fe_l1" := fifelse(shift(year, type = "lag")+1==year & shift(siren, type = "lag")==siren, shift(fe0212_year, type = "lag"), NA_real_)]
SIREN_INDFE_MA3[, "fe_f1" := fifelse(shift(year, type = "lead")-1==year & shift(siren, type = "lead")==siren, shift(fe0212_year, type = "lead"), NA_real_)]
SIREN_INDFE_MA3 <- SIREN_INDFE_MA3[, .(siren, year, fe0212_idfhda_ma3 = (fe_l1+fe0212_year+fe_f1)/3)]
SIREN_INDFE_MA3 <- SIREN_INDFE_MA3[!is.na(fe0212_idfhda_ma3)]

write_parquet(SIREN_INDFE_MA3, "data/interim/akm_fe/fh_akm_ma3.parquet", compression = "zstd")

file.remove("data/_tmp/siren_workers.parquet.tmp")
