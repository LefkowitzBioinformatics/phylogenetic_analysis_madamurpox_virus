#!/usr/bin/env bash
#
# build a single FASTA with all the proteins
#
# This fasta may contain additional proteins part of
# the core gene set. That's ok. We'll be building
# the core gene fasta by protein accession numbers.
#
#

# set-env
source 00.set_env.sh $*

# sources
OLD_PROTEIN_DIR="$SRC_SEQ_DIR/ictv_report"
NEW_GENOME_DIR="$SRC_SEQ_DIR/new_genomes"
GENBANK_DIR="$SRC_SEQ_DIR/genbank"
	  


cat <<EOF
# ----------------------------------------------------------------------
#
# merge source fasta
#
# ----------------------------------------------------------------------
EOF

#
# beware of filenames with spaces in OLD_PROTEIN_DIR
#
echo "SCANNING: $SRC_SEQ_DIR/"

if [[ ! -d "$SRC_SEQ_DIR" ]]; then
    echo "ERROR: $0 input directory missing: $OLD_PROTEIN_DIR" > /dev/stderr
    exit 1
fi
FAA_CT=$(find $SRC_SEQ_DIR \( -name "*.faa" -o -name "sequence.fasta.txt" \) | wc -l)
if [[ "$FAA_CT" -le 0 ]]; then
    echo "ERROR[$0] no .faa or sequence.fasta.txt files found in $SRC_SEQ_DIR" > /dev/stderr
    exit 1
fi

echo "READING: "
find $SRC_SEQ_DIR \( -name "*.faa" -o -name "sequence.fasta.txt" \) -exec cat {} +  > $SRC_PROTEINS_DB_FAA
find $SRC_SEQ_DIR \( -name "*.faa" -o -name "sequence.fasta.txt" \) -exec grep -c ">" {} +  

cat <<EOF
#
# index result
#
EOF
echo samtools faidx $SRC_PROTEINS_DB_FAA
samtools faidx $SRC_PROTEINS_DB_FAA

# QC line count
SEQ_DB_CT=$(grep '>'  $SRC_PROTEINS_DB_FAA | wc -l)
SRC_SEQ_CT=$(find $SRC_SEQ_DIR \( -name "*.faa" -o -name "sequence.fasta.txt" \) -exec grep '>' {} + | wc -l )
echo "TOTAL SRC Sequences: $SRC_SEQ_CT"
echo "$SRC_PROTEINS_DB_FAA:    $SEQ_DB_CT"
if [[ "$SRC_SEQ_CT" -ne "$SEQ_DB_CT" ]]; then
     echo "ERROR[$0]: final all-proteins databases does not have same number of sequences as the sources"
     exit 1
fi
echo "# ===================================="
echo "# SUCCESS: $0 $*"
echo "# ===================================="
