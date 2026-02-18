#!/usr/bin/env Rscript

# Usage:
#   ./graph_tree.R <treefile> <proteins.faa> <plot_title>
#
# Outputs:
#   <treefile>.pdf
#   <treefile>.png
#
# Colors
#   red: MNB 
#   blue: AYY386264, PP711852
#   black: all others
#
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  cat("Usage: graph_tree.R <treefile> <faa_file> <plot_title>\n", file = stderr())
  quit(status = 2)
}

in_tree <- args[1]
in_faa  <- args[2]
plot_title <- args[3]

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

# Color rule: anything containing "MNB" in the label (or in the original id if you prefer)
node_color <- factor(
  ifelse(grepl("^MNB", tip_ids), "red",
         ifelse(grepl("^(AY386264|PP711852)", tip_ids), "blue", "black")),
  levels = c("black", "red", "blue")
)

print("# Node_color:" )
node_color

# Attach metadata so ggtree can map aesthetics
df <- data.frame(
  label = tip_ids,              # must match tree tip labels for %<+%
  tip_label = tip_label,
  node_color = node_color,
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
  geom_tiplab(aes(label = tip_label, color = node_color),
  			size = tip_size
        ,offset = tip_size/20
#              		, align = FALSE
	      ) +
  scale_color_manual(values = c(black = "black",
                                red = "red",
                                blue = "blue"),
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

