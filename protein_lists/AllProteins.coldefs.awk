#
# Column definitions
#
BEGIN {
    FS="\t";OFS=FS;

    # head -1 AllProteins.txt | sed 's/\t/\n/g' | egrep -n .
    GeneOrder=1
    GroupName=2
    GroupProteinFunction=3
    GeneAccession=4
    GeneLink=5
    GeneProteinFunction=6
    IsolateName=7
    IsolateAccession=8
    GenomeDisplayName=9
    GenomeOrder=10
    inNewPoxAlign=11
}
