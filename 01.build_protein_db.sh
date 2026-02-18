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
source 00.set_env.sh

# sources
OLD_PROTEIN_DIR="$SRC_SEQ_DIR/ictv_report"
NEW_POX_FAA="$SRC_SEQ_DIR/madamurpox_isolate_MNB22_067_17/madamurpox_isolate_MNB22_067_17.faa"
GENBANK_FAAS=" \
	  $SRC_SEQ_DIR/genbank/MF467280-Western_grey_kangaroopox_virus.faa \
	  $SRC_SEQ_DIR/genbank/PP711852-Rousettus_bat_poxvirus_isolate_1A-Uganda-UGR70-2019.faa \
	  $SRC_SEQ_DIR/genbank/PP711852-Rousettus_bat_poxvirus_isolate_1A-Uganda-UGR70-2019.tblastn.faa \
"
	  


cat <<EOF
# ----------------------------------------------------------------------
#
# merge source fasta
#
# ----------------------------------------------------------------------
EOF

#
# beware of filenames with spaces in OLD_PROTEIN_DIr
#

echo "SCANNING: $OLD_PROTEIN_DIR"

if [[ ! -d "$OLD_PROTEIN_DIR" ]]; then
    echo "ERROR: $0 input directory missing: $OLD_PROTEIN_DIR" > /dev/stderr
    exit 1
fi
PROT_CT=$(ls $OLD_PROTEIN_DIR/*/sequence.fasta.txt | wc -l)
if [[ "$CORE_PROT_CT" -ne "$PROT_CT" ]]; then
    echo "ERROR[$0] incorrect number of core genes" > /dev/stderr
    echo "ERROR[$0] expected $CORE_PROT_CT; found $PROT_CT" > /dev/stderr
    exit 1
fi

# OLD_PROTEIN_DIR
echo "READING: "
ls -1 $OLD_PROTEIN_DIR/*/sequence.fasta.txt
cat $OLD_PROTEIN_DIR/*/sequence.fasta.txt > $SRC_PROTEINS_DB_FAA

# NEW NOVEL VIRUS
if [[ ! -e "$NEW_POX_FAA" ]]; then
    echo "ERROR[$0] input file missing: $NEW_POX_FAA" > /dev/stderr
    exit 1
fi
ls -1 $NEW_POX_FAA
cat $NEW_POX_FAA >> $SRC_PROTEINS_DB_FAA

GENBANK_CT=$(ls -1 $GENBANK_FAAS | wc -l) 
if [[ "$GENBANK_CT" -le "0" ]]; then
    echo "ERROR: $0 no .faa files $GENBANK_FAAS" > /dev/stderr
    exit 1
fi
for GBK_FAA in $GENBANK_FAAS; do 
    ls -1 "$GBK_FAA"
    cat "$GBK_FAA" >> "$SRC_PROTEINS_DB_FAA"
done

cat <<EOF
#
# index result
#
EOF
echo samtools faidx $SRC_PROTEINS_DB_FAA
samtools faidx $SRC_PROTEINS_DB_FAA

# QC line count
echo "grep -c '>'  $OLD_PROTEIN_DIR/*/sequence.fasta.txt $GENBANK_FAAS $NEW_POX_FAA "
SRC_SEQ_CT=$(grep '>'  $OLD_PROTEIN_DIR/*/sequence.fasta.txt $GENBANK_FAAS $NEW_POX_FAA | wc -l )
SEQ_DB_CT=$(grep '>'  $SRC_PROTEINS_DB_FAA | wc -l)
echo "TOTAL SRC Sequences: $SRC_SEQ_CT"
echo "$SRC_PROTEINS_DB_FAA:    $SEQ_DB_CT"
if [[ "$SRC_SEQ_CT" -ne "$SEQ_DB_CT" ]]; then
     echo "ERROR[$0]: final all-proteins databases does not have same number of sequences as the sources"
     exit 1
fi
echo "# ===================================="
echo "# SUCCESS: $0 $*"
echo "# ===================================="
