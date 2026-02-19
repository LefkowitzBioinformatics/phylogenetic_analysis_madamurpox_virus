#!/usr/bin/env awk
#
# lookup protein_id given (genomeAccession & protein groupName)
#
# always run protein_lists/AllProteins.coldefs.awk first!
#
#
#
# RUN AS
# GENOME_HEADER=$(awk -v TargGenome="$GENOME_ACC" -v TargGroup="$GENE_NAME" -f protein_lists/AllProteins.coldefs.awk -f 04.merge_protein_aligns.sh.gene_from_group_genome.awk $META)
#

# strip CR if present (CRLF files), no-op on LF files
{ sub(/\r$/, "", $0) }   
#
# FILT: select genome row by accession
# OUT: print fasta header with genome info
# 
($IsolateAccession==TargGenome && $GroupName==TargGroup){
    print $GeneAccession
    exit 0
}
