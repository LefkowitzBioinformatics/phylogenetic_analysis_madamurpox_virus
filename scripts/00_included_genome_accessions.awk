#!/usr/bin/env awk
#
# Enumerate ONLY Accessions in the Alignment
#
{
    sub(/\r$/,"",$0)
}
(tolower(substr($inNewPoxAlign,1,1))=="y") {
    print $IsolateAccession
}
