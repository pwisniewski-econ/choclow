# Table A3: employment-weighted firm distributions and baseline effects at +5.
dispersion <- read_result("misc-descriptive_statistics/desc_firm_outcomes.csv")
variables <- c("prod_res_mean_0215", "ln_apl_mean_0215",
               "ln_lshare_mean_0215", "fe0215_mlo_le")
outcomes <- c("prod_res_ma3_dlag4", "ln_apl_ma3_dlag4",
              "ln_lshare_ma3_dlag4", "fe0215_mlo_le")
stopifnot(!anyDuplicated(dispersion$var_name), all(variables %in% dispersion$var_name))
dispersion <- dispersion[match(variables, dispersion$var_name), ]
effects <- select_event(LE, outcomes, distances = 5)
dispersion$coefficient <- effects$beta[match(outcomes, effects$dep_var)]
dispersion$event_outcome <- outcomes
dispersion$model_id <- effects$model_id[match(outcomes, effects$dep_var)]
dispersion$share_iqr <- abs(dispersion$coefficient) / dispersion$IQ_W
dispersion$sd_units <- abs(dispersion$coefficient) / dispersion$sd_w

# Interpolate percentile positions between the weighted median and adjacent quartile.
stopifnot(all(dispersion$coefficient >= dispersion$p25_w - dispersion$p50_w),
          all(dispersion$coefficient <= dispersion$p75_w - dispersion$p50_w))
adjacent_gap <- ifelse(dispersion$coefficient >= 0,
                      dispersion$p75_w - dispersion$p50_w,
                      dispersion$p50_w - dispersion$p25_w)
dispersion$percentile_reached <- 50 + 25 * dispersion$coefficient / adjacent_gap

lines <- c("\\begin{tabular}{lcccc}", "\\toprule", number_header(4),
  tex_row("", c("Productivity", "VA per worker", "Labor share", "Wage premium")),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A. Distribution across firms, weighted by employment}} \\\\",
  tex_row("Standard deviation", fmt(dispersion$sd_w)),
  tex_row("25th percentile", fmt(dispersion$p25_w)),
  tex_row("Median", fmt(dispersion$p50_w)),
  tex_row("75th percentile", fmt(dispersion$p75_w)),
  tex_row("Interquartile range", fmt(dispersion$IQ_W)),
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B. Displacement effect at $t^D+5$ (Table~\\ref{tab:evstudytable_body}) relative to panel A}} \\\\",
  tex_row("Coefficient at $t^D+5$", fmt(dispersion$coefficient)),
  tex_row("Share of the interquartile range", fmt(dispersion$share_iqr, 2)),
  tex_row("In standard-deviation units", fmt(dispersion$sd_units, 2)),
  tex_row("Percentile reached by a median firm", fmt(dispersion$percentile_reached, 0)),
  "\\midrule", tex_row("Firms with a non-missing value", fmt(dispersion$n_nonmiss, 0)),
  "\\bottomrule", "\\end{tabular}")
save_table(lines, "r3_firm_universe_dispersion_0215.tex",
           note = "Employment-weighted moments; baseline LE effects at +5; percentile approximated from adjacent quartiles.")
write.csv(dispersion, file.path(build_dir, "table_A3_calculations.csv"), row.names = FALSE)
