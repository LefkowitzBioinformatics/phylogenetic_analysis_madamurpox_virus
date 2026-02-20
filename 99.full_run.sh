#!/usr/bin/env bash
#
# run all pipeline steps in order
#
# may the force be with you

STEPS="\
     ./01.build_protein_db.sh \
     ./02.build_protein_faa.sh \
     ./03.align.sh \
     ./04.merge_protein_aligns.sh \
     ./05.build_tree.iqtree.sh \
     ./06.build_protein_trees.sh \
"

for STEP in $STEPS; do
    echo $STEP
    $STEP
    if [[ $? -ne 0 ]]; then
	echo "ERROR[$0] STEP FAILED: $STEP"
	exit 1
    fi
done

cat <<EOF
# ======================================================================
# SUCCESS: $0
# ======================================================================
EOF

exit 0
