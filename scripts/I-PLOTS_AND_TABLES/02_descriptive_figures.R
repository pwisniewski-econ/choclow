# Non-regression plots: categorical distributions, binscatters, quintiles, raw means.

# Figures A1/A17: categorical distributions at d = -1.
categories <- read_result("misc-descriptive_statistics/cs1_sec10_samples.csv")
sector_names <- c("Agriculture", "Manufacturing", "Construction", "Trade, transp. & hotels",
                  "Information & com.", "Finance", "Real estate", "Services to firms",
                  "Public / edu / health", "Other services")
occupation_names <- c("Farmers", "Self-employed", "Managers", "Intermediate prof.",
                      "Employees", "Blue collar", "Other / unknown")
education_names <- c("Higher education (>=2y)", "Higher educ. (other)", "Bac+2", "Baccalaureate",
                     "Vocational dipl. (CAP/BEP)", "Brevet", "No diploma", "Other")
category_labels <- list(sec_a10 = sector_names, cs1 = occupation_names, dip_tot = education_names)
invisible(lapply(c(LE, MLO), function(sample_name) {
  variables <- if (sample_name == LE) c("sec_a10", "cs1", "dip_tot") else c("sec_a10", "cs1")
  invisible(lapply(variables, function(variable_name) {
    if (variable_name == "sec_a10") {
      d <- categories |>
        filter(variable == variable_name,
               (sample == sample_name & treated == 0) | (sample == "dads-2005_2012" & treated == 2)) |>
        mutate(series = ifelse(sample == sample_name, "Estimation sample", "Panel DADS (2005-2012)"))
      colors <- c("Estimation sample" = "#1e2d53", "Panel DADS (2005-2012)" = "#a0a0a0")
    } else {
      d <- categories |> filter(variable == variable_name, sample == sample_name, treated %in% 0:1) |>
        mutate(series = ifelse(treated == 0, "Control", "Displaced"))
      colors <- c(Control = "#1e2d53", Displaced = "#91353b")
    }
    # Missing education contributes to the denominator but has no bar.
    d <- d |> group_by(series) |>
      mutate(share = n_individuals / sum(n_individuals)) |> ungroup() |> filter(!is.na(value))
    labels <- category_labels[[variable_name]]
    d$category <- factor(labels[d$value], levels = labels[sort(unique(d$value))])
    d$series <- factor(d$series, levels = names(colors))
    p <- ggplot(d, aes(category, share, fill = series)) +
      geom_col(position = position_dodge(width = 0.78), width = 0.72) +
      scale_fill_manual(values = colors) +
      scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
      labs(x = "", y = "Share of workers") +
      paper_theme() + theme(axis.text.x = element_text(angle = 25, hjust = 1, vjust = 1, size = 11),
                             plot.margin = margin(8, 12, 8, 35),
                             plot.subtitle = element_text(size = 9, colour = "grey40"))
    prefix <- if (sample_name == LE) "LEAll" else "MLOAll"
    suffix <- c(sec_a10 = "sec", cs1 = "occup", dip_tot = "dip")[[variable_name]]
    save_figure(p, paste0(prefix, "desc_", suffix),
                width = if (variable_name == "sec_a10") 10 else 9, height = 4,
                note = "Updated export at d=-1. Shares use exported counts, including missing categories where exported; cells with at most five workers are suppressed upstream.")
  }))
}))

# Figure A12. Display all 50 bins; the line is fitted only on bins 6..49.
productivity_bins <- read_result("fig_a7-binned_scatter/productivity_akm.csv")
bin_x <- c("ln_apl_mean_0215", "prod_res_mean_0215")
bin_files <- c("firm_LE_binscatter_ln_apl", "firm_LE_binscatter_prod")
bin_labels <- c("Log of value-added per worker (mean 2002-2015)", "Productivity (residual, mean 2002-2015)")
invisible(lapply(seq_along(bin_x), function(i) {
  d <- productivity_bins |> filter(xname == bin_x[i]) |> arrange(quantile)
  fit <- lm(fe0215_mlo_le ~ mean_xval, data = filter(d, quantile > 5, quantile < 50))
  p <- ggplot(d, aes(mean_xval, fe0215_mlo_le)) +
    geom_point(color = "#1e2d53", size = 2.2) +
    geom_abline(intercept = coef(fit)[1], slope = coef(fit)[2], color = "grey60", linewidth = 0.6) +
    annotate("label", x = -Inf, y = Inf, label = sprintf("slope = %.3f", coef(fit)[2]),
             hjust = -0.05, vjust = 1.2, linewidth = 0.2, fill = "white", color = "grey25", size = 4) +
    labs(x = bin_labels[i], y = "Firm wage premium (AKM)") + paper_theme() +
    theme(axis.title.x = element_text(size = 13))
  save_figure(p, bin_files[i])
}))

