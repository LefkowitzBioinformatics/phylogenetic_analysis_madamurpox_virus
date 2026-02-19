#!/usr/bin/env bash
cat <<EOF
#
# show differences in merged MUSCLE MSA
#
EOF
echo "git diff -i -u -- new_align/merged_proteins.msa-muscle.faa | dwdiff -i -u -P --color -d 0123456789-"
git diff -i -u -- new_align/merged_proteins.msa-muscle.faa | dwdiff -i -u -P --color -d 0123456789- 
if [[ $? -eq 0 ]]; then echo "NO DIFFERENCES"; fi
