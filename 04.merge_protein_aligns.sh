#!/usr/bin/env bash
#
# using our master accessions/metadata table to order the proteins,
# merge the per-protein alignments into a "core protein" alignment
#
# each alignment has the genomes in whatever order Muscle output them,
# so we must forceably re-unite the genes from each genome.
#

# set-env
source 00.set_env.sh $*

# ----------------------------------------------------------------------
# inputs
# ----------------------------------------------------------------------
echo META rows=$(wc -l $META)
echo ALL_ALIGN_RAW=$ALL_ALIGN_RAW
echo ALL_ALIGN_FAA=$ALL_ALIGN_FAA

# scripts
AWK_GENOME_HEADER=$SCRIPT_DIR/04.merge_protein_aligns.sh.genome_header.awk
AWK_PROT_FROM_GROUP_GENOME=$SCRIPT_DIR/04.merge_protein_aligns.sh.gene_from_group_genome.awk
# QC
for SCRIPT in $AWK_GENOME_HEADER; do
    if [[ ! -e "$SCRIPT" ]]; then
	echo "ERROR[$0]: script source missing: $SCRIPT" > /dev/stderr
	exit 1
    fi
done

cat <<EOF
#
# check input MSAs
#
# GENOME_CT=$GENOME_CT
EOF
ALIGN_MSAS="$PROT_GROUPS_DIR/*/$PROT_ALIGN_MSA_FNAME"
for MSA in $ALIGN_MSAS; do
    SEQ_CT=$(grep -c ">" $MSA)
    if [[ $SEQ_CT -ne $GENOME_CT ]]; then
	echo "ERROR[$*] there are $GENOME_CT genomes, but $SEQ_CT sequences in $MSA"
	exit 1
    else
	echo "OK: $SEQ_CT sequences found in $MSA"
    fi
done


# extract from META
echo "CORE_PROT_NAMES_ORD N=" $(echo $CORE_PROT_NAMES_ORD|sed 's/ /\n/g' | awk 'END{print NR}') " : " $CORE_PROT_NAMES_ORD
echo GENOME_ACCESSIONS_ORD N=$(echo $GENOME_ACCESSIONS_ORD | sed 's/ /\n/g'  | awk 'END{print NR}') :  $GENOME_ACCESSIONS_ORD

# setup output file
echo -n "" > $ALL_ALIGN_RAW

# for each genome
for GENOME_ACC in $GENOME_ACCESSIONS_ORD; do
    echo "# ------ $GENOME_ACC -------"

    # add header to output FAA
    GENOME_HEADER=$(awk -v TargAccession="$GENOME_ACC" -f $META_AWK -f $AWK_GENOME_HEADER $META | uniq)
    if [[ $? -ne 0 || -z "$GENOME_HEADER" ]]; then
	echo "ERROR[$0 $*] running 'awk -v TargAccession=\"$GENOME_ACC\" -f $META_AWK -f $AWK_GENOME_HEADER $META | uniq'"
	exit 1
    fi
    echo GENOME_HEADER=">$GENOME_HEADER"
    echo ">$GENOME_HEADER" >> $ALL_ALIGN_RAW
    #
    # for each group, in order, building up coore genes for the genome
    #
    for PROT_NAME in $CORE_PROT_NAMES_ORD; do 
	echo -e "\t# ------ $PROT_NAME -------"
	PROT_DIR=$PROT_GROUPS_DIR/$PROT_NAME
	PROT_FAA=$PROT_DIR/$PROT_ALIGN_MSA_FNAME

	# debug
	PROT_ACC=$(awk -v TargGenome="$GENOME_ACC" -v TargGroup="$PROT_NAME" -f $META_AWK -f $AWK_PROT_FROM_GROUP_GENOME $META |sort -t $'\t' -k2n)
	if [[ $? -ne 0 || -z "$PROT_ACC" ]]; then
	    echo "ERROR[$*] running $AWK_PROT_FROM_GROUP_GENOME on $META"
	    exit 1
	fi
	echo -e "\tPROT_ACC=$PROT_ACC"

	# extract sequence w/o header
	RC=$(samtools faidx $PROT_FAA $PROT_ACC 2> .tmp.rc | tail -n +2 >> $ALL_ALIGN_RAW)
	if [[ $? -ne 0 || ! -f .tmp.rc ||  -s .tmp.rc ]]; then
	    echo "ERROR: PROTEIN SEQ MISSING: $GENOME_HEADER / $PROT_NAME / $PROT_ACC "
	    echo "samtools faidx $PROT_FAA $PROT_ACC"
	    cat .tmp.rc
	    exit 1
	fi
	# blank line after each gene
	echo "" >> $ALL_ALIGN_RAW
	
	# debug - stop after first group
	# exit 1
	
    done

done

echo "# QC: genome count in merged MSA"
for MSA in $ALL_ALIGN_RAW; do
    SEQ_CT=$(grep -c ">" $MSA)
    if [[ $SEQ_CT -ne $GENOME_CT ]]; then
	echo "ERROR[$*] there are $GENOME_CT genomes, but $SEQ_CT sequences in $MSA"
	exit 1
    else
	echo "OK: $SEQ_CT sequences found in $MSA"
    fi	
done

cat <<EOF
#
# word-wrap resulting .faa
#
EOF
echo "seqtk seq -l60 $ALL_ALIGN_RAW > $ALL_ALIGN_FAA"
seqtk seq -l60 $ALL_ALIGN_RAW > $ALL_ALIGN_FAA
if [[ $? -ne 0 || ! -s "$ALL_ALIGN_FAA" ]]; then
   echo "ERROR: seqtk failed on $ALL_ALIGN_RAW"
   exit 1
fi
# clean up temp file
rm $ALL_ALIGN_RAW

cat <<EOF
# ====================================
# QC final MSA
# ====================================
EOF
for MSA in $ALL_ALIGN_FAA; do
    SEQ_CT=$(grep -c ">" $MSA)
    if [[ $SEQ_CT -ne $GENOME_CT ]]; then
	echo "ERROR[$*] there are $GENOME_CT genomes, but $SEQ_CT sequences in $MSA"
	exit 1
    else
	echo "OK: $SEQ_CT sequences found in $MSA"
    fi	
done

echo "# ===================================="
echo "# SUCCESS:$0 $*"
echo "# ===================================="
