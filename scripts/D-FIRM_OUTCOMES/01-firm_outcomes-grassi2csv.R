library(arrow)
library(dplyr)
library(data.table)
setDTthreads(3)

open_dataset("data/external/grassi_ficusfare/ficusfare_profil_wof_19942019_v0222.parquet") |>
  filter(year>=1999 & year<=2015) |>
  select(siren, year, code, catotal, va, emp, sal, immocor, acha4, autacha, naf2003_single, inpcs, datcr) |>
  collect() |>
  fwrite(file = "data/interim/firm_outcomes/ficusfare_profil_wof_19992015_v0222_light.csv")