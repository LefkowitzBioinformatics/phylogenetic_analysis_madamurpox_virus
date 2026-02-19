#!/usr/bin/env awk
#
# Print GroupName for all genes in INCLUDED genomes
(tolower(substr($inNewPoxAlign,1,1))=="y"){print $GroupName}
