#
# Settings
#
# this is source'd be each script to get common settings
#

# ----------------------------------------------------------------------
#
# inputs
# 
# ----------------------------------------------------------------------

META=protein_lists/AllProteins.txt

SRC_SEQ_DIR=src_sequences

# extract from META
GENOME_ACCESSIONS_ORD=$(sort -t $'\t' -k14n $META | grep -v GroupName | awk 'BEGIN{FS="\t";IsolateAccession=8;inAlignCol=15}{sub(/\r$/,"",$0)}($inAlignCol=="Y"){print $IsolateAccession}'| uniq)

GENOME_CT=$(awk 'BEGIN{FS="\t";GenomeOrder=14;inNewPoxAlign=15}(tolower(substr($inNewPoxAlign,1,1))=="y"){print $GenomeOrder}' $META | sort | uniq | wc -l)
if [ $? -ne 0 ]; then echo ERROR parsing $META; exit 1; fi
if [[ "$GENOME_CT" -lt 1 ]]; then
    echo "ERROR[$0]: invalid GENOME_CT=$GENOME_CT (from $META)"
    exit 1
fi

CORE_PROT_NAMES_ORD=$(sort -t $'\t' -k1n $META | grep -v GroupName | cut -f 2 | egrep -v '^$'| uniq)

CORE_PROT_CT=$(awk 'BEGIN{FS="\t";GroupName=2;inNewPoxAlign=15}(tolower(substr($inNewPoxAlign,1,1))=="y"){print $GroupName}' $META | sort | uniq | wc -l)
if [ $? -ne 0 ]; then echo ERROR parsing $META; exit 1; fi
if [[ "$CORE_PROT_CT" -ne 25 ]]; then
    echo "ERROR[$0]: invalid CORE_PROT_CT=$CORE_PROT_CT (from $META)"
    echo "ERROR[$0]: expected at least 25 core protein groups"
    exit 1
fi


IQTREE_MODELS="MFP Q.yeast+F+I+R6 LG+I+G4+F"
IQTREE_MODEL_SAFE=$(echo "$IQTREE_MODELS" | tr '+' '_' | sed 's/\.//g' )

IQTREE_FINAL_MODEL="Q.yeast+F+I+R6"
IQTREE_FINAL_MODEL_SAFE=$(echo "$IQTREE_FINAL_MODEL" | tr '+' '_' | sed 's/\.//g' )


# ----------------------------------------------------------------------
#
# INTERNALS
#
# ----------------------------------------------------------------------

# config
SCRIPT_DIR=./scripts
GRAPH_TREE=$SCRIPT_DIR/graph_tree.R

IQTREE2=/Applications/iqtree2

# ----------------------------------------------------------------------
#
# outputs
#
# ----------------------------------------------------------------------


#
# output directory
#
ALIGN_DIR=./new_align
mkdir -p ./new_align
if [[ ! -d $ALIGN_DIR ]]; then
    echo "ERROR[$0]: output dir missing: $ALIGN_DIR"
    exit 1
fi

#
# "database" of all protein sequences from all genomes
#
# (internal/temp file)
#
# we pull the proteins we need from this to make our
# protein  fastas
#
SRC_PROTEINS_DB_FAA=$ALIGN_DIR/src_proteins_cache.faa


#
# individual protein alignments
#
# terminal filename; found in $ALIGN_DIR/protein_groups/$PROT_GROUP/
#
PROT_GROUPS_DIR=$ALIGN_DIR/protein_groups

PROT_ALIGN_MSA_FNAME=sequence.msa-muscle.faa.txt



#
# merged core proteins alignments
#
ALL_ALIGN_RAW=$ALIGN_DIR/merged_proteins.msa-muscle.raw.faa
ALL_ALIGN_FAA=$ALIGN_DIR/merged_proteins.msa-muscle.faa
