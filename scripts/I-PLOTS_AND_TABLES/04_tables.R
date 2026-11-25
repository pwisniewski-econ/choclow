# LaTeX tables. assets.csv maps stable calculation keys to current numbered paths.
# Outputs are LaTeX fragments or tabular environments; unavailable statistics use --.

# Each column represents one model.
event_value <- function(d, variable, horizon) {
  if (is.null(d)) return(NA_real_)
  d[[variable]][match(horizon, d$distance)]
}
model_value <- function(d, variable) {
  if (is.null(d)) return(NA_real_)
  value <- unique(d[[variable]])
  stopifnot(length(value) == 1)
  value
}
event_table <- function(columns, labels, distances, worker = FALSE,
                        footer = c("n_obs", "n_treated", "r2")) {
  n <- length(columns) + as.integer(worker)
  if (worker) labels <- c(labels, "Ratio (6)/(5)")
  lines <- if (worker) c("& \\multicolumn{2}{l}{Outcome in levels} & \\multicolumn{5}{l}{Outcomes in log} \\\\ \\cmidrule[1.5pt](lr){2-3} \\cmidrule[1.5pt](lr){4-8}") else character()
  lines <- c(lines, number_header(n), tex_row("Time to displ.", labels), "\\midrule")
  row_lines <- lapply(distances, function(h) {
    estimates <- vapply(seq_along(columns), function(j) {
      d <- columns[[j]]
      # Agreement effects are estimable through +4.
      if (!is.null(d) && all(grepl("agreement", d$dep_var)) && h > 4 && !h %in% d$distance) return("")
      if (!is.null(d) && h == -2 && h %in% d$distance) return("REF")
      fmt(event_value(d, "beta", h), if (worker && j == 2) 0 else 3)
    }, character(1))
    errors <- vapply(seq_along(columns), function(j) {
      if (h == -2 && !is.null(columns[[j]])) return("")
      se <- event_value(columns[[j]], "std_error", h)
      if (is.na(se)) "" else paste0("(", fmt(se, if (worker && j == 2) 0 else 3), ")")
    }, character(1))
    if (worker) {
      denominator <- event_value(columns[[5]], "beta", h)
      ratio <- event_value(columns[[6]], "beta", h) / denominator
      ratio <- if (is.finite(ratio) && denominator != 0) fmt(ratio) else ""
      estimates <- c(estimates, ratio)
      errors <- c(errors, "")
    }
    c(tex_row(paste0("$d=", h, "$"), estimates), tex_row("", errors))
  })
  lines <- c(lines, unlist(row_lines, use.names = FALSE))
  if (length(footer)) lines <- c(lines, "\\midrule")
  footer_labels <- c(n_obs = "$N$", n_treated = "\\# treated", n_ind = "Individuals", r2 = "$R^2$")
  row_lines <- lapply(footer, function(statistic) {
    cells <- vapply(columns, function(d) fmt(model_value(d, statistic), if (statistic == "r2") 3 else 0), character(1))
    if (worker) cells <- c(cells, "")
    c(tex_row(footer_labels[[statistic]], cells))
  })
  lines <- c(lines, unlist(row_lines, use.names = FALSE))
  lines
}

# Table 2(a), A7, A9, A12: worker estimates with a premium/hourly-wage ratio.
worker_labels <- c("Employed", "Earnings", "Earnings", "Hours", "Hourly wage", "Premium")
worker_specs <- data.frame(
  sample = c(LE, LE, LE, MLO), premium = c("fe0215_mlo_le", "fe0215_mlo_le", "fe0215_god2", "fe0215_mlo_le"),
  filename = c("table_worker_body_202402.tex", "table_worker_appendix_2026-04.tex",
               "table_worker_god2_appendix_2026-04.tex", "table_worker_mlo_appendix_2026-04.tex"))
invisible(lapply(seq_len(nrow(worker_specs)), function(i) {
  spec <- worker_specs[i, ]
  outcomes <- c("employed", "sbr", "lnsbr", "lnnbheur", "lnsbrhour", spec$premium)
  columns <- lapply(outcomes, function(v) select_event(spec$sample, v))
  distances <- if (i == 1) 0:5 else -3:6
  footer <- if (i == 1) character() else c("n_obs", "n_treated", "r2")
  save_table(event_table(columns, worker_labels, distances, worker = TRUE, footer = footer),
             paste0("comprehensivetable/", spec$filename))
}))

