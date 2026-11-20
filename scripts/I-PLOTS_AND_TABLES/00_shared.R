# Shared data selection, appearance and output bookkeeping.
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})

project_dir <- normalizePath(".", winslash = "/")
script_dir <- file.path(project_dir, "scripts/I-PLOTS_AND_TABLES")
paper_dir <- file.path(project_dir, "results_paper")
data_dir <- file.path(project_dir, "results_analysis")
build_dir <- file.path(paper_dir, "build")
assets <- read.csv(file.path(script_dir, "assets.csv"), stringsAsFactors = FALSE)
invisible(lapply(unique(c(build_dir, dirname(file.path(paper_dir, assets$file)))),
                 dir.create, recursive = TRUE, showWarnings = FALSE))

LE <- "le5_panelsize0"
MLO <- "panelpanSIZE2"
STAYER <- "panelpanSIZE1"
ACCORDS <- "le5_panelsize0-acco_alt"
ACCORDS_ISIN <- "le5_panelsize0-acco_isin"
ELECTIONS <- "le5_panelsize0-election"
ci_scalar <- 2.576

used_result_files <- character()
read_result <- function(path) {
  used_result_files <<- unique(c(used_result_files, file.path(data_dir, path)))
  read.csv(file.path(data_dir, path), na.strings = c("NA", ""),
           check.names = FALSE, stringsAsFactors = FALSE)
}
event_files <- c(list.files(file.path(data_dir, "event_studies-main_samples"), pattern = "\\.csv$", full.names = TRUE),
                 list.files(file.path(data_dir, "event_studies-elec_samples"), pattern = "\\.csv$", full.names = TRUE))
events <- bind_rows(lapply(event_files, read.csv, na.strings = c("NA", "")))
selected_models <- data.frame()

# Select one specification before restricting event horizons.
select_event <- function(sample_name, outcomes, group = "none", description_value = NA_character_,
                         distances = -5:6) {
  d <- events |>
    filter(sample == sample_name, dep_var %in% outcomes,
           treatment_path, interaction_group == group)
  d <- if (is.na(description_value)) filter(d, is.na(description)) else
    filter(d, description == description_value)
  stopifnot(setequal(unique(d$dep_var), outcomes))
  models <- d |> distinct(dep_var, model_id) |> count(dep_var)
  stopifnot(all(models$n == 1), !anyDuplicated(d[c("dep_var", "distance")]))
  d <- d |> filter(distance %in% distances) |> arrange(dep_var, distance)
  selected_models <<- bind_rows(selected_models,
    d |> group_by(sample, dep_var, model_id, interaction_group, description) |>
      summarise(first_distance = min(distance), last_distance = max(distance), .groups = "drop"))
  d
}

output_manifest <- data.frame(exhibit = character(), file = character(), status = character(),
                              note = character(), stringsAsFactors = FALSE)
record_output <- function(exhibit, path, status = "ready", note = "") {
  output_manifest <<- bind_rows(output_manifest,
    data.frame(exhibit = exhibit, file = path, status = status, note = note))
  invisible(NULL)
}
save_figure <- function(p, filename, width = 6, height = 5, status = "ready", note = "") {
  targets <- assets[assets$key == filename, ]
  stopifnot(nrow(targets) > 0)
  invisible(lapply(seq_len(nrow(targets)), function(i) {
    ggsave(file.path(paper_dir, targets$file[i]), p,
           width = width, height = height, units = "in", bg = "white",
           device = grDevices::cairo_pdf, family = "Arial")
    record_output(targets$exhibit[i], targets$file[i], status, note)
  }))
}

fmt <- function(x, digits = 3) {
  ifelse(is.na(x), "--", formatC(x, digits = digits, format = "f",
                                 big.mark = if (digits == 0) "," else ""))
}
tex_row <- function(label, cells) paste0(label, " & ", paste(cells, collapse = " & "), " \\\\")
number_header <- function(n) tex_row("", paste0("(", seq_len(n), ")"))
save_table <- function(lines, filename, status = "ready", note = "") {
  key <- tools::file_path_sans_ext(basename(filename))
  target <- assets[assets$key == key, ]
  stopifnot(nrow(target) == 1)
  heading <- c("% Generated from current results_analysis CSV files by master.R, section I (scripts/I-PLOTS_AND_TABLES).",
               paste0("% ", target$exhibit, "; status: ", status), paste0("% ", note),
               "% -- means a requested statistic is unavailable; an empty cell means not applicable.")
  writeLines(c(heading, lines), file.path(paper_dir, target$file), useBytes = TRUE)
  record_output(target$exhibit, target$file, status, note)
}

paper_theme <- function() {
  theme_minimal(base_size = 16, base_family = "Arial") +
    theme(axis.title.x = element_text(vjust = -1),
          axis.title.y = element_text(vjust = 3),
          legend.position = "bottom", legend.title = element_blank(),
          panel.grid.minor = element_blank(),
          axis.line = element_line(colour = "grey20", linewidth = 0.6),
          plot.margin = margin(8, 10, 8, 8))
}
wage_labels <- c(fe0215_mlo_le = "Firm Wage Premium", fe0215_god2 = "Firm Wage Premium",
                 lnsbrhour = "Log Hourly Wage", lnnbheur = "Log Hours", lnsbr = "Log Earnings")
wage_order <- c("Firm Wage Premium", "Log Hourly Wage", "Log Hours", "Log Earnings")
wage_colors <- c("Firm Wage Premium" = "#91353b", "Log Hourly Wage" = "#008bbc",
                 "Log Hours" = "#82c0e9", "Log Earnings" = "#1e2d53")
