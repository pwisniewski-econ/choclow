library(tidyverse)
library(haven)
library(arrow)
library(data.table)
setDTthreads(3)

library(lfe)
library(fixest)
setFixest_nthreads(3)

get_fhdads <- function(year_var){
  
  print(year_var)
  
  path <-paste0("data/external/fhdads/fhdads_",year_var,".dta") 
  
  DADS_FH <- read_dta(
    path, 
    col_select = c("idfhda", "sir", "sbr", "nbheur")
  ) |>
    setDT()
  
  DADS_FH[, c("siren", "sir") := list(as.numeric(sir), NULL)]
  
  DADS_FH <- DADS_FH[!is.na(siren)&nbheur>0&sbr>0]
  
  DADS_FH <- DADS_FH[order(-sbr), .SD[1], by=.(idfhda)]
  
  return(DADS_FH[, year := year_var])
}

DADS_FH <- lapply(2002:2012, get_fhdads) |>
  rbindlist()

DADS_FH[, .(siren, year, idfhda)] |>
  write_parquet(sink = "data/_tmp/siren_workers.parquet.tmp", compression = "zstd")

DADS_FH[, "lw" := log(sbr/nbheur)]
DADS_FH <- DADS_FH[!is.na(lw)]

setkey(DADS_FH, idfhda, year)

DADS_FH[, siren.l1 := fifelse(
  year == shift(year)+1 & idfhda == shift(idfhda), shift(siren, 1), siren
)]

DADS_FH[is.na(siren.l1), siren.l1:=siren] 

LE_ALL <-  read_dta("./data/interim/lic_eco/le2_lastjob.dta")
FILT <- LE_ALL |> select(idfhda, and) |> mutate(filt=1) |> unique() |> setDT()

DADS_FH <- FILT[DADS_FH, on = .(idfhda)]
DADS_FH <- DADS_FH[is.na(filt)|and>year]

cf <- DADS_FH[, compfactor(list(factor(siren), factor(siren.l1)))]
DADS_FH <- DADS_FH[cf == 1]
rm(cf)
  
# COMPUTING AKM----

est <- feols(fml = lw ~ 0 | siren + idfhda + year, data = DADS_FH)
rm(DADS_FH)

fhdads_fe <- fixef(est)

FIRM_FE <- data.table(siren=as.numeric(names(fhdads_fe$siren)), firm_fe=fhdads_fe$siren)
write_parquet(FIRM_FE, "data/interim/akm_fe/fhdads-firm.parquet", compression = "zstd", compression_level = 5)

IND_FE <- data.table(fhdads=names(fhdads_fe$idfhda), fhdads_fe=fhdads_fe$idfhda)
write_parquet(IND_FE, "data/interim/akm_fe/fhdads-ind.parquet", compression = "zstd", compression_level = 5)

