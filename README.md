# integrative-analysis-aphid

## Project Overview

This repository contains the code and analysis pipeline for an integrative study comparing RNA-seq and FAIRE-seq data in pea aphids (*Acyrthosiphon pisum*). The project aims to explore the differential gene expression and chromatin accessibility between sexual male and asexual female (parthenogenetic) morphs. 

## Project Structure

- Root project : all scripts in this directory, and the general data like the GFF and GTF (not included in this repository because too voluminous). 4 directories to create at root that will contain the outputs of the anaysis :
  - RNA (all RNA-related output files will go here. Example: `DEG_male_tss.bed`)
  - FAIRE (all FAIRE-related output files will go here. Example: `DAR_broad_male.bed`)
  - integrated (all integrated-related output files will go here. Example: `DAR_broad_DEG_male.bed`)
  - plots (an example of the plots generated with the analysis is provided in this repository)

### 1. RNA-seq Analysis
#### Data
- **Samples**: 4 whole-body samples (2 males and 2 females).
- **Sequencing**: Paired-end RNA sequencing of *Acyrthosiphon pisum* JIC1 strain.

#### Pipeline
- **Pipeline Used**: [nfcore/rnaseq](https://nf-co.re/rnaseq)
- **Script**:
  ```bash
  sbatch --mem=10G /path/to/rnaseq_script.sh
  ```
  Contents of `rnaseq_script.sh`:
  ```bash
  #!/bin/bash
  . /local/env/envnextflow-23.10.0.sh
  nextflow run nf-core/rnaseq \
      -profile genouest \
      -resume \
      --input /path/to/samplesheet.csv \
      --outdir /path/to/RESULTS \
      --fasta /path/to/Acyrthosiphon_pisum_JIC1_v1.0.scaffolds.fa \
      --gtf /path/to/Acyrthosiphon_pisum_JIC1_v1.0.scaffolds.braker2.exon.gtf \
      --skip_bbsplit false \
      --bbsplit_fasta_list /path/to/bbsplit_list.csv \
      --remove_ribo_rna \
      --skip_rseqc \
      --save_unaligned
  ```
- **Output**:
  - Normalized count matrix: `salmon.merged.gene_counts.tsv`

#### Differential Expression Analysis
- **Tool**: [AskoR](https://github.com/askomics/askoR) (DevKevin branch)
- **Key Parameters**:
  ```r
  parameters$threshold_cpm = 0.5
  parameters$replicate_cpm = 2
  parameters$threshold_FDR = 0.05
  parameters$threshold_logFC = 1
  parameters$normal_method = "TMM"
  parameters$p_adj_method = "BH"
  ```
- **Output**:
  - Differentially expressed genes (DEGs) list: `MalevsPartheno.txt` in AskoR output directory `DEanalysis/DEtable` (see AskoR documentation).

### 2. FAIRE-seq Analysis
#### Data
- **Samples**: 8 whole-body samples (3 males, 3 females, 1 control per condition).
- **Sequencing**: Paired-end FAIRE sequencing of *Acyrthosiphon pisum* JIC1 strain.

#### Pipeline
- **Pipeline Used**: [nfcore/atacseq](https://nf-co.re/atacseq)
- **Script**:
  ```bash
  sbatch --mem=10G /path/to/faireseq_script.sh
  ```
  Contents of `faireseq_script.sh`:
  ```bash
  #!/bin/bash
  . /local/env/envnextflow-23.10.0.sh
  nextflow run nf-core/atacseq \
      -profile genouest \
      -resume \
      --input /path/to/faireseq_samplesheet.csv \
      --outdir /path/to/RESULTS \
      --fasta /path/to/Acyrthosiphon_pisum_JIC1_v1.0.scaffolds.fa \
      --gtf /path/to/Acyrthosiphon_pisum_JIC1_v1.0.scaffolds.braker2.exon.gtf \
      --with_control \
      --macs_gsize 525769313 \
      --broad_cutoff 0.1 \
      --macs_fdr 0.05 \
      --min_trimmed_reads 1000 \
      --keep_dups true \
      --save_macs_pileup true \
      --save_unaligned true
  ```
  For narrow mode, replace `--broad_cutoff 0.1` with `--narrow_peak true`.

### 3. Data Integration
#### Intersection Analysis
- **Tool**: [Bedtools](https://bedtools.readthedocs.io/en/latest/)
- **Procedure**:
  - **RNA-seq**:
    - Cross-reference the gff file and fetch ±1500 bp around TSS to create BED files separated by condition with `DEG_X_GFF.ipynb`. Output example : `DEG_male_tss.bed`
  - **FAIRE-seq**:
    - Process consensus_peaks.mLb.clN.boolean.txt file (output from `nfcore/atacseq`) to separate by condition with `FAIRE_Peaks_Per_Condition.ipynb`. Output example : `DAR_broad_male.bed`
  - **Integration Command**:
    - Intersect both outputs from previous steps using Bedtools, automated for all different files with `run_intersects.sh`. Output example : `DAR_broad_DEG_male.bed`

### Results
- **RNA-seq**:
  - Total genes: 31,244
  - Filtered genes (CPM > 0.5 in 2 samples): 14,108
  - Significant DEGs: 4,676 (2,867 in males, 1,809 in females)

- **FAIRE-seq**:
  - Peaks identified:
    - Broad: 44,251
    - Narrow: 39,104
  - Differentially accessible regions (DARs):
    - Males (broad): 1,875
    - Females (broad): 1,955
    - Intergroup (broad): 8,788
    - Males (narrow): 1,689
    - Females (narrow): 1,725
    - Intergroup (narrow): 4,886
  
- **Integrative Analysis (minreps = 1, overlap =0.9))**:
    - Intersected DEGs and DARs:
        - Broad Peaks:
            - Males: 329 regions
            - Females: 93 regions
        - Narrow Peaks:
            - Males: 396 regions
            - Females: 112 regions
              
The integrative analysis highlights regions of accessible chromatin linked to differential gene expression between morphs.

### Visualization
- Integrated data visualized using Seaborn and Matplotlib with `plotting.ipynb` Plots will all go in the plots directory (at the root of the project)
- **Key Visualizations**:
  - Peak distribution plots (DEG, DAR, DEG + DAR: global and per scaffold)
  - Coverage

## Prerequisites
- Install nf-core tools: `nf-core/rnaseq` and `nf-core/atacseq`.
- Install R and required packages (`AskoR`).
- Install Bedtools intersect for genomic operations.
- GFF and GTF files for *Acyrthosiphon pisum*, in project's root folder

### Notes
`integrated_analysis.ipynb` is included in the repository but is not completed : it is a draft for a khi-2 test on the integrated data. It needs to be corrected to perform a correct statistical test. `run_intersects_TSS.sh`is also used to get data used in that test.