# Tables 2(b), A8 and A13: firm and sample-specific bargaining models.
firm_outcomes <- c("prod_res_ma3_dlag4", "ln_apl_ma3_dlag4", "ln_lshare_ma3_dlag4")
firm_labels <- c("Productivity", "VA / Worker", "Labor share", "Wage Agr. ind.", "Election turnout")
invisible(lapply(1:3, function(i) {
  sample_name <- if (i == 3) MLO else LE
  columns <- lapply(firm_outcomes, function(v) select_event(sample_name, v))
  columns <- c(columns, list(
    select_event(paste0(sample_name, "-acco_alt"), "wage_agreement_ind_0507_alt"),
    select_event(paste0(sample_name, "-election"), "participation_siren0912")))
  lines <- event_table(columns, firm_labels, if (i == 1) 0:5 else -3:6,
                        footer = if (i == 1) character() else c("n_obs", "n_treated", "r2"))
  lines <- c("& \\multicolumn{3}{l}{Firm outcomes} & \\multicolumn{2}{l}{Negotiation variables} \\\\",
             "\\cmidrule[1.5pt](lr){2-4}\\cmidrule[1.5pt](lr){5-6}", lines)
  filename <- c("table_firm_body_202402.tex", "table_firm_appendix_2026-04.tex", "table_firm_mlo_appendix_2026-04.tex")[i]
  save_table(lines, paste0("comprehensivetable/", filename),
             note = if (i == 3) "MLO bargaining models use their exported support through +6." else
               "LE agreement estimates intentionally stop at +4; later agreement cells are blank, as in the paper.")
}))

# Tables 3 and A2: origin/destination comparisons; four and three columns respectively.
origin_destination <- read_result("tbl2-origin_destination/tbl2-le5_panelsize0-fixed_all.csv")
invisible(lapply(c(FALSE, TRUE), function(use_weights) {
  outcomes <- c("fe0215_mlo_le", "ln_apl_mean_0215", "prod_res_mean_0215")
  if (!use_weights) outcomes <- c(outcomes, "fe0215_mlo_le")
  columns <- lapply(seq_along(outcomes), function(j) {
    d <- origin_destination |>
      filter(sample == "le5_panelsize0-fixed_all", dep_var == outcomes[j], weighted == use_weights,
             naf2_fe, controls == (j == 4))
    stopifnot(length(unique(d$model_id)) == 1, !anyDuplicated(d$variable))
    d
  })
  labels <- c("Wage premium", "VA/worker", "Productivity", "Wage premium")[seq_along(columns)]
  lines <- c(number_header(length(columns)), tex_row("", labels), "\\midrule")
  row_lines <- lapply(c("destinationTRUE", "originTRUE", "ln_apl_mean_0215", "ln_emp_mean_0215"), function(variable_name) {
    if (use_weights && variable_name %in% c("ln_apl_mean_0215", "ln_emp_mean_0215")) return(character())
    coefficient <- vapply(columns, function(d) {
      row <- d[d$variable == variable_name, ]
      if (nrow(row) == 0) return("")
      stars <- if (row$pval < .001) "***" else if (row$pval < .01) "**" else if (row$pval < .05) "*" else ""
      paste0(sprintf("%.4g", row$beta), if (stars == "") "" else paste0("\\sym{", stars, "}"))
    }, character(1))
    statistics <- vapply(columns, function(d) {
      value <- d$tval[d$variable == variable_name]
      if (length(value)) paste0("(", sprintf("%.2f", value), ")") else ""
    }, character(1))
    label <- c(destinationTRUE = "Destination firm", originTRUE = "Origin firm",
               ln_apl_mean_0215 = "VA/worker", ln_emp_mean_0215 = "Employees")[[variable_name]]
    c(tex_row(label, coefficient), tex_row("", statistics), "\\addlinespace")
  })
  lines <- c(lines, unlist(row_lines, use.names = FALSE))
  lines <- c(lines, "\\midrule",
             tex_row("Observations", vapply(columns, function(d) fmt(unique(d$n_obs), 0), character(1))),
             tex_row("$R^2$", vapply(columns, function(d) fmt(unique(d$r2)), character(1))),
             tex_row("Adjusted $R^2$", vapply(columns, function(d) fmt(model_value(d, "ar2")), character(1))),
             tex_row("Sector FE", rep("$\\surd$", length(columns))),
             tex_row("P-value Origin-Destination", vapply(columns, function(d) fmt(model_value(d, "p_origin_destination")), character(1))))
  filename <- if (use_weights) "desc_regression_hiring_firing_LE__weighted_202402.tex" else
    "new/desc_regression_hiring_firing_LE__all_202402.tex"
  save_table(lines, filename,
             note = "Adjusted R2 and the origin-destination equality-test p-value use the updated exports.")
}))

