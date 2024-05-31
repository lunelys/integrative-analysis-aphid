#!/bin/bash

# Set default overlap fraction
overlap_fraction="${1:-1.0}"

# Define arrays for the different parameters
genders=("male" "partheno")
reptypes=("minreps1" "minreps2")
peaktypes=("broad" "narrow")

# Base paths for inputs and output
cwd="$(dirname "$0")"  #current working directory
FAIRE_directory="${cwd}/FAIRE/"
integrated_directory="${cwd}/integrated/"  # output directory

# Loop through each combination of parameters
for gender in "${genders[@]}"; do
    for reptype in "${reptypes[@]}"; do
        for peaktype in "${peaktypes[@]}"; do
            # Construct filenames
            tss_file="${cwd}/Acyrthosiphon_pisum_JIC1_v1.0_expressed_tss.bed"
            dar_file="${FAIRE_directory}DAR_${peaktype}_${gender}_${reptype}.bed"
            output_file="${integrated_directory}/DAR_${peaktype}_TSS_${gender}_${reptype}_overlap${overlap_fraction}.bed"

            # Run bedtools intersect with each combination
            bedtools intersect -F "$overlap_fraction" -a "$tss_file" -b "$dar_file" -wb > "$output_file"
            
             # Rearrange columns: keeping the geneid and the strand, removing the intersection interval and the scaffold
            awk 'BEGIN {FS=OFS="\t"} {print $6, $7, $8, $9, $4, $5, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41}' "$output_file" > "${output_file}.tmp"

            mv "${output_file}.tmp" "$output_file"  # We just want to keep one file
            
            # For IGV visualizations, extract the first six columns to a new "reduced" file
    	    cut -f 1-6 "$output_file" > "${output_file%.bed}_reduced.bed"
            
            # Display in the terminal the number of peaks found, with just the filename (no full path cluttering)
            count=$(wc -l < "$output_file")
            echo "$count DAR_${peaktype}_DEG_${gender}_${reptype}_overlap${overlap_fraction}.bed"  
        done
    done
done

