# Record outputs, selected models and input fingerprints.
definitions <- assets[assets$script == "definitions", ]
invisible(lapply(seq_len(nrow(definitions)), function(i) {
  record_output(definitions$exhibit[i], definitions$file[i],
                note = "Authored definitions retained from EJ_R2; edit the LaTeX directly.")
}))
stopifnot(!anyDuplicated(output_manifest$file),
          setequal(output_manifest$file, assets$file),
          all(file.exists(file.path(paper_dir, assets$file))))
output_manifest <- output_manifest[match(assets$file, output_manifest$file), ]
output_manifest$script <- assets$script
write.csv(output_manifest, file.path(build_dir, "manifest.csv"), row.names = FALSE, na = "")
write.csv(distinct(selected_models), file.path(build_dir, "selected_event_models.csv"), row.names = FALSE, na = "")
issues <- output_manifest |> filter(status != "ready")
writeLines(c("PAPER BUILD REPORT", "", paste("Built:", Sys.time()),
  paste("Numbered figure-panel PDFs:", sum(grepl("\\.pdf$", assets$file))),
  paste("Table inputs, including authored definitions:", sum(grepl("\\.tex$", assets$file))),
  "Numbering and selected exhibits follow the revised EJ_R2 manuscript.",
  "Repeated MLO panels have their own correctly numbered filenames; estimates are identical.",
  "Baseline firm timing: ma3_dlag4. Agreements: ALT, except Table A19 column 4 (ISIN).",
  "Balance normalized differences: sqrt((SD_treated^2 + SD_control^2)/2).",
  "Table A3 uses employment-weighted sd_w, quartiles and IQ_W from desc_firm_outcomes.csv.",
  "Table A3 productivity is prod_res_mean_0215, without the extra sector residualization.",
  "", "OUTPUT QUALIFICATIONS:",
  if (nrow(issues)) paste(issues$exhibit, issues$status, issues$note, sep = " | ") else "None.",
  "", "See manifest.csv for selection notes and selected_event_models.csv for model IDs."
), file.path(build_dir, "build_report.txt"))

# Fingerprint the input CSVs.
input_files <- sort(unique(c(event_files, used_result_files)))
input_hashes <- data.frame(file = substring(input_files, nchar(project_dir) + 2),
                          md5 = unname(tools::md5sum(input_files)))
write.csv(input_hashes, file.path(build_dir, "input_fingerprints.csv"), row.names = FALSE)