# Table A1: cell means, with the overlap counted in both Origin and Destination.
firm_means <- read_result("tbl2-origin_destination/means-le5_panelsize0-fixed_all.csv")
mean_variables <- c("fe0215_mlo_le", "ln_apl_mean_0215", "prod_res_mean_0215", "ln_lshare_mean_0215", "ln_emp_mean_0215")
lines <- c(number_header(6), tex_row("", c("Wage premium", "ln(VA/L)", "Productivity", "ln(labor share)", "ln(L)", "N (firms)")), "\\midrule")
firm_groups <- list("Origin firms" = firm_means$origin, "Destination firms" = firm_means$destination,
                    "Other firms" = !firm_means$origin & !firm_means$destination)
row_lines <- lapply(names(firm_groups), function(label) {
  d <- firm_means[firm_groups[[label]], ]
  means <- vapply(mean_variables, function(v) weighted.mean(d[[v]], d$n_siren, na.rm = TRUE), numeric(1))
  c(tex_row(label, c(fmt(means), fmt(sum(d$n_siren), 0))))
})
lines <- c(lines, unlist(row_lines, use.names = FALSE))
save_table(lines, "new/desc_means_origin_destination_LE_2026-05.tex",
            note = "Cell means weighted by n_siren; overlapping firms appear in both rows. Outcome-specific nonmissing denominators are not exported.")

# Table A4: firm age and pre-displacement mean tenure.
lines <- c("\\begin{tabular}{lcccc}", "\\toprule", tex_row("", paste0("$d=", c(-2, 0, 2, 5), "$")), "\\midrule")
age_outcomes <- c("age_firm", "mean_tenure_eqtp_ma3_dlag4")
age_labels <- c("Firm age (years)", "Mean worker tenure (years)")
row_lines <- lapply(seq_along(age_outcomes), function(i) {
  d <- select_event(LE, age_outcomes[i], distances = c(-2, 0, 2, 5))
  stars <- ifelse(is.na(d$pval), "", ifelse(d$pval < .01, "***", ifelse(d$pval < .05, "**", ifelse(d$pval < .1, "*", ""))))
  values <- paste0(sprintf("%+.3f", d$beta), stars)
  errors <- ifelse(is.na(d$std_error), "", paste0("(", fmt(d$std_error), ")"))
  c(tex_row(age_labels[i], values), tex_row("", errors))
})
lines <- c(lines, unlist(row_lines, use.names = FALSE))
save_table(c(lines, "\\bottomrule", "\\end{tabular}"), "r3_firm_age_tenure.tex",
            note = "Tenure is mean_tenure_eqtp_ma3_dlag4 under the confirmed baseline rule.")

# Tables 1/A14/A15: balance at each matching horizon.
# Normalize mean differences by the root mean of the two variances.
balance <- read_result("misc-descriptive_statistics/matching_balance.csv")
matching_rows <- data.frame(
  variable = c("age_cl", "sbrhour", "sbrhour", "nbheur", "nbheur", "nbsa_ent"),
  distance = c(-1, -2, -3, -2, -3, -1), digits = c(2, 2, 2, 2, 2, 1),
  label = c("Age", "Hourly wage at $t^D-2$", "Hourly wage at $t^D-3$", "Hours worked at $t^D-2$",
            "Hours worked at $t^D-3$", "\\# employees at firm at $t^D-1$"))
other_rows <- data.frame(
  variable = c("sx", "sbr", "fe0215_mlo_le", "hhi_comp_sirze_eqtp_ma3_dlag4", "year_cre"),
  distance = c(-1, -2, -1, -1, -1), digits = c(2, 2, 2, 4, 1),
  label = c("Gender: Male", "Annual gross earnings at $t^D-2$", "Firm wage premium $\\widehat{\\psi}_{J(i,t)}$",
            "Local labor market HHI", "Firm year of creation"))