# Figure A13: wage-agreement indicator and election turnout binscatters.
bargaining_bins <- read_result("fig_a7-binned_scatter/akm_bargaining.csv") |>
  filter(xname == "fe0215_mlo_le") |> arrange(quantile)
bargaining_y <- c("wage_agreement_ind_0507_alt", "participation_siren0912")
bargaining_files <- c("firm_LE_binscatter_wage_agreement", "firm_LE_binscatter_election_turnout")
bargaining_labels <- c("Indicator of wage agreement", "Election turnout")
stopifnot(all(bargaining_y %in% names(bargaining_bins)))
invisible(lapply(seq_along(bargaining_y), function(i) {
  d <- bargaining_bins |> mutate(y = .data[[bargaining_y[i]]])
  fitted <- filter(d, quantile > 1, quantile < 20)
  fit <- lm(y ~ mean_xval, data = fitted)
  p <- ggplot(d, aes(mean_xval, y)) +
    geom_smooth(data = fitted, method = "lm", formula = y ~ x, se = FALSE,
                color = "grey60", linewidth = 0.6) +
    geom_point(color = "#1e2d53", size = 3) +
    annotate("text", x = quantile(d$mean_xval, 0.05), y = max(d$y), hjust = 0, vjust = 1,
             label = sprintf("Fitted slope = %.3f", coef(fit)[2]), size = 4, color = "grey30") +
    labs(x = "Firm wage premium (AKM)", y = bargaining_labels[i]) + paper_theme()
  save_figure(p, bargaining_files[i])
}))

# Figure A14: wage-premium quintiles by sample.
quintiles <- read_result("misc-descriptive_statistics/quantiles_split.csv") |>
  filter(type_akm == "fe0215_mlo_le_q5_full", sample %in% c(LE, MLO)) |>
  group_by(sample) |> mutate(share = 100 * n_ind / sum(n_ind)) |> ungroup() |>
  mutate(study = ifelse(sample == LE, "LE", "MLO")) |> select(study, quantile, share)
literature <- data.frame(
  study = rep(c("LMW", "SWH boom", "SWH rec.", "BABGLS"), each = 5),
  quantile = rep(1:5, 4),
  share = c(9.9, 9.4, 18.9, 19.8, 42.0, 2.05, 5.97, 15.2, 36.5, 40.3,
            1.65, 6.1, 16.4, 37.4, 38.5, 7.14, 6.5, 18.66, 30.38, 37.31))
d <- bind_rows(quintiles, literature) |>
  mutate(study = factor(study, levels = rev(c("LE", "MLO", "LMW", "SWH boom", "SWH rec.", "BABGLS"))),
         quantile = factor(quantile, levels = 1:5, labels = paste0("Q", 1:5)))
p <- ggplot(d, aes(y = study, x = share, fill = quantile)) +
  geom_col(width = 0.75, color = "grey20", linewidth = 0.25, position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = ifelse(share >= 5, sprintf("%.1f%%", share), "")),
            position = position_stack(vjust = 0.5, reverse = TRUE), size = 3.2, color = "grey15") +
  scale_fill_manual(values = c(Q1 = "#A9A8A8", Q2 = "#D0D0D0", Q3 = "#ABDAF4", Q4 = "#80CFB9", Q5 = "#E6BCD3")) +
  scale_x_continuous(breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%"),
                     limits = c(0, 100.5), expand = c(0, 0)) +
  labs(x = NULL, y = NULL, fill = "AKM Quantile") + paper_theme() +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(size = 12), legend.text = element_text(size = 12),
        legend.title = element_text(size = 12))
save_figure(p, "sample_FEdist", width = 7.5, height = 4.5)

# Figures A15/A16: one raw-mean pair per horizon, without event-study SEs.
invisible(lapply(c("sbr", "nbheur"), function(outcome) {
  d <- select_event(LE, outcome) |> select(distance, mean_treated, mean_control) |>
    pivot_longer(c(mean_control, mean_treated), names_to = "series", values_to = "value") |>
    mutate(series = factor(series, levels = c("mean_control", "mean_treated"), labels = c("Control", "Displaced")))
  p <- ggplot(d, aes(distance, value, color = series, shape = series, linetype = series)) +
    geom_line(linewidth = 0.8) + geom_point(size = 3.5) +
    geom_vline(xintercept = -0.5, color = "grey30", linewidth = 0.6) +
    scale_x_continuous(breaks = -5:6, limits = c(-5.5, 6.5), expand = expansion(add = 0)) +
    scale_color_manual(values = c(Control = "#1e2d53", Displaced = "#91353b")) +
    scale_shape_manual(values = c(Control = 17, Displaced = 19)) +
    scale_linetype_manual(values = c(Control = "dashed", Displaced = "solid")) +
    labs(x = "Distance to displacement", y = if (outcome == "sbr") "Annual earnings (euros)" else "Hours worked") +
    paper_theme()
  save_figure(p, if (outcome == "sbr") "LEAllraw_sbr" else "LEAllraw_hours", width = 7)
}))
