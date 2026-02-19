#!/usr/bin/env awk
#
# Get all GeneAccessions in GenomeOrder for a given protein group
#
# always run protein_lists/AllProteins.coldefs.awk first!
#
# strip CR if present (CRLF files), no-op on LF files
{ sub(/\r$/, "", $0) }   
#
# FILT: in group && in alignment
# OUT: print accession & order
# 
($GroupName==TargGroup && tolower(substr($inNewPoxAlign,1,1))=="y") {
    print $GeneAccession,$GenomeOrder
}