invisible(lapply(c("LE", "MLO_matching", "MLO_other"), function(kind) {
  sample_name <- if (kind == "LE") LE else MLO
  d <- filter(balance, sample == paste0("results_building/main_samples/", sample_name, ".parquet"))
  rows <- if (kind == "LE") bind_rows(matching_rows, other_rows) else if (kind == "MLO_matching") matching_rows else other_rows
  lines <- c("{", "\\begin{tabular}{lccc}", "\\hline\\hline", number_header(3),
             tex_row("", c(if (kind == "LE") "LE" else "MLO30", "Control", "Norm. Diff.")), "\\hline")
  row_lines <- lapply(seq_len(nrow(rows)), function(i) {
    spec <- rows[i, ]
    section <- if (kind == "LE" && i %in% c(1, 7)) c(
      paste0("\\multicolumn{4}{l}{\\textbf{", if (i == 1) "Matching variables" else "Variables not included in matching algorithm", "}} \\\\")) else character()
    means <- d |> filter(name == spec$variable, ref_dist == spec$distance)
    sds <- d |> filter(name == paste0(spec$variable, "_sd"), ref_dist == spec$distance)
    stopifnot(nrow(means) == 1, nrow(sds) == 1)
    nd <- (means$Treated - means$Control) / sqrt((sds$Treated^2 + sds$Control^2) / 2)
    values <- c(fmt(c(means$Treated, means$Control), spec$digits), sprintf("%+.3f", nd))
    sd_values <- c(paste0("(", fmt(c(sds$Treated, sds$Control), spec$digits), ")"), "")
    c(section, tex_row(spec$label, values), tex_row("", sd_values))
  })
  lines <- c(lines, unlist(row_lines, use.names = FALSE))
  counts <- d |> filter(name == "age_cl_n", ref_dist == -1)
  origins <- read_result(paste0("tbl2-origin_destination/means-", sample_name, "-fixed_all.csv")) |>
    filter(origin)
  lines <- c(lines, "\\hline", tex_row("Obs (workers)", fmt(c(counts$Treated, counts$Control, counts$Treated + counts$Control), 0)),
             tex_row("Distinct origin firms", c(fmt(sum(origins$n_siren), 0), "", "")),
             "\\hline\\hline", "\\end{tabular}", "}")
  filenames <- c(LE = "LEAllmatchvar_quantivar_2026-05.tex", MLO_matching = "MLOAllmatchvar_2026-05.tex", MLO_other = "MLOAllquantivar_2026-05.tex")
  save_table(lines, filenames[[kind]],
             note = "Normalized differences recomputed using pooled SD; hourly-wage means and SDs use the updated exports.")
}))

# Tables A5/A6: authored definitions in tables/definitions.

# Tables A10/A11: exact formula filters. reg_id is always 12, so it is not a key.
correlations <- read_result("tbl_a6-corr_akm/le5_panelsize0.csv")
correlation_premium <- "fe0215_god2"
firm_rhs <- c("ln_emp_mean_0215 | minmax_year",
              "ln_emp_mean_0215+ln_va_mean_0215 | minmax_year",
              "ln_emp_mean_0215+ln_apl_mean_0215 | minmax_year",
              "ln_emp_mean_0215+prod_res_mean_0215 | minmax_year",
              "before1994 | minmax_year", "maxmfg | minmax_year",
              "ln_emp_mean_0215+prod_res_mean_0215+before1994+maxmfg | minmax_year",
              "ln_emp_mean_0215+prod_res_mean_0215+before1994+maxmfg | minmax_year+naf2d_num_main")
agreement_rhs <- c("wage_agreement_ind_0507_alt | minmax_year",
                   "wage_agreement_ind_0507_alt+ln_emp_mean_0215 | minmax_year",
                   "wage_agreement_ind_0507_alt | minmax_year+naf2d_num_main")
