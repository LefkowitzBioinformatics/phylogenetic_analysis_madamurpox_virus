#!/usr/bin/env Rscript

# Usage:
#   ./graph_tree.R <treefile> <proteins.faa> <plot_title> [branch_score_cutoff]
#
# Outputs:
#   <treefile>.pdf
#   <treefile>.png
#
# Tip colors are assigned by case-insensitive regex matches against tip_label.
#   madamurpox: red
#   rousettus.bat.pox: blue
#   orf.virus: blue
#   black: all others
#
# Branches leading to internal nodes with support scores below branch_score_cutoff
# are colored red. The default cutoff is 80.
#
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  cat("Usage: graph_tree.R <treefile> <faa_file> <plot_title> [branch_score_cutoff]\n", file = stderr())
  quit(status = 2)
}

in_tree <- args[1]
in_faa  <- args[2]
plot_title <- args[3]
branch_score_cutoff <- if (length(args) >= 4) as.numeric(args[4]) else 80
if (is.na(branch_score_cutoff)) {
  cat("branch_score_cutoff must be numeric\n", file = stderr())
  quit(status = 2)
}

# debug
#in_tree <- "all_protein_aligns.faa.Qyeast_F_I_R6.treefile"
#in_faa <- "all_protein_aligns.faa"
#plot_title <-"Merged 25 protein tree MODEL:Qyeast_F_I_R6"

outpdf <- paste0(in_tree, ".pdf")
outpng <- paste0(in_tree, ".png")

suppressPackageStartupMessages({
  library(ape)
  library(ggtree)
  library(ggplot2)
})

# Parse FASTA headers:
# - id = first token after '>'
# - comment = the rest of the header line after the first whitespace (may be empty)
parse_faa_headers <- function(faa_path) {
  lines <- readLines(faa_path, warn = FALSE)
  hdrs <- lines[grepl("^>", lines)]
  hdrs <- sub("^>", "", hdrs)

  # split into id + rest
  ids <- sub("[[:space:]].*$", "", hdrs)
  rest <- ifelse(grepl("[[:space:]]", hdrs),
                 sub("^[^[:space:]]+[[:space:]]+", "", hdrs),
                 "")

  # If comment is empty, keep id as fallback label.
  labels <- ifelse(nzchar(rest), rest, ids)

  # Return named vector: names are ids, values are labels/comments
  setNames(labels, ids)
}

id_to_label <- parse_faa_headers(in_faa)

# Read tree (Newick)
tr <- read.tree(in_tree)

# Build label vector for tips in tree order
tip_ids <- tr$tip.label
tip_label <- tip_ids
mapped <- tip_ids %in% names(id_to_label)
tip_label[mapped] <- unname(id_to_label[tip_ids[mapped]])

node_color_rules <- c(
  "madamurpox" = "red",
  "rousettus.bat.pox" = "blue",
  "orf.virus" = "blue",
  "molluscum.contagiosum" = "green"
)

assign_node_color <- function(label) {
  for (pattern in names(node_color_rules)) {
    if (grepl(pattern, label, ignore.case = TRUE)) {
      return(unname(node_color_rules[[pattern]]))
    }
  }
  "black"
}

node_color_values <- c(black = "black", stats::setNames(unique(node_color_rules), unique(node_color_rules)))
node_color <- factor(
  vapply(tip_label, assign_node_color, character(1)),
  levels = names(node_color_values)
)

print("# Node_color:" )
summary(node_color)

parse_support_score <- function(label) {
  label <- trimws(label)
  first_number <- sub("^.*?([0-9]+(?:\\.[0-9]+)?).*$", "\\1", label)
  suppressWarnings(as.numeric(ifelse(grepl("[0-9]", label), first_number, NA)))
}

total_nodes <- length(tr$tip.label) + tr$Nnode
support_score <- rep(NA_real_, total_nodes)
branch_color <- rep("black", total_nodes)

if (!is.null(tr$node.label) && length(tr$node.label) > 0) {
  internal_nodes <- (length(tr$tip.label) + 1):total_nodes
  support_score[internal_nodes] <- parse_support_score(tr$node.label)
  branch_color[!is.na(support_score) & support_score < branch_score_cutoff] <- "red"
}

branch_color <- factor(branch_color, levels = c("black", "red"))

print(paste0("# Branch support cutoff: ", branch_score_cutoff))
summary(branch_color)

# Attach metadata so ggtree can map aesthetics
df <- data.frame(
  node = seq_len(total_nodes),
  tip_label = c(tip_label, rep(NA_character_, tr$Nnode)),
  node_color = factor(c(as.character(node_color), rep(NA_character_, tr$Nnode)),
                      levels = names(node_color_values)),
  support_score = support_score,
  branch_color = branch_color,
  stringsAsFactors = FALSE
)

# ---- Auto-size canvas to avoid truncation ----
ntip <- length(tr$tip.label)
max_chars <- if (length(tip_label) > 0) max(nchar(tip_label), na.rm = TRUE) else 10

# Heuristics tuned for typical phylo trees:
# - width grows with longest label
# - height grows with number of tips
# clamp so you don't accidentally make a billboard-sized PDF
width_in  <- min(30, max(8,  4 + 0.13 * max_chars))
height_in <- min(60, max(6,  2 + 0.25 * ntip))

dpi <- 300
width_px  <- as.integer(ceiling(width_in  * dpi))
height_px <- as.integer(ceiling(height_in * dpi))

# Increase text size 3x
tip_size <- 6	# was ~2
node_size <- 6	# was ~2

# Plot
p <- ggtree(tr) %<+% df +
  geom_tree(aes(color = branch_color)) +
  geom_tiplab(aes(label = tip_label, color = node_color),
  			size = tip_size
        ,offset = tip_size/20
#              		, align = FALSE
	      ) +
  scale_color_manual(values = node_color_values,
                     guide = "none") +
  ggtitle(plot_title) +
  theme(
	plot.title = element_text(hjust = 0.5, size = 18),
	plot.margin = margin(10, 200, 10, 10)  # add right margin space
  ) +
  geom_text2(aes(subset = !isTip, label = label),
             hjust = -0.2, size = node_size/2)

# Expand horizontal space
x_range <- diff(range(p$data$x, na.rm = TRUE))
x_expand <- x_range * 0.7   # increase if still clipped
px <- p +
  coord_cartesian(
    xlim = c(0, max(p$data$x, na.rm = TRUE) + x_expand),
    clip = "off"
  )

# Write PDF
pdf(outpdf, width = width_in, height = height_in, onefile = TRUE)
print(px)
dev.off()
message(paste0("wrote: (",width_in,"x",height_in,") ", outpdf))

# Write PNG
png(outpng, width = width_px, height = height_px, res = dpi)
print(px)
dev.off()
message(paste0("wrote: (",width_px,"x",height_px,") ", outpng))
