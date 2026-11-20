library(tidyverse)
library(arrow)
library(haven)
library(data.table)

#SAMPLE_DESC <- read_dta("data/interim/panel_outcomes/descriptives_panel.dta", col_select = c(an, age, n))
#age_q <- SAMPLE_DESC |> 
#  select(an, age, n) |>
#  filter(age>0&age<110&an>2001&an<2016)
#age_q <- unname(Hmisc::wtd.quantile(age_q$age, age_q$n)[2:5])

## AKM - FIRMS

get_q <- function(filename){
    read_parquet(paste0("results_building/main_samples/", filename, ".parquet")) |>
    select(siren, matches("_q._full")) |>
    unique() |>
    pivot_longer(-c(siren)) |>
    group_by(quantile = value, type_akm = name) |>
    summarise(n_ind = n()) |>
    ungroup() |>
    filter(!is.na(quantile)) |>
    mutate(sample = filename)
}

samples <- str_remove(list.files("results_building/main_samples"), ".parquet")

AKM_SUMMS <- lapply(samples, get_q) |>
  bind_rows()

write_csv(AKM_SUMMS, "results_analysis/misc-descriptive_statistics/quantiles_split.csv")


AKM_SUMMS |>
  group_by(sample = paste0(sample, "-", type_akm)) |>
  mutate(quantile = factor(paste0("Q",quantile), levels = paste0("Q", 5:1)), 
    prop = n_ind/sum(n_ind), cumprop = cumsum(prop), 
    text_pos = cumprop - (cumprop-lag(cumprop))/2, 
    text_pos = if_else(is.na(text_pos), prop/2, text_pos)) |>
  ggplot(aes(y=sample, x= prop, fill = quantile))+
  geom_bar(stat="identity")+
  scale_fill_brewer(palette = "Blues", direction = -1)+
  geom_text(aes(label = paste0(round(prop,4)*100,"%"), x= text_pos), size=5)+
  theme_minimal(16)