election_rhs <- sub("wage_agreement_ind_0507_alt", "participation_siren0912", agreement_rhs, fixed = TRUE)
invisible(lapply(c("firm", "bargaining"), function(kind) {
  rhs <- if (kind == "firm") firm_rhs else c(agreement_rhs, election_rhs)
  samples <- if (kind == "firm") rep("le5_panelsize0-fixed-one", 8) else
    rep(c("le5_panelsize0-acco_alt-one", "le5_panelsize0-elec-one"), each = 3)
  columns <- lapply(seq_along(rhs), function(j) {
    d <- correlations |> filter(sample == samples[j], dep_var == correlation_premium, errors == "~minmax_year",
                                 formula == paste0(correlation_premium, "~", rhs[j]))
    stopifnot(nrow(d) > 0, !anyDuplicated(d$variable))
    d
  })
  variables <- if (kind == "firm") c("ln_emp_mean_0215", "ln_va_mean_0215", "ln_apl_mean_0215", "prod_res_mean_0215", "before1994", "maxmfg") else
    c("wage_agreement_ind_0507_alt", "participation_siren0912", "ln_emp_mean_0215")
  labels <- if (kind == "firm") c("Employees", "VA", "VA per worker", "Productivity", "Age $>10$ years", "Manufacturing") else
    c("Wage agreement ind.", "Election turnout", "Employees")
  lines <- c(number_header(length(columns)), "\\midrule")
  row_lines <- lapply(seq_along(variables), function(i) {
    cells <- lapply(seq_along(columns), function(j) {
      row <- columns[[j]][columns[[j]]$variable == variables[i], ]
      # Paper A10 col.2 controls for size but only reports the VA coefficient.
      if (nrow(row) == 0 || (kind == "firm" && j == 2 && i == 1)) return(c("", ""))
      c(fmt(row$beta), paste0("(", fmt(row$std_error), ")"))
    })
    c(tex_row(labels[i], vapply(cells, `[`, character(1), 1)),
               tex_row("", vapply(cells, `[`, character(1), 2)), "\\addlinespace")
  })
  lines <- c(lines, unlist(row_lines, use.names = FALSE))
  lines <- c(lines, "\\midrule", tex_row("Sector FE", ifelse(grepl("naf2d_num_main", rhs), "$\\surd$", "")))
  row_lines <- lapply(c("n_obs", "r2", "ar2"), function(stat) {
    label <- c(n_obs = "Observations", r2 = "$R^2$", ar2 = "Adjusted $R^2$")[[stat]]
    c(tex_row(label, vapply(columns, function(d) fmt(unique(d[[stat]]), if (stat == "n_obs") 0 else 3), character(1))))
  })
  lines <- c(lines, unlist(row_lines, use.names = FALSE))
  save_table(lines, if (kind == "firm") "firm_Pooled_regression_fe0115.tex" else "firm_Pooled_nego_fe0115.tex",
             note = paste("Unrestricted AKM (fe0215_god2); unweighted; minmax_year-clustered errors.",
                          if (kind == "firm") "Uses the LE firm sample." else
                            "Uses LE-specific default acco_alt/election samples."))
}))

# Tables A16/A17: use the corresponding LE agreement/election sample.
negotiation_moments <- read_result("misc-descriptive_statistics/desc_sample-acco_elec.csv")
invisible(lapply(c("agreements", "elections"), function(kind) {
  sample_name <- if (kind == "agreements") ACCORDS else ELECTIONS
  variables <- if (kind == "agreements") c("wage_agreement_ind_0507_alt", "wage_agreement_num_0507_alt", "wage_agreement_fail_0507_alt", "hours_agreement_ind_0507_alt") else
    c("participation_siren0912", "shinscrit_carence_siren0912", "shinscrit_sup10cgt_siren0912")
  labels <- if (kind == "agreements") c("Wage agreement indicator", "\\# Wage agreement", "Wage failure ind.", "Hours agreement ind.") else
    c("Average turnout", "Failed (\\% workers)", "CGT (\\% workers)")
  d <- negotiation_moments[negotiation_moments$sample_name == sample_name &
                             negotiation_moments$var_name %in% variables, ]
  stopifnot(nrow(d) == length(variables), !anyDuplicated(d$var_name))
  d <- d[match(variables, d$var_name), ]
  stopifnot(!anyNA(d$var_name), !anyNA(d$n_nonmiss), all(d$n_nonmiss <= d$n_obs))
  percentile <- if (kind == "agreements") "p75" else "p50"
  lines <- c(tex_row("", c("Mean", "sd", "min", percentile, "max", "$N$")), "\\hline")
  row_lines <- lapply(seq_len(nrow(d)), function(i) {
    q <- d[[percentile]][i]
    cells <- c(fmt(d$mean[i]), fmt(d$sd[i]), fmt(d$min[i], 0), fmt(q, if (kind == "agreements") 0 else 3), fmt(d$max[i], if (kind == "agreements") 0 else 3), fmt(d$n_nonmiss[i], 0))
    c(tex_row(labels[i], cells))
  })
  lines <- c(lines, unlist(row_lines, use.names = FALSE))
  stopifnot(length(unique(d$n_obs)) == 1, length(unique(d$n_individuals_treated)) == 1)
  lines <- c(lines, "\\hline",
             tex_row("\\# Treated (sample)", c(fmt(unique(d$n_individuals_treated), 0), rep("", 5))))
  save_table(lines, if (kind == "agreements") "LEnego_acc_desc.tex" else "LEnego_ele_desc.tex",
             note = paste0("Sample: ", sample_name, ". N counts nonmissing observations for each outcome; the treated count describes the full sample. ",
                           if (kind == "agreements") "Agreement outcomes cover 2005-2007; uses exported p75." else
                             "Election outcomes cover 2009-2012; uses exported p50. Failed = no-candidate share, not blank votes."))
}))

