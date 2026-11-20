library(data.table)
library(tidyverse)
library(haven)
library(fixest)
library(arrow)

col2keep <- c("siren", "max_year", "year_cre", "ln_emp_mean_0215",
  "prod_res_mean_0215", "prod_res_mean_0215_d2res", "ln_apl_mean_0215", 
  "fe0215_god2","fe0215_mlo_le", "fe0215_mlo","fe0215_le"
)

BINNING_OUTCOMES <- read_dta("data/interim/firm_outcomes/firm_siren_avg_fixed.dta", col_select = col2keep) |>
  #WARNING: Using an external vector in selections was deprecated in tidyselect 1.1.0. (it's from the haven package - careful in the future)
  filter(!if_any(c(fe0215_mlo_le, ln_apl_mean_0215, prod_res_mean_0215), is.na)) |> 
  setDT()

ELECTIONS_PRO <- setDT(read_dta("data/interim/elections_pro/elections_siren_year_0912.dta"))
ACCO_ENT <- setDT(read_dta("data/interim/acco_ent/accords0513.dta")) 

BINNING_OUTCOMES <- ELECTIONS_PRO[BINNING_OUTCOMES, on = .(siren)]
BINNING_OUTCOMES <- ACCO_ENT[BINNING_OUTCOMES, on = .(siren)]

BINNING_OUTCOMES <- BINNING_OUTCOMES[, wage_agreement_ind_0507_alt :=  fifelse(is.na(wage_agreement_ind_0507) & year_cre<2008 & max_year>2004, 0, wage_agreement_ind_0507)]


binning_select <- function(xval, yvals, nbins, DATA){
  
  DATA <- DATA |> 
    mutate(across(all_of(xval), ~ ntile(.x, nbins), .names = "{.col}_q")) 
  
  DATA |>
    group_by(quantile = .data[[paste0(xval, "_q")]]) |> 
    summarise(across(all_of(c(yvals, xval)), ~mean(.x, na.rm=TRUE))) |>
    mutate(xname = xval) |>
    rename(c("mean_xval"=xval))
}


fe_cols <- c("fe0215_mlo_le", "fe0215_mlo", "fe0215_le", "fe0215_god2")
bargaining_cols <- c("wage_agreement_num_0507", "wage_agreement_ind_0507_alt", "participation_siren0912")

binning_cols <- c("ln_apl_mean_0215", "prod_res_mean_0215", "prod_res_mean_0215_d2res")

BINNED_DATA_FE <- lapply(binning_cols, binning_select, fe_cols, 50, BINNING_OUTCOMES) |> 
  bind_rows()

write_csv(BINNED_DATA_FE, "results_analysis/fig_a7-binned_scatter/productivity_akm.csv")

BINNED_DATA_BARGAINING <- lapply(fe_cols, binning_select, bargaining_cols, 20, BINNING_OUTCOMES) |> 
  bind_rows()

write_csv(BINNED_DATA_BARGAINING, "results_analysis/fig_a7-binned_scatter/akm_bargaining.csv")






# RANDOM TESTING -----
BINNED_DATA_BARGAINING |> 
  #pivot_longer(all_of(binning_cols[1])) |>
  filter(xname == "fe0215_mlo_le") |>
  mutate(above = if_else(quantile > 9, T, F)) |>
  ggplot(aes(x=mean_xval, y = wage_agreement_num_0507))+
  geom_point(size=3, color = '#800020')+
  #geom_smooth(aes(group = above), method = "lm", se =F, linewidth=1.2, color = "grey50")+
  theme_minimal(18)+
  labs(title= "FIRM-SPECIFIC WAGE PREMIUM AND LOG(VA/L)", y="AVERAGE FIRM PREMIUM 2002 - 2012 (FH-DADS)", x="")
  #facet_wrap(~name, strip.position = "bottom", scales = "free_x")
