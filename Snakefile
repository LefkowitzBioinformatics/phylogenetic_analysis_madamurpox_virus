# Snakefile
#
# Align per-group protein FASTAs with MAFFT and MUSCLE, in parallel.
#   *MUST* preserve sequence order during alignment
#

# Snakefile
import os

# inputs - must match 00.set_env.sh
META="protein_lists/AllProteins.txt"
ALIGN_DIR="new_align"
PROT_GROUPS_DIR=ALIGN_DIR+"/protein_groups"

# outputs
QC_MUSCLE_SUMMARY=ALIGN_DIR+"qc.muscle.ensemble.summary.txt"

# scripts & dependancies
GRAPH_TREE="scripts/graph_tree.R"
MUSCLE_EXE="~/Applications/muscle-osx-arm64.v5.3"

#
# Parse METADATA file to get protein group naems
#
def read_groups(meta_path):
    print("META_PATH", meta_path)
    groups = []
    seen = set()
    with open(meta_path, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            # Prefer TSV; fall back to whitespace
            parts = line.split("\t")
            if len(parts) < 2:
                parts = line.split()

            if len(parts) < 2:
                continue

            g = parts[1].strip()

            if not g or g.lower() in ("groupname", "group"):
                #print(g)
                continue

            if g not in seen:
                seen.add(g)
                #print(g)
                groups.append(g)

    return groups

GROUPS = read_groups(META)

print( "GROUPS=")
print( GROUPS )

#
# pre-flight check
#
rule check_requirements:
    shell:
        #"echo ===== MAFFT =====;"
        #"echo $(which mafft);"
        #"echo $(mafft --version);"
        #"echo MAFFT {rules.all.input.mafft[0]};"
        "echo ===== MUSCLE =====;"
        "echo $(which {MUSCLE_EXE});"
        "echo $({MUSCLE_EXE} --version);"
        "echo 'MUSCLE      {rules.all.input.muscle[0]}';"
        "echo 'MUSCLE TEST {rules.all.input.muscle_efa[0]}';"
        "echo ===== R =====;"
        "echo $(which Rscript);"
        "echo $(Rscript --version);"
        "echo ===== PDFUNITE =====;"
        "echo $(which pdfunite);"
        "echo $(pdfunite -v);"

rule test:
    shell:
        "echo GROUPS='{GROUPS}'"

# ----------------------------------------------------------------------
#
# BUILD EVERYTHING
#
# disabled MAFFT, standardizign on MUSCLE
# disabled RAxML - crashes on our trees
#
# ----------------------------------------------------------------------
rule all:
    input:
        #mafft=expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-mafft.faa.txt", group=GROUPS),
        muscle=expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt", group=GROUPS),
        muscle_efa=QC_MUSCLE_SUMMARY,

        # Rendered trees (Newick -> PDF/PNG) for MUSCLE alignments
        # IQ-TREE2 output: {group}/sequence.msa-muscle.faa.txt.treefile
        muscle_iqtree_pdf=expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile.pdf", group=GROUPS),
        muscle_iqtree_png=expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile.png", group=GROUPS),

        # RAxML output: {group}/sequence.msa-muscle.faa.txt.raxml.bestTree
        #muscle_raxml_pdf=expand(PROT_GROUPS_DIR+"{group}/sequence.msa-muscle.faa.txt.raxml.bestTree.pdf", group=GROUPS),
        #muscle_raxml_png=expand(PROT_GROUPS_DIR+"{group}/sequence.msa-muscle.faa.txt.raxml.bestTree.png", group=GROUPS)

# ----------------------------------------------------------------------
#
# MUSCLE: align per-protein family MSAs individually
#
# ----------------------------------------------------------------------
rule muscle:
    input:
        muscle=expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt", group=GROUPS)
    
#
# MUSCLE
#
rule muscle_align_prot_group:
    input:
        faa=PROT_GROUPS_DIR+"/{group}/sequence.faa.txt"
    output:
        msa=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt"
    threads: 4
    shell:
        "{MUSCLE_EXE} -align {input.faa} -output {output.msa} -threads {threads} "

rule muscle_stratify_prot_group:
    input:
        faa=PROT_GROUPS_DIR+"/{group}/sequence.faa.txt"
    output:
        efa=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.ensemble.efa.txt",
    threads: 4
    shell:
        "{MUSCLE_EXE} -align {input.faa} -stratified -output {output.efa} -threads {threads} "


rule muscle_stratify_eval:
    input:
        efa=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.ensemble.efa.txt",
    output:
        qc=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.ensemble.qc.txt"
    shell:
        "{MUSCLE_EXE} -disperse {input.efa} 2>&1 | tee {output.qc} "

rule muscle_stratify_eval_summary:
    input:
        expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.ensemble.qc.txt", group=GROUPS)
    output:
        QC_MUSCLE_SUMMARY
    shell:
        "tail -3 {input} | grep D_LP= > {output}"

# ----------------------------------------------------------------------
#
# MUSCLE: align per-protein family MSAs individually
#
# ----------------------------------------------------------------------

#
# MAFFT
#
rule mafft_align_prot_group:
    input:
        faa=PROT_GROUPS_DIR+"/{group}/sequence.faa.txt"
    output:
        msa=PROT_GROUPS_DIR+"/{group}/sequence.msa-mafft.faa.txt"
    threads: 4
    shell:
        "mafft --auto --thread {threads} --inputorder {input.faa} > {output.msa}"


# ----------------------------------------------------------------------
#
# Render trees into PNG/PDF
#
# ----------------------------------------------------------------------
rule iqtree:
    input:
        # IQ-TREE2 output: {group}/sequence.msa-muscle.faa.txt.treefile
        muscle_iqtree_pdf=expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile.pdf", group=GROUPS),
        muscle_iqtree_png=expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile.png", group=GROUPS),
        muscle_iqtrees_pdf=PROT_GROUPS_DIR+"/sequence.msa-muscle.iqtree.all_groups.pdf"

rule merge_pdfs_iqtree_muscle:
    input:
        expand(PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile.pdf", group=GROUPS)
    output:
        muscle_iqtrees_pdf=PROT_GROUPS_DIR+"/sequence.msa-muscle.iqtree.all_groups.pdf"
    shell:
        "pdfunite {input} {output}"

rule render_tree_iqtree_muscle:
    input:
        tree=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile",
        faa=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt",
        script=GRAPH_TREE
    output:
        pdf=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile.pdf",
        png=PROT_GROUPS_DIR+"/{group}/sequence.msa-muscle.faa.txt.treefile.png"
    params:
        title=lambda wc: f"muscle-iqtree-{wc.group}"
    shell:
        "Rscript {input.script} {input.tree} {input.faa} '{params.title}'"

rule render_iqtree_muscle_all_proteins:
    input:
        tree=ALIGN_DIR+"/all_protein_aligns.faa.treefile",
        faa=ALIGN_DIR+"/all_protein_aligns.faa",
        script=GRAPH_TREE
    output:
        pdf=ALIGN_DIR+"/all_protein_aligns.faa.treefile.pdf",
        png=ALIGN_DIR+"/all_protein_aligns.faa.treefile.png"
    params:
        title=lambda wc: f"Genomes:56, CorePoxGenes:25 Muscle-IQTree2(Q.yeast+F+I+R6;B=1000Q)"
    shell:
        "Rscript {input.script} {input.tree} {input.faa} '{params.title}'"

rule render_iqtree_all:
     input:
        pdf=ALIGN_DIR+"/all_protein_aligns.faa.treefile.pdf"

rule render_tree_raxml_muscle:
    input:
        tree=ALIGN_DIR+"/{group}/sequence.msa-muscle.faa.txt.raxml.bestTree",
        faa=ALIGN_DIR+"/{group}/sequence.msa-muscle.faa.txt",
        script=GRAPH_TREE
    output:
        pdf=ALIGN_DIR+"/{group}/sequence.msa-muscle.faa.txt.raxml.bestTree.pdf",
        png=ALIGN_DIR+"/{group}/sequence.msa-muscle.faa.txt.raxml.bestTree.png"
    params:
        title=lambda wc: f"muscle-raxml-{wc.group}"
    shell:
        "Rscript {input.script} {input.tree} {input.faa} '{params.title}'"