# Tables A18/A20: baseline bargaining effects, with the paper's column counts.
agreement_outcomes <- c("wage_agreement_ind_0507_alt", "wage_agreement_num_0507_alt", "wage_agreement_fail_0507_alt", "hours_agreement_ind_0507_alt")
election_outcomes <- c("participation_siren0912", "shinscrit_carence_siren0912", "shinscrit_sup10cgt_siren0912")
save_table(event_table(lapply(agreement_outcomes, function(v) select_event(ACCORDS, v)),
                       c("Wage agree. ind.", "\\# Wage agree.", "Wage fail. ind.", "Hours agree. ind."), -3:4,
                       footer = c("n_ind", "n_treated")), "LEnego_acc_result.tex")
save_table(event_table(lapply(election_outcomes, function(v) select_event(ELECTIONS, v)),
                       c("Average turnout", "Failed (\\% workers)", "CGT (\\% workers)"), -3:6,
                       footer = c("n_ind", "n_treated")), "LEnego_ele_result.tex",
             note = "Failed elections follow the paper definition: shinscrit_carence_siren0912.")

# Table A19: baseline, size control, size+bins, observed-agreement-firms restriction.
columns <- list(select_event(ACCORDS, "wage_agreement_ind_0507_alt"),
                select_event(ACCORDS, "wage_agreement_ind_0507_alt", description_value = "controls: log(nbsa_ent)"),
                select_event(ACCORDS, "wage_agreement_ind_0507_alt", description_value = "controls: log(nbsa_ent) + bins"),
                select_event(ACCORDS_ISIN, "wage_agreement_ind_0507"))
lines <- event_table(columns, rep("Wage agreement ind.", 4), -3:4, footer = c("n_ind", "n_treated"))
lines <- c(lines, tex_row("Legal size bins (4)", c("", "", "$\\surd$", "")))
save_table(lines, "LEnego_acc_rob.tex",
             note = "Column 4 is acco_isin. Empty legacy lnsize coefficient row omitted because control coefficients are not exported.")

# Table A21: baseline, log size, log size + bins, and the smallest-layoff sample.
small_layoff_description <- events |>
  filter(sample == ELECTIONS, dep_var == "participation_siren0912",
         startsWith(description, "sample: lowest quartile of layoff share")) |>
  distinct(description) |> pull(description)
stopifnot(length(small_layoff_description) == 1)
columns <- list(select_event(ELECTIONS, "participation_siren0912"),
                select_event(ELECTIONS, "participation_siren0912", description_value = "controls: log(nbsa_ent)"),
                select_event(ELECTIONS, "participation_siren0912", description_value = "controls: log(nbsa_ent) + bins"),
                select_event(ELECTIONS, "participation_siren0912", description_value = small_layoff_description))
lines <- event_table(columns, rep("Average turnout", 4), -3:6, footer = c("n_ind", "n_treated"))
lines <- c(lines, tex_row("Legal size bins (4)", c("", "", "$\\surd$", "")))
save_table(lines, "LEnego_ele_rob.tex",
             note = paste("Column 3: log size + legal size bins. Column 4:", small_layoff_description))
