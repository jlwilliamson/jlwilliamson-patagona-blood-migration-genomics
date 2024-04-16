#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --job-name=pairwise_fst
#SBATCH --output=pairwise_fst_o_%j
#SBATCH --error=pairwise_fst_error_%j
#SBATCH --partition=normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

module load miniconda3/4.10.3-an4v
#module load parallel/20210922-cfec
#source $(which env_parallel.bash)

src=$SLURM_SUBMIT_DIR
reference=~/wheeler-scratch/patagona/reference/ANHU_reference

scontrol show hostname > $src/node_list_${SLURM_JOB_ID}

source activate gatk-env

## Script to calculate all pairwise Fst comparisons for ALL birds (i.e., genome-wide; does not exclude sexes or chromosomes like Z) 
## Includes N to S comparisons
## And country comparisons 


## GENOME-WIDE COMPARISONS

## North Vs. South - ALL DATA (excludes W chromosome and NK279003)
## (Excludes NK279003 for relationship with NK279017)
vcftools --vcf /users/jlwill/wheeler-scratch/patagona/analysis_vcfs/patagona_genomes_vcftoolsfilter_10kthin_75complete_NoWChromosome_NoNK279003_2023-04-04.vcf \
         --weir-fst-pop sample_list_southern_NoNK279003 \
         --weir-fst-pop sample_list_northern \
         --out /users/jlwill/wheeler-scratch/patagona/fst_output/Patagona_Genomes_NorthVsSouth_Fst_NoWChromosome_No279003_2023-04-06

## North Vs. South - ALL DATA (includes W and Z) 
## (Excludes NK279003 for relationship with NK279017)
#vcftools --vcf /users/jlwill/wheeler-scratch/patagona/analysis_vcfs/patagona_genomes_vcftoolsfilter_10kthin_75complete.vcf \
#         --weir-fst-pop sample_list_southern_NoNK279003 \
#         --weir-fst-pop sample_list_northern \
#         --out /users/jlwill/wheeler-scratch/patagona/fst_output/Patagona_Genomes_NorthVsSouth_Fst_AllData_April2022

## North Vs. South - AUTOSOMES (excludes sex chromosomes, Z and W)
## (Excludes NK279003 for relationship with NK279017)
#vcftools --vcf /users/jlwill/wheeler-scratch/patagona/analysis_vcfs/patagona_genomes_vcftoolsfilter_10kthin_75complete.vcf \
#         --weir-fst-pop sample_list_southern_NoNK279003 \
#         --weir-fst-pop sample_list_northern \
#	 --not-chr NC_044274.1 \
#         --not-chr NC_044276.1 \
#         --out /users/jlwill/wheeler-scratch/patagona/fst_output/Patagona_Genomes_NorthVsSouth_Fst_AutosomesOnly_April2022  

## North Vs. South - Z-CHROMOSOME/MALES ONLY
## (Excludes NK279003 for relationship with NK279017)
#vcftools --vcf /users/jlwill/wheeler-scratch/patagona/analysis_vcfs/patagona_genomes_vcftoolsfilter_10kthin_75complete.vcf \
#         --weir-fst-pop southern_sample_list_males \
#         --weir-fst-pop northern_sample_list_males \
#         --chr NC_044274.1 \
#         --out /users/jlwill/wheeler-scratch/patagona/fst_output/Patagona_Genomes_NorthVsSouth_Fst_MalesOnly_ZChromosome_April2022
