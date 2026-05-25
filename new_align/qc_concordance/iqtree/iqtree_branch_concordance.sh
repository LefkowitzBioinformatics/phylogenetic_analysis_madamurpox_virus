#!/usr/bin/env bash
cat <<EOF
#
# use IQ-Tree to compute "concordance factors" between the gene trees and the concatenated one
#
#
EOF
SCRIPT_DIR="../../../scripts"
CONCAT_TREEFILE="../../iqtree.Qyeast_F_I_R6/merged_proteins.msa-muscle.faa.Qyeast_F_I_R6.treefile"
LOCI_TREEFILE="./loci.treefile"
GENE_TREE_DIR="../../protein_groups"
IQTREE2_EXE=~/Applications/iqtree2

cat <<EOF
CONCAT_TREEFILE=$CONCAT_TREEFILE
LOCI_TREEFILE=$LOCI_TREEFILE
GENE_TREE_DIR=$GENE_TREE_DIR
IQTREE2_EXE=$IQTREE2_EXE
EOF

cat <<EOF
#
# build loci tree file
#
find $GENE_TREE_DIR -name '*.treefile' -exec cat {} + > $LOCI_TREEFILE
EOF
find $GENE_TREE_DIR -name '*.genome.treefile' -exec cat {} + \
    | sed 's/AF380138-monkeypox_virus_-clade_I/AF380138-monkeypox_virus__clade_I_/g' \
    | sed 's/AY753185-monkeypox_virus_-clade_IIa/AY753185-monkeypox_virus__clade_IIa_/g' \
     > $LOCI_TREEFILE
wc -l $LOCI_TREEFILE

cat <<EOF
#
# analyze vs merged
#
$IQTREE2_EXE \
  -nt 10 \
  -t $CONCAT_TREEFILE \
  --gcf $LOCI_TREEFILE \
  --prefix concordance
EOF

$IQTREE2_EXE \
  -nt 10 \
  -t $CONCAT_TREEFILE \
  --gcf $LOCI_TREEFILE \
  --prefix concordance


cat<<EOF
#
# PDF render trees
#
Rscript $SCRIPT_DIR/plot_iqtree_concordance.R .
EOF
Rscript $SCRIPT_DIR/plot_iqtree_concordance.R .