wage_shapes <- setNames(c(19, 17, 18, 15), wage_order)
wage_lines <- setNames(c("solid", "dashed", "dashed", "solid"), wage_order)
sector_order <- c("Overall effect", "Between sector", "Within sector")
sector_colors <- c("Overall effect" = "#1e2d53", "Within sector" = "#a0a0a0", "Between sector" = "#82c0e9")
sector_shapes <- c("Overall effect" = 19, "Within sector" = 18, "Between sector" = 15)

event_plot <- function(d, colors = c(Estimate = "black"), shapes = c(Estimate = 19),
                       linetypes = c(Estimate = "solid"), x_breaks = sort(unique(d$distance)),
                       legend_rows = 2) {
  if (!"series" %in% names(d)) d$series <- "Estimate"
  intervals <- d |> filter(!is.na(std_error))
  ggplot(d, aes(distance, beta, color = series, shape = series, linetype = series)) +
    geom_vline(xintercept = -0.5, color = "grey30", linewidth = 0.6) +
    geom_hline(yintercept = 0, color = "grey30", linewidth = 0.6) +
    geom_line(linewidth = 0.8) + geom_point(size = 3.5) +
    geom_errorbar(data = intervals,
                  aes(ymin = beta - ci_scalar * std_error, ymax = beta + ci_scalar * std_error),
                  width = 0.25, linewidth = 0.75, linetype = "solid") +
    scale_x_continuous(breaks = x_breaks, limits = range(x_breaks) + c(-0.5, 0.5),
                       expand = expansion(add = 0)) +
    scale_color_manual(values = colors) + scale_shape_manual(values = shapes) +
    scale_linetype_manual(values = linetypes) +
    guides(color = guide_legend(nrow = legend_rows), shape = guide_legend(nrow = legend_rows),
           linetype = guide_legend(nrow = legend_rows)) +
    labs(x = "", y = "") + paper_theme() +
    theme(legend.position = if (length(colors) == 1) "none" else "bottom")
}

# Ratios used in figure annotations.
wage_plot <- function(d, ratios = TRUE) {
  d$series <- factor(unname(wage_labels[d$dep_var]), levels = wage_order)
  p <- event_plot(d, wage_colors, wage_shapes, wage_lines)
  yr <- range(d$beta - ci_scalar * ifelse(is.na(d$std_error), 0, d$std_error),
              d$beta + ci_scalar * ifelse(is.na(d$std_error), 0, d$std_error), 0)
  yr <- c(floor(yr[1] * 10) / 10, ceiling(yr[2] * 10) / 10)
  p <- p + scale_y_continuous(breaks = seq(floor(yr[1] / .2) * .2,
                                          ceiling(yr[2] / .2) * .2, by = .2)) +
    coord_cartesian(ylim = yr)
  if (ratios) {
    b <- d |> select(distance, series, beta) |> pivot_wider(names_from = series, values_from = beta)
    b <- b[match(c(2, 6), b$distance), ]
    hourly <- sprintf("%.0f%%", 100 * b[["Log Hourly Wage"]] / b[["Log Earnings"]])
    premium <- sprintf("%.0f%%", 100 * b[["Firm Wage Premium"]] / b[["Log Hourly Wage"]])
    label <- paste0('atop("Ratios at d = 2, d = 6:", atop(beta[hourly]/beta[earnings] == "',
                    paste(hourly, collapse = ", "), '", beta[AKM]/beta[hourly] == "',
                    paste(premium, collapse = ", "), '"))')
    p <- p + annotate("label", x = -4.8, y = yr[1] + 0.58 * diff(yr),
                       label = label, parse = TRUE, hjust = 0, vjust = 1, size = 3.6,
                       fill = NA, color = "#525c66", linewidth = 0.3,
                       label.padding = grid::unit(0.5, "lines"))
  }
  p
}

decomposition_plot <- function(d) {
  d$series <- ifelse(grepl("_d2res$", d$dep_var), "Within sector",
                     ifelse(grepl("_d2FE$", d$dep_var), "Between sector", "Overall effect"))
  d$series <- factor(d$series, levels = sector_order)
  # All three components must use the same observed horizons.
  common_distances <- Reduce(intersect, split(d$distance, d$series))
  d <- filter(d, distance %in% common_distances)
  last <- d |> filter(distance == max(common_distances))
  within <- last$beta[last$series == "Within sector"]
  between <- last$beta[last$series == "Between sector"]
  share <- abs(within) / (abs(within) + abs(between))
  label <- sprintf('frac(group("|", beta[within], "|"), group("|", beta[within], "|") + group("|", beta[between], "|")) == "%.0f%%"', 100 * share)
  p <- event_plot(d, sector_colors, sector_shapes, setNames(rep("solid", 3), sector_order))
  yr <- range(d$beta - ci_scalar * ifelse(is.na(d$std_error), 0, d$std_error),
              d$beta + ci_scalar * ifelse(is.na(d$std_error), 0, d$std_error), 0)
  yr <- c(floor(yr[1] * 20) / 20, ceiling(yr[2] * 20) / 20)
  p + scale_y_continuous(breaks = round(seq(yr[1], yr[2], 0.05), 2),
                         labels = function(x) sprintf("%.2f", x)) +
    coord_cartesian(ylim = yr) +
    annotate("label", x = min(common_distances) + 0.1, y = yr[2],
             label = label, parse = TRUE, hjust = 0, vjust = 1, size = 3.2,
             fill = NA, color = "#525c66", linewidth = 0.3,
             label.padding = grid::unit(0.5, "lines"))
}
