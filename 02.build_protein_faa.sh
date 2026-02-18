#!/usr/bin/env bash
#
# using our master accessions/metadata table,
# create one .faa per core protein,
# insuring the same genome order in each .faa
#
#
# set-env
source 00.set_env.sh

# inputs
echo WC META=$(wc -l $META)
echo WC SRC_PROTEINS_DB_FAA=$(wc -l $SRC_PROTEINS_DB_FAA)

# scripts
AWK_GET_GROUP_ACC_LIST=$SCRIPT_DIR/02.build_protein_faa.get_group_acc_list.awk
AWK_PROT_HEADER=$SCRIPT_DIR/02.build_protein_faa.gene_header.awk
# QC
for SCRIPT in $AWK_GET_GROUP_ACC_LIST $AWK_PROT_HEADER; do
    if [[ ! -e "$SCRIPT" ]]; then
	echo "ERROR[$0]: script source missing: $SCRIPT" > /dev/stderr
	exit 1
    fi
done

# WARNING: these column name/ordinal mappings appear in the AWK scripts, too.
# head -1 protein_lists/AllProteins.txt | sed 's/\t/\n/g' | egrep -n .
# 1:GeneOrder
# 2:GroupName
# 3:GroupProteinFunction
# 4:GeneAccession
# 5:GeneLink
# 6:GeneProteinFunction
# 7:IsolateName
# 8:IsolateAccession
# 9:isIsolate
# 10:GroupNameGood
# 11:Fence
# 12:GenomeAcc
# 13:NcbiIsolateName
# 14:GenomeOrder
# 15:inNewPoxAlign

# gene names
# to prefix with ordinal: awk '{ printf "poxcore%02d-%s\n", $1, $2 }')
CORE_PROT_NAMES_ORD=$(sort -t $'\t' -k1n $META | grep -v GroupName | cut -f 2 | uniq)
if [ $? -ne 0 ]; then echo ERROR parsing $META; exit 1; fi
echo CORE_PROT_NAMES_ORD=$CORE_PROT_NAMES_ORD

# genome count
echo GENOME_CT=${GENOME_CT}

# for each group
for PROT_NAME in $CORE_PROT_NAMES_ORD; do
    echo "# ------ $PROT_NAME -------"
    PROT_DIR=$PROT_GROUPS_DIR/$PROT_NAME
    PROT_FAA=$PROT_DIR/sequence.faa.txt

    # create
    mkdir -p $PROT_DIR
    if [[ ! -d $PROT_DIR ]]; then
	echo "ERROR[$0]: output dir missing: $PROT_DIR"
	exit 1
    fi

    echo -n "" >  $PROT_FAA

    # debug
    echo awk -v TargGroup="$PROT_NAME" -v inAlignCol=15 -f $AWK_GET_GROUP_ACC_LIST $META |sort -t $'\t' -k2n 
    awk -v TargGroup="$PROT_NAME" -v inAlignCol=15 -f $AWK_GET_GROUP_ACC_LIST $META |sort -t $'\t' -k2n 
    if [ $? -ne 0 ]; then echo ERROR parsing $META with $AWK_GET_GROUP_ACC_LIST  ; exit 1; fi
    
    PROT_ACC_ORDERED=$(awk -v TargGroup="$PROT_NAME" -v inAlignCol=15 -f $AWK_GET_GROUP_ACC_LIST $META|sort -t $'\t' -k2n | cut -f 1)
    if [ $? -ne 0 ]; then echo ERROR parsing $META with $AWK_GET_GROUP_ACC_LIST; exit 1; fi
    echo PROT_ACC_ORDERED=$PROT_ACC_ORDERED
    
    #
    # extract those proteins in that order, building headers
    #
    for PROT_ACC in $PROT_ACC_ORDERED; do
	# get genome name and accession
	PROT_HEADER=$(awk -v TargAccession="$PROT_ACC" -f $AWK_PROT_HEADER $META)
	if [ $? -ne 0 ]; then echo ERROR parsing $META with $AWK_PROT_HEADER ; exit 1; fi
	echo ">$PROT_HEADER" 
	echo ">$PROT_HEADER" >> $PROT_FAA
	echo samtools faidx $SRC_PROTEINS_DB_FAA $PROT_ACC \>\> $PROT_FAA
	samtools faidx $SRC_PROTEINS_DB_FAA $PROT_ACC | tail -n +2  >> $PROT_FAA
    done

    # debug - stop after first group
    #exit 1
    
done

echo "# QC "
PROT_CT=$(ls -1 $PROT_GROUPS_DIR/*/sequence.faa.txt | wc -l)
if [[ "$CORE_PROT_CT" -ne "$PROT_CT" ]]; then
    echo "ERROR[$0]: there are $PROT_CT .faa, but $CORE_PROT_CT protein groups"
    find $PROT_GROUPS_DIR -name "sequence.faa.txt" -exec ls -lstr {} +
    exit 1
else
    echo "OK: there are $PROT_CT .faa's == $CORE_PROT_CT protein groups"
fi
for PROTEIN_FAA in  $PROT_GROUPS_DIR/*/sequence.faa.txt; do
    FAA_SEQ_CT=$(grep -c ">" $PROTEIN_FAA)
    if [[ "$FAA_SEQ_CT" -ne "$GENOME_CT" ]]; then
	echo "ERROR[$0]: incorrect sequence count for core protein $PROTEIN_FAA"
	exit 1
    else
	echo "OK: $FAA_SEQ_CT==$GENOME_CT for $PROTEIN_FAA"
    fi
done

echo "# ===================================="
echo "# SUCCESS:$0 $*"
echo "# ===================================="

exit 0
