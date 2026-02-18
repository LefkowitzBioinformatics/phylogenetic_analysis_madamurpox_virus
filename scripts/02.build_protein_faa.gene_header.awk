BEGIN {
    FS="\t";OFS=FS;

    # head -1 ictv_core_proteins_curated-genome_from_gene.allgenes.txt | sed 's/\t/\n/g' | egrep -n .
    GeneOrder=1
    GroupName=2
    GroupProteinFunction=3
    GeneAccession=4
    GeneLink=5
    GeneProteinFunction=6
    IsolateName=7
    IsolateAccession=8
    isIsolate=9
    GroupNameGood=10
    Fence=11
    GenomeAcc=12
    NcbiIsolateName=13
    GenomeOrder=14
    inNewPoxAlign=15
}
# strip CR if present (CRLF files), no-op on LF files
{ sub(/\r$/, "", $0) }   
#
# FILT: gene accession
# OUT: print fasta header with genome info
# 
($GeneAccession==TargAccession){
    print $GeneAccession" "$IsolateName" ["$IsolateAccession"]"
}
