# Figure A5: LE wage-premium trajectories by AKM estimation window.
# All AKMs exclude MLO- and LE-affected workers.
periods <- data.frame(
  dep_var = c("fe0215_mlo_le", "fe0205_mlo_le", "fe0210_mlo_le",
              "fe0510_mlo_le", "fe0515_mlo_le", "fe1015_mlo_le"),
  period = c("2002-2015 (baseline)", "2002-2005", "2002-2010",
             "2005-2010", "2005-2015", "2010-2015")
)
akm <- select_event(LE, periods$dep_var) |>
  left_join(periods, by = "dep_var") |>
  mutate(series = factor(period, levels = periods$period))
colors <- setNames(c("#1e2d53", "#91353b", "#008bbc", "#a0a0a0", "#56876b", "#9a7040"), periods$period)
shapes <- setNames(c(19, 17, 15, 18, 1, 2), periods$period)
lines <- setNames(c("solid", "dashed", "dotdash", "longdash", "twodash", "dotted"), periods$period)

# Omitting the facet variable repeats the baseline in each panel.
baseline <- akm |> filter(dep_var == "fe0215_mlo_le") |> select(distance, beta)
model_counts <- akm |>
  distinct(dep_var, period, model_id, n_obs) |>
  arrange(match(dep_var, periods$dep_var))
panel_labels <- setNames(paste0(model_counts$period, "\nN = ",
                               format(model_counts$n_obs, big.mark = ",", trim = TRUE)), model_counts$period)
p <- event_plot(akm, colors, shapes, lines, x_breaks = -5:6) +
  geom_line(data = baseline, aes(distance, beta), inherit.aes = FALSE,
            color = "grey45", linetype = "dashed", linewidth = 0.6) +
  facet_wrap(~series, ncol = 2, labeller = as_labeller(panel_labels)) +
  labs(x = "Years from displacement", y = "Effect on firm wage premium") +
  paper_theme() +
  theme(legend.position = "none", strip.text = element_text(size = 12),
        axis.text = element_text(size = 10), axis.title = element_text(size = 13))
save_figure(p, "tmp_ref2_LE_akm_periods_panels", width = 9, height = 9)
write.csv(akm, file.path(build_dir, "figure_A5_akm_data.csv"), row.names = FALSE, na = "")
