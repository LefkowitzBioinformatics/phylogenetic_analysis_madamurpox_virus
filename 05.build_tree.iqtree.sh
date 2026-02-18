#!/usr/bin/env bash
#
#
# set-env
source 00.set_env.sh

#inputs
echo ALL_ALIGN_FAA=$ALL_ALIGN_FAA

echo "IQTREE2 version"
$IQTREE2 --version 

#
# align
#

# MFP=ModelFinderPlus - and it takes a long time to run
for MODEL in $IQTREE_MODELS; do
    SAFE_MODEL=$(echo "$MODEL" | tr '+' '_' | sed 's/\.//g' )
    echo "# ------------------------------------------------------------"
    echo "# MODEL = $MODEL ($SAFE_MODEL)"
    echo "# ------------------------------------------------------------"
    
    PREFIX="$(dirname ${ALL_ALIGN_FAA})/iqtree.$SAFE_MODEL/$(basename ${ALL_ALIGN_FAA}).${SAFE_MODEL}"

    # skip, if already computed
    if [[ -s ${PREFIX}.treefile ]]; then
	echo "# SKIP: ${PREFIX}.treefile "
    else
       
	# create output dir
	mkdir -p $(dirname $PREFIX)
	if [[ $? -ne 0 ]]; then
	    echo "ERROR[$0] could not create output dir: $(dirname $PREFIX)"
	    exit 1
	fi
	
	#
	# build tree
	#
	$IQTREE2 \
	    $* \
	    -s $ALL_ALIGN_FAA \
	    -m "$MODEL" \
	    -B 1000 \
	    -nt AUTO \
	    -pre "$PREFIX"
	RC=$?
	echo RC=$RC
	if [[ $RC -ne 0 ]]; then
	    echo "ERROR[$0] iqtree2 failed; see ${PREFIX}.log"
	    exit 1
	fi
	
	echo "# OUTPUTS:"
	ls -lstra ${PREFIX}*

    fi

    
    echo "# Draw tree"
    TREE=${PREFIX}.treefile
    PDF=${TREE}.pdf
    PNG=${TREE}.png
    echo Rscript $GRAPH_TREE $TREE $ALL_ALIGN_FAA "'MODEL: $MODEL'"
    Rscript $GRAPH_TREE $TREE $ALL_ALIGN_FAA "MODEL: $MODEL"
    ls -lstra $PDF $PNG
done
