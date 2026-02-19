#!/usr/bin/env awk
#
# Construct FASTA gene_id
#
# always run protein_lists/AllProteins.coldefs.awk first!
#
# strip CR if present (CRLF files), no-op on LF files
{ sub(/\r$/, "", $0) }   
#
# FILT: gene accession
# OUT: print fasta header with genome info
# 
($GeneAccession==TargAccession){
    print $GeneAccession" "$IsolateName" ["$IsolateAccession"]"
}
