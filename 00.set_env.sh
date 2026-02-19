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
META_AWK=protein_lists/AllProteins.coldefs.awk
source protein_lists/AllProteins.coldefs.sh

if [[ ! -s "$META" ]]; then
    echo "ERROR[${0}:00_set_env.sh $*]: missing or empty METADATA file: $META"
    exit 1
elif [[ "-v" == "$1" ]]; then
    echo "OK: $(wc -l $META)"
fi
    
SRC_SEQ_DIR=src_sequences

# extract from META
GENOME_ACCESSIONS_ORD=$(sort -t $'\t' -k${META_GenomeOrder}n $META | grep -v GroupName | awk -f $META_AWK -f scripts/00_included_genome_accessions.awk |  uniq)
if [[ "-v" == "$1" ]]; then echo GENOME_ACCESSIONS_ORD=$GENOME_ACCESSIONS_ORD; fi

GENOME_CT=$(awk -f $META_AWK -f scripts/00_included_genome_accessions.awk $META | sort | uniq | wc -l )
if [[ "-v" == "$1" ]]; then echo GENOME_CT=$GENOME_CT; fi
if [[ $? -ne 0 ]]; then echo ERROR parsing $META; exit 1; fi
if [[ "$GENOME_CT" -lt 1 ]]; then
    echo "ERROR[${0}:00_set_env.sh $*]: invalid GENOME_CT=$GENOME_CT (from $META)"
    exit 1
fi

CORE_PROT_NAMES_ORD=$(sort -t $'\t' -k${META_GeneOrder}n $META | grep -v GroupName | cut -f ${META_GroupName} | egrep -v '^$'| uniq)
if [[ "-v" == "$1" ]]; then echo CORE_PROT_NAMES_ORD=$CORE_PROT_NAMES_ORD; fi

CORE_PROT_CT=$(awk -f $META_AWK -f scripts/00_included_group_names.awk $META | sort | uniq | wc -l)
if [[ "-v" == "$1" ]]; then echo CORE_PROT_CT=$CORE_PROT_CT; fi 
if [[ $? -ne 0 ]]; then echo ERROR parsing $META; exit 1; fi
if [[ "$CORE_PROT_CT" -ne 25 ]]; then
    echo "ERROR[${0}:00_set_env.sh $*]: invalid CORE_PROT_CT=$CORE_PROT_CT (from $META)"
    echo "ERROR[${0}:00_set_env.sh $*]: expected at least 25 core protein groups"
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

# hand-installed apps
IQTREE2_EXE=~/Applications/iqtree2
MUSCLE_EXE=~/Applications/muscle-osx-arm64.v5.3
for APP_EXE in $IQTREE2_EXE $MUSCLE_EXE; do
    if [[ ! -e "$APP_EXE" ]]; then
	echo "ERROR[${0}:00_set_env.sh $*] missing application: $APP_EXE"
	exit 1
    fi
done 

# brew apps
for EXE in blastn samtools seqtk snakemake gcc Rscript pdfunite ; do
    if [[ -z "$(which $EXE 2>/dev/null)" ]]; then
	echo "ERROR[${0}:00_set_env.sh $*] missing exe: $EXE"
	exit 1
    elif [[ "-v" == "$1" ]]; then
	echo "OK[${0}:00_set_env.sh $*] found $EXE"
    fi
done

# R libraries
for RLIB_NAME in ape ggplot2 ggtree; do
    Rscript -e "library($RLIB_NAME)" > /dev/null 2>&1  
    if [[ $? -ne 0 ]]; then
	echo "ERROR[${0}:00_set_env.sh $*] R library '$RLIB_NAME' not installed (see README.md)"
	exit 1
    elif [[ "-v" == "$1" ]]; then
	echo "OK[${0}:00_set_env.sh $*] found R library $RLIB_NAME"
    fi
done

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
    echo "ERROR[${0}:00_set_env.sh $*]: output dir missing: $ALIGN_DIR"
    exit 1
elif [[ "-v" == "$1" ]]; then
    echo "OK[${0}:00_set_env.sh $*] exists ALIGN_DIR=$ALIGN_DIR"
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
if [[ "-v" == "$1" ]]; then echo "OK[${0}:00_set_env.sh $*] SRC_PROTEINS_DB_FAA=$SRC_PROTEINS_DB_FAA"; fi


#
# individual protein alignments
#
# terminal filename; found in $ALIGN_DIR/protein_groups/$PROT_GROUP/
#
PROT_GROUPS_DIR=$ALIGN_DIR/protein_groups
if [[ "-v" == "$1" ]]; then echo "OK[${0}:00_set_env.sh $*] PROT_GROUPS_DIR=$PROT_GROUPS_DIR"; fi

PROT_ALIGN_MSA_FNAME=sequence.msa-muscle.faa.txt
if [[ "-v" == "$1" ]]; then echo "OK[${0}:00_set_env.sh $*] PROT_ALIGN_MSA_FNAME=$PROT_ALIGN_MSA_FNAME"; fi



#
# merged core proteins alignments
#
ALL_ALIGN_RAW=$ALIGN_DIR/merged_proteins.msa-muscle.raw.faa
ALL_ALIGN_FAA=$ALIGN_DIR/merged_proteins.msa-muscle.faa
if [[ "-v" == "$1" ]]; then echo "OK[${0}:00_set_env.sh $*] ALL_ALIGN_RAW=$ALL_ALIGN_RAW"; fi
if [[ "-v" == "$1" ]]; then echo "OK[${0}:00_set_env.sh $*] ALL_ALIGN_FAA=$ALL_ALIGN_FAA"; fi
	
# ----------------------------------------------------------------------
#
# done
#
# ----------------------------------------------------------------------

if [[ "-v" == "$1" ]]; then
    echo "# ----------------------------------------------------------------------"
    echo "OK[${0}:00_set_env.sh $*] Env setup/check SUCCESSFUL"
    echo "# ----------------------------------------------------------------------"
fi
