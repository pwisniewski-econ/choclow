# Event-study figures. Stable keys are mapped to current numbered paths in assets.csv.
# Panel titles and labels are supplied by LaTeX.
wage_outcomes <- c("fe0215_mlo_le", "lnsbrhour", "lnnbheur", "lnsbr")

# Figures 1, A3/A4/A6, A8 and A18: four-series wage decompositions.
wage_specs <- data.frame(
  sample = c(LE, "le5_panelsize10", LE, MLO, LE, LE, STAYER),
  group = c("none", "none", "none", "none", "sx:1", "sx:0", "none"),
  premium = c("fe0215_mlo_le", "fe0215_mlo_le", "fe0215_god2", rep("fe0215_mlo_le", 4)),
  filename = c("fig_1_wage_decomposition", "fig_1_wage_decomposition_size10",
               "fig_1_wage_decomposition_god2", "fig_1_wage_decomposition_mlo30_baseline",
               "fig_1_wage_decomposition_men", "fig_1_wage_decomposition_women",
               "fig_1_wage_decomposition_mlo30_stayer"))
invisible(lapply(seq_len(nrow(wage_specs)), function(i) {
  spec <- wage_specs[i, ]
  d <- select_event(spec$sample, c(spec$premium, wage_outcomes[-1]), group = spec$group)
  save_figure(wage_plot(d), spec$filename, width = 7)
}))

# Figures 2, A7 and A19: baseline timing, three sector-decomposition panels.
sector_samples <- c(LE, MLO, STAYER)
sector_suffix <- c("", "_mlo30_baseline", "_mlo30_stayer")
sector_outcomes <- c("prod_res_ma3_dlag4", "ln_lshare_ma3_dlag4", "fe0215_mlo_le")
sector_files <- c("fig_2_productivity", "fig_2_labor_share", "fig_2_firm_premium")
invisible(lapply(seq_along(sector_samples), function(i) {
  invisible(lapply(seq_along(sector_outcomes), function(j) {
    outcomes <- paste0(sector_outcomes[j], c("", "_d2res", "_d2FE"))
    d <- select_event(sector_samples[i], outcomes)
    horizon <- min(tapply(d$distance, d$dep_var, max))
    save_figure(decomposition_plot(d), paste0(sector_files[j], sector_suffix[i]), note = paste("Within share evaluated at d =", horizon))
  }))
}))

# Figure 3: bargaining quality (ALT agreement definition).
save_figure(event_plot(select_event(ACCORDS, "wage_agreement_ind_0507_alt", distances = -5:4)),
            "fig_3_wage_agreement")
save_figure(event_plot(select_event(ELECTIONS, "participation_siren0912")),
            "fig_3_election_turnout")

# Figure A2: level outcomes.
level_outcomes <- c("sbr", "employed", "nbheur")
level_files <- c("event_sbr_All", "event_employed_All", "event_nbheur_All")
level_labels <- c("Annual earnings (euros)", "Employment probability", "Hours worked (per year)")
invisible(lapply(seq_along(level_outcomes), function(i) {
  p <- event_plot(select_event(LE, level_outcomes[i])) + labs(y = level_labels[i])
  save_figure(p, level_files[i])
}))

# Figures A9/A10: fixed 2002-2015 firm means, without sector components.
full_outcomes <- c("prod_res_mean_0215", "ln_apl_mean_0215", "ln_lshare_mean_0215")
full_roots <- c("prod_resFull", "ln_aplFull", "ln_LshareFull")
full_labels <- c("Productivity", "Log VA / worker", "Log labor share")
invisible(lapply(c(LE, MLO), function(sample_name) {
  invisible(lapply(seq_along(full_outcomes), function(i) {
    suffix <- if (sample_name == MLO) "_mlo" else ""
    filename <- paste0("event_firmfeat_", full_roots[i], suffix, "_Log")
    p <- event_plot(select_event(sample_name, full_outcomes[i])) + labs(y = full_labels[i])
    save_figure(p, filename)
  }))
}))

# Figure A11: laying-off firm outcomes; each h identifies a separate model.
firm_events <- read_result("ref_answers-productivity/productivity-post_le_es.csv")
firm_outcomes <- c("prod_res_ma3", "tfp_cd_ma3")
firm_files <- c("firm_es_prod_res", "firm_es_tfp_cd")
invisible(lapply(seq_along(firm_outcomes), function(i) {
  d <- firm_events |>
    filter(sample == LE, description == "LE-event def: first", dep_var == firm_outcomes[i]) |>
    mutate(distance = as.integer(sub(".*h=(-?[0-9]+).*", "\\1", coefficient)))
  stopifnot(!anyDuplicated(d$distance), !(-2 %in% d$distance))
  d <- bind_rows(d, data.frame(distance = -2, beta = 0, std_error = NA_real_))
  max_h <- if (i == 1) 4 else 6
  d <- d |> filter(distance %in% -4:max_h) |> arrange(distance)
  # Shading is drawn first so it never covers coefficient/error-bar marks.
  p <- event_plot(d, colors = c(Estimate = "#1e2d53"))
  p$layers <- c(list(annotate("rect", xmin = -1.5, xmax = 1.5, ymin = -Inf, ymax = Inf,
                              fill = "grey90", alpha = 0.4)), p$layers)
  p <- p + labs(x = "Horizon h (years from LE event)")
  save_figure(p, firm_files[i], width = 7)
}))

# Figure A20: wage decomposition in each bargaining subsample, no ratio box.
invisible(lapply(c(ACCORDS, ELECTIONS), function(sample_name) {
  is_accords <- sample_name == ACCORDS
  d <- select_event(sample_name, wage_outcomes, distances = if (is_accords) -5:4 else -5:6)
  save_figure(wage_plot(d, ratios = FALSE),
              if (is_accords) "LE_accords_age_roblabor" else "LE_elections_roblabor", width = 8.5, height = 5.5)
}))

# Figure A21: agreement robustness.
agreement_outcomes <- c("wage_agreement_ind_0507_alt", "wage_agreement_num_0507_alt",
                        "hours_agreement_ind_0507_alt")
agreement_files <- c("fig_a14_wage_indicator", "fig_a14_wage_num", "fig_a14_hours_indicator")
agreement_labels <- c("Wage agreement (indicator)", "Wage agreements (count)", "Hours agreement (indicator)")
invisible(lapply(seq_along(agreement_outcomes), function(i) {
  p <- event_plot(select_event(ACCORDS, agreement_outcomes[i], distances = -5:4)) +
    labs(y = agreement_labels[i])
  save_figure(p, agreement_files[i], height = 4.19)
}))
