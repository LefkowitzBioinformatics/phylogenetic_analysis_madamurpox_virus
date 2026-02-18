#!/usr/bin/env bash
#
# Compare two trees produced by iqtree under different models
#
source 00.set_env.sh

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
echo IQTREE2_EXE=$IQTREE2_EXE

TREE1="iqtree.$MODEL_FNAME1/merged_proteins.msa-muscle.faa.$MODEL_FNAME1.treefile"
TREE2="iqtree.$MODEL_FNAME2/merged_proteins.msa-muscle.faa.$MODEL_FNAME2.treefile"

for INP in $IQTREE $ALL_ALIGN_FAA $TREE1 $TREE2; do
    if [[ ! -e "$INP" ]]; then
	echo "ERROR: missing input: $INP"
	exit 1
    fi
done

# intermediate
TREES="merged_proteins.msa-muscle.candidates.treefile"

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
    echo $IQTREE2_EXE \
      -s "$ALL_ALIGN_FAA" \
      -m "$MODEL" \
      -z "$TREES" \
      -n 0 \
      -zb 10000 \
      -au \
      -nt AUTO \
      -pre "$CMP_OUT"
    $IQTREE2_EXE \
      -s "$ALL_ALIGN_FAA" \
      -m "$MODEL" \
      -z "$TREES" \
      -n 0 \
      -zb 10000 \
      -au \
      -nt AUTO \
      -pre "$CMP_OUT"

done
