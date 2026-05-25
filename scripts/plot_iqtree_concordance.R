#!/usr/bin/env Rscript

# Visualize IQ-TREE concordance factor output.
#
# Usage:
#   Rscript scripts/plot_iqtree_concordance.R [qc_dir] [prefix] [gcf_cutoff]
#
# Defaults:
#   qc_dir     = new_align/qc_concordance/iqtree
#   prefix     = concordance
#   gcf_cutoff = 50
#
# Outputs, when inputs are present:
#   <prefix>.cf.tree.gcf.pdf/png
#   <prefix>.cf.branch.gcf.pdf/png

args <- commandArgs(trailingOnly = TRUE)
qc_dir <- if (length(args) >= 1) args[1] else "new_align/qc_concordance/iqtree"
prefix <- if (length(args) >= 2) args[2] else "concordance"
gcf_cutoff <- if (length(args) >= 3) as.numeric(args[3]) else 50

if (is.na(gcf_cutoff)) {
  cat("gcf_cutoff must be numeric\n", file = stderr())
  quit(status = 2)
}

suppressPackageStartupMessages({
  library(ape)
  library(ggplot2)
  library(ggtree)
})

cf_tree_path <- file.path(qc_dir, paste0(prefix, ".cf.tree"))
cf_branch_path <- file.path(qc_dir, paste0(prefix, ".cf.branch"))
cf_stat_path <- file.path(qc_dir, paste0(prefix, ".cf.stat"))

plot_width <- 18
plot_height <- 14
dpi <- 300

parse_cf_tree_label <- function(label) {
  label <- trimws(label)
  parts <- strsplit(label, "/", fixed = TRUE)
  bootstrap <- vapply(parts, function(x) suppressWarnings(as.numeric(x[1])), numeric(1))
  gcf <- vapply(parts, function(x) {
    if (length(x) >= 2) {
      suppressWarnings(as.numeric(x[2]))
    } else {
      NA_real_
    }
  }, numeric(1))
  data.frame(bootstrap = bootstrap, gCF = gcf)
}

read_cf_stat <- function(path) {
  stat <- read.table(path, header = TRUE, sep = "\t", comment.char = "#", stringsAsFactors = FALSE)
  numeric_cols <- c("ID", "gCF", "gCF_N", "gDF1", "gDF1_N", "gDF2", "gDF2_N",
                    "gDFP", "gDFP_N", "gN", "Label", "Length")
  for (col in intersect(numeric_cols, names(stat))) {
    stat[[col]] <- suppressWarnings(as.numeric(stat[[col]]))
  }
  stat
}

build_node_metadata <- function(tr) {
  data.frame(
    node = seq_len(length(tr$tip.label) + tr$Nnode),
    stringsAsFactors = FALSE
  )
}

size_for_tree <- function(tr) {
  max_chars <- max(nchar(tr$tip.label), na.rm = TRUE)
  list(
    width = min(30, max(plot_width, 4 + 0.13 * max_chars)),
    height = min(60, max(plot_height, 2 + 0.25 * length(tr$tip.label)))
  )
}

render_gcf_plot <- function(tr, node_df, title, out_prefix, label_col = "gCF") {
  low_gcf <- !is.na(node_df$gCF) & node_df$gCF < gcf_cutoff
  node_df$branch_group <- ifelse(low_gcf, "low", "ok")
  node_df$branch_group <- factor(node_df$branch_group, levels = c("ok", "low"))

  label_values <- node_df[[label_col]]
  node_df$branch_label <- ifelse(!is.na(label_values), round(label_values, 1), NA)

  dims <- size_for_tree(tr)

  p <- ggtree(tr) %<+% node_df +
    geom_tree(aes(color = branch_group), linewidth = 0.8) +
    geom_tiplab(size = 4.4, offset = 0.015) +
    geom_text2(aes(subset = !isTip & !is.na(branch_label), label = branch_label),
               hjust = -0.25, vjust = -0.25, size = 2.4) +
    scale_color_manual(
      values = c(ok = "black", low = "red"),
      breaks = c("low", "ok"),
      labels = c(paste0("gCF < ", gcf_cutoff), paste0("gCF >= ", gcf_cutoff)),
      name = "Branch"
    ) +
    ggtitle(title) +
    theme_tree2() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 18),
      legend.position = "bottom",
      plot.margin = margin(10, 220, 10, 10)
    )

  x_range <- diff(range(p$data$x, na.rm = TRUE))
  x_expand <- ifelse(is.finite(x_range) && x_range > 0, x_range * 0.45, 1)
  px <- p + coord_cartesian(
    xlim = c(0, max(p$data$x, na.rm = TRUE) + x_expand),
    clip = "off"
  )

  pdf_path <- paste0(out_prefix, ".pdf")
  png_path <- paste0(out_prefix, ".png")

  pdf(pdf_path, width = dims$width, height = dims$height, onefile = TRUE)
  print(px)
  dev.off()

  png(png_path, width = as.integer(ceiling(dims$width * dpi)),
      height = as.integer(ceiling(dims$height * dpi)), res = dpi)
  print(px)
  dev.off()

  message("wrote: ", pdf_path)
  message("wrote: ", png_path)
}

plot_from_cf_tree <- function(path) {
  tr <- read.tree(path)
  node_df <- build_node_metadata(tr)

  internal_nodes <- (length(tr$tip.label) + 1):(length(tr$tip.label) + tr$Nnode)
  parsed <- parse_cf_tree_label(tr$node.label)
  node_df$bootstrap <- NA_real_
  node_df$gCF <- NA_real_
  node_df$bootstrap[internal_nodes] <- parsed$bootstrap
  node_df$gCF[internal_nodes] <- parsed$gCF

  out_prefix <- file.path(qc_dir, paste0(prefix, ".cf.tree.gcf"))
  render_gcf_plot(tr, node_df, "IQ-TREE Concordance Factors from .cf.tree", out_prefix)
}

plot_from_cf_branch <- function(branch_path, stat_path) {
  tr <- read.tree(branch_path)
  stat <- read_cf_stat(stat_path)
  node_df <- build_node_metadata(tr)

  internal_nodes <- (length(tr$tip.label) + 1):(length(tr$tip.label) + tr$Nnode)
  node_ids <- suppressWarnings(as.numeric(tr$node.label))
  id_to_node <- stats::setNames(internal_nodes, node_ids)
  stat$node <- unname(id_to_node[as.character(stat$ID)])

  metric_cols <- intersect(c("gCF", "gCF_N", "gDF1", "gDF1_N", "gDF2", "gDF2_N",
                             "gDFP", "gDFP_N", "gN", "Label", "Length"), names(stat))
  for (col in metric_cols) {
    node_df[[col]] <- NA_real_
    matched <- !is.na(stat$node)
    node_df[[col]][stat$node[matched]] <- stat[[col]][matched]
  }

  out_prefix <- file.path(qc_dir, paste0(prefix, ".cf.branch.gcf"))
  render_gcf_plot(tr, node_df, "IQ-TREE Concordance Factors from .cf.branch/.cf.stat", out_prefix)
}

if (file.exists(cf_tree_path)) {
  plot_from_cf_tree(cf_tree_path)
} else {
  warning("missing ", cf_tree_path)
}

if (file.exists(cf_branch_path) && file.exists(cf_stat_path)) {
  plot_from_cf_branch(cf_branch_path, cf_stat_path)
} else {
  warning("missing ", cf_branch_path, " or ", cf_stat_path)
}
