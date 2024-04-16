#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --job-name=windowed_fst
#SBATCH --output=windowed_fst_o_%j
#SBATCH --error=windowed_fst_error_%j
#SBATCH --partition=normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

## This is script to calculate windowed Fst to be able to make Manhattan plots
## Note that here you ALWAYS want to read in gatk-filtered SNPS
## If you need to run many comparisons at once, see notes in Patagona_BioinformaticsPipeline_WGS_Annotated file
## (note that you'll basically use two .sh scripts written by Ethan: vcf_fst_pairs_for_manhattan_plot_script.sh, and rename_vcf_fstpairs_for_manhattah_plot.sh)
## This is basically the simpler version of that script for single comparisons and manual adjustment of code.

module load miniconda3/4.10.3-an4v
#module load parallel/20210922-cfec

#source $(which env_parallel.bash)
#source activate gatk-env

source activate gatk-env
#source $(which env_parallel.bash)

src=$SLURM_SUBMIT_DIR

#scontrol show hostname > $src/node_list_${SLURM_JOB_ID}



## NORTH VERSUS SOUTH WINDOWED FST 
## North Vs. South - ALL DATA (excludes W chromosome and NK279003)
#vcftools --vcf /users/jlwill/wheeler-scratch/patagona/analysis_vcfs/filtered_snps.vcf \
#	 --fst-window-size 50000 \
#	 --weir-fst-pop sample_list_southern_NoNK279003 \
#	 --weir-fst-pop sample_list_northern \
#	 --remove-filtered-all \
#	 --min-alleles 2 \
#	 --max-alleles 2 \
#	 --mac 2 \
#	 --max-missing .75 \
#	 --not-chr NC_044276.1 \
#         --out /users/jlwill/wheeler-scratch/patagona/fst_output/Patagona_Genomes_NorthVsSouth_Fst_Window50k_NoWChromosome_No279003_2023-04-11

## North Vs. South - ALL DATA (excludes W chromosome and NK279003)
vcftools --vcf /users/jlwill/wheeler-scratch/patagona/analysis_vcfs/filtered_snps.vcf \
         --fst-window-size 10000 \
         --weir-fst-pop sample_list_southern_NoNK279003 \
         --weir-fst-pop sample_list_northern \
         --remove-filtered-all \
         --min-alleles 2 \
         --max-alleles 2 \
         --mac 2 \
         --max-missing .75 \
         --not-chr NC_044276.1 \
         --out /users/jlwill/wheeler-scratch/patagona/fst_output/Patagona_Genomes_NorthVsSouth_Fst_Window10k_NoWChromosome_No279003_2023-04-11
