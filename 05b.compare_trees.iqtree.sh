#!/usr/bin/env bash
#
# Compare two trees produced by iqtree under different models
#

# config
MODELS="Q.yeast+F+I+R6 LG+I+G4+F"
echo MODELS="'$MODELS'"

MODEL1=$(echo $MODELS|cut -d " " -f 1)
MODEL2=$(echo $MODELS|cut -d " " -f 2)
MODEL_FNAME1=$(echo $MODEL1 | tr "+" "_" | sed 's/\.//g')
MODEL_FNAME2=$(echo $MODEL2 | tr "+" "_" | sed 's/\.//g')
MODEL_ABBREV1=$(echo $MODEL_FNAME1 | cut -d _ -f 1)
MODEL_ABBREV2=$(echo $MODEL_FNAME2 | cut -d _ -f 1)

#inputs
IQTREE2=/Applications/iqtree2
echo IQTREE2=$IQTREE2

ALL_ALIGN_FAA=all_protein_aligns.faa
TREE1="all_protein_aligns.faa.$MODEL_FNAME1.treefile"
TREE2="all_protein_aligns.faa.$MODEL_FNAME2.treefile"

for INP in $IQTREE $ALL_ALIGN_FAA $TREE1 $TREE2; do
    if [[ ! -e "$INP" ]]; then
	echo "ERROR: missing input: $INP"
	exit 1
    fi
done

# intermediate
TREES="all_protein_aligns.candidates.treefile"

# output
CMP_MODEL1="topotest_$MODEL_ABBREV1"
CMP_MODEL2="topotest_$MODEL_ABBREV2"

#
# merge trees into tmp file
#
echo cat "$TREE1 $TREE2 > $TREES"
cat $TREE1 $TREE2 > $TREES
ls -lstra $TREE1 $TREE2 $TREES

#
# CMP under each model
#
for MODEL in $MODELS; do

    if [[ "$MODEL" == "$MODEL1" ]]; then
	CMP_OUT=$CMP_MODEL1
    elif [[ "$MODEL" == "$MODEL2" ]]; then
	CMP_OUT=$CMP_MODEL2
    else
	echo "INTERNAL ERROR: $MODEL into in [$MODEL1, $MODEL2]"
	exit 1
    fi

    #
    # compare under a model
    #
    echo $IQTREE2 \
      -s "$ALL_ALIGN_FAA" \
      -m "$MODEL" \
      -z "$TREES" \
      -n 0 \
      -zb 10000 \
      -au \
      -nt AUTO \
      -pre "$CMP_OUT"
    $IQTREE2 \
      -s "$ALL_ALIGN_FAA" \
      -m "$MODEL" \
      -z "$TREES" \
      -n 0 \
      -zb 10000 \
      -au \
      -nt AUTO \
      -pre "$CMP_OUT"

done
