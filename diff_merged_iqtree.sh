#!/usr/bin/env bash
cat <<EOF
#
# show differences in IQTREE2 treefile
#
EOF
echo "git diff -i -u -- new_align/iqtree.Qyeast_F_I_R6/merged_proteins.msa-muscle.faa.Qyeast_F_I_R6.treefile  | dwdiff -i -u -P --color -d 0123456789 "
git diff -i -u -- new_align/iqtree.Qyeast_F_I_R6/merged_proteins.msa-muscle.faa.Qyeast_F_I_R6.treefile  | dwdiff -i -u -P --color -d 0123456789 
if [[ $? -eq 0 ]]; then echo "NO DIFFERENCES"; fi
