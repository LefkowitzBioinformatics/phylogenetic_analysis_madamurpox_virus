#!/usr/bin/env awk
##
# build formatted fasta header for
# a genome in the merged core genes file
#
# RUN AS
# GENOME_HEADER=$(awk -v TargAccession="$GENOME_ACC" -f protein_lists/AllProteins.coldefs.awk -f 04.merge_protein_aligns.sh.genome_header.awk $META)
#
# strip CR if present (CRLF files), no-op on LF files
{ sub(/\r$/, "", $0) }   
#
# FILT: select genome row by accession
# OUT: print fasta header with genome info
# 
($IsolateAccession==TargAccession){
    final_name=gsub(/ /,"_",$GenomeDisplayName)
    print $GenomeDisplayName
}
