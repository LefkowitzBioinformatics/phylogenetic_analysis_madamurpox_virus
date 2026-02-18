#!/usr/bin/env bash
#
#
source 00.set_env.sh

# gene names
# to prefix with ordinal: awk '{ printf "poxcore%02d-%s\n", $1, $2 }')
echo CORE_PROT_NAMES_ORD=$CORE_PROT_NAMES_ORD

#
# for each gene
#
for PROT_NAME in $CORE_PROT_NAMES_ORD; do
    echo "# ----------------------------------------------------------------------------"
    echo "# ------ $PROT_NAME -------"
    echo "# ----------------------------------------------------------------------------"
    PROT_DIR=$PROT_GROUPS_DIR/$PROT_NAME
    PROT_ALIGN_MSA=$PROT_DIR/$PROT_ALIGN_MSA_FNAME
    echo PROT_ALIGN_MSA=$PROT_ALIGN_MSA

    # QC
    if [[ ! -d $PROT_DIR ]]; then
	echo "PROT_DIR: ERROR NO EXIST: $PROT_DIR"
	exit 1
    fi

    echo "IQTREE2 version"
    $IQTREE2_EXE --version

    #echo "RAXML version"
    #$RAXML --version | tee $PROT_DIR/version.raxml.txt

    # MFP = model finder plus - tries them all, very slow
    #MODEL="MFP"
    MODEL=$IQTREE_FINAL_MODEL
    MODEL_SAFE=$IQTREE_FINAL_MODEL_SAFE
    PREFIX="$(dirname ${PROT_ALIGN_MSA})/iqtree.${MODEL_SAFE}/$(basename ${PROT_ALIGN_MSA}).${IQTREE_FINAL_MODEL_SAFE}"
    
    # skip, if already computed
    if [[ -s ${PREFIX}.treefile ]]; then
	echo "# SKIP: exists ${PREFIX}.treefile "
    else
	echo "# "
	echo "# (PROTEIN $PROT_NAME) Tree Build IQTREE2; model=${MODEL}"
	echo "#"
	mkdir -p $(dirname $PREFIX)

	echo $IQTREE2_EXE \
	     -s $PROT_ALIGN_MSA \
	     -m "$MODEL" \
	     -B 1000 \
	     -nt AUTO \
	     -pre "$PREFIX" 
	$IQTREE2_EXE \
	    -s $PROT_ALIGN_MSA \
	    -m "$MODEL" \
	    -B 1000 \
	    -nt AUTO \
	    -pre "$PREFIX"
	RC=$?
	echo RC=$RC
	if [[ $RC -ne 0 ]]; then
	    echo "ERROR[$0]: iqtree2 failed; see ${PREFIX}.log"
	    exit 1
	fi
    fi
#    echo "# "
#    echo "# Tree Build RAXML"
    # echo "# "
    # echo $RAXML --all \
    # 	   --msa $PROT_ALIGN_MSA \
    # 	   --model "LG+I+G4+F" \
    # 	   --bs-trees 1000 \
    # 	   --threads auto{MAX} \
    # 	   --workers auto{5} \
    # 	  2>&1 \
    # 	  | tee $PROT_DIR/log.raxml.txt
    # $RAXML --all \
    # 	   --msa $PROT_ALIGN_MSA \
    # 	   --model "LG+I+G4+F" \
    # 	   --bs-trees 1000 \
    # 	   --threads auto{MAX} \
    # 	   --workers auto{5} \
    # 	  2>&1 \
    # 	  | tee -a $PROT_DIR/log.raxml.txt

    # RAXML_RC=$?
    # echo RAXML_RC=$RAXML_RC

done
