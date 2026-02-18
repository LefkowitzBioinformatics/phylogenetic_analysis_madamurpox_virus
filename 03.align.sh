#!/usr/bin/env bash
#
# run alignments
#
#
# set-env
source 00.set_env.sh

cat <<EOF
#
# run per-protein group MUSCLE alignments
#
# GENOME_CT=$GENOME_CT
#
EOF
echo snakemake --cores $(sysctl -n hw.logicalcpu)  -k --rerun-incomplete --printshellcmd muscle $*
snakemake --cores $(sysctl -n hw.logicalcpu)  -k --rerun-incomplete --printshellcmd muscle $*

if [[ $? -ne 0 ]]; then
   echo "ERROR[$0]: snakemake failed"
   exit 1
fi
#
# QC results from Snakemake
#
MSA_CT=$(ls -1 $PROT_GROUPS_DIR/*/$PROT_ALIGN_MSA_FNAME | wc -l)
if [[ "$CORE_PROT_CT" -ne "$MSA_CT" ]]; then
    echo "ERROR[$0]: there are $MSA_CT MSAs, but $CORE_PROT_CT protein groups"
    find $PROT_GROUPS_DIR -name "$PROT_ALIGN_MSA_FNAME" -exec ls -lstr {} +
    exit 1
else
    echo "OK: there are $MSA_CT MSAs == $CORE_PROT_CT protein groups"
fi

for PROTEIN_MSA in  $PROT_GROUPS_DIR/*/$PROT_ALIGN_MSA_FNAME; do
    MSA_SEQ_CT=$(grep -c ">" $PROTEIN_MSA)
    if [[ "$MSA_SEQ_CT" -ne "$GENOME_CT" ]]; then
	echo "ERROR[$0]: incorrect sequence count for core protein $PROTEIN_MSA"
	exit 1
    else
	echo "OK: $MSA_SEQ_CT==$GENOME_CT for $PROTEIN_MSA"
    fi
done

echo "# ===================================="
echo "# SUCCESS:$0 $*"
echo "# ===================================="
