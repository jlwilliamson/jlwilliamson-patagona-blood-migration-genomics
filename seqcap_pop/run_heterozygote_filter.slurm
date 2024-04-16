#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=7
#SBATCH --time=48:00:00
#SBATCH --job-name=hetfilter
#SBATCH --output=hetfilter_out_%j
#SBATCH --error=hetfilter_error_%j
#SBATCH --partition=normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

## Ethan' s script to take combined data, remove excess heterozygotes from each tissue UCEs and UCEs from genomes, merge, then output merged and filtered vcf. 
## This dataset contains n=70 birds (all 35 tissue UCE birds and 35 of 36 WGS birds; excludes NK279003, which is relate to NK279017)

## Load stuff
module load miniconda3/4.10.3-an4v

## eval conda shell.bash hook line allows conda to be called as conda, not source (EFG thinks th$
## So ideally, run this line, THEN activate gatk-env and env_parallel with "conda" and not "sour$
## remember NEED eval conda shell bash hook line BEFORE conda activate env line
eval "$(conda shell.bash hook)"
conda activate gatk-env
#conda activate bcftools-env

## Note! Remember you can only have on environment active at once! So activate gatk-env to run initial vcftools, then activate bcftools for merge, then gatk-env again for final vcftools

#source activate gatk-env
#source activate vcfmerge-env
#sourc activate vcftools-env

## Set working directory
src=$SLURM_SUBMIT_DIR


## Start by taking the combined tissue and UCE GATK-filter output and splitting these into tissue UCE and genome UCE
#vcftools --vcf /users/jlwill/wheeler-scratch/patagona/UCE/analysis_vcfs/patagona_UCE_TissueUCEAndGenomes_singleref_gatkfilter.vcf \
#	 --out $src/patagona_tissue_UCE \
#	 --keep sample_list_tissueUCE_copy \
#	 --remove-filtered-all \
#	 --recode

#vcftools --vcf /users/jlwill/wheeler-scratch/patagona/UCE/analysis_vcfs/patagona_UCE_TissueUCEAndGenomes_singleref_gatkfilter.vcf \
#	 --out $src/patagona_genomes_noNK279003 \
#	 --keep sample_list_from_genomes_noNK279003_copy \
#	 --remove-filtered-all \
#	 --recode

## Run Ethan's python script to remove excess heterozygotes from each dataset, applying a 0.4 het filter	 
#python2 remove_excessHets.py -i $src/patagona_tissue_UCE.recode.vcf -o $src/patagona_tissue_UCE_40hetfilter.vcf -n 0.4
#python2 remove_excessHets.py -i $src/patagona_genomes_noNK279003.recode.vcf -o $src/patagona_genomes_noNK279003_40hetfilter.vcf -n 0.4

## Prep data for vcf merge
## In order for vcf merge to work, The tool requires bgzipped and tabix indexed VCF files on input. (E.g. bgzip file.vcf; tabix -p vcf file.vcf.gz)
## Keep -f flag in bgzip to overwrite if a file already exists (while zipping, it might say a temp file already exists...hence the -f flag to write anyways
#bgzip -f $src/patagona_genomes_noNK279003_40hetfilter.vcf > $src/patagona_genomes_noNK279003_40hetfilter.vcf.gz
#tabix -fp vcf $src/patagona_genomes_noNK279003_40hetfilter.vcf.gz

#bgzip -f $src/patagona_tissue_UCE_40hetfilter.vcf > $src/patagona_tissue_UCE_40hetfilter.vcf.gz
#tabix -fp vcf $src/patagona_tissue_UCE_40hetfilter.vcf.gz

## Merge the two het filtered datasets
#vcf-merge $src/patagona_genomes_noNK279003_40hetfilter.vcf.gz $src/patagona_tissue_UCE_40hetfilter.vcf.gz > $src/patagona_UCE_TissueUCEAndGenomes_singleref_40hetfilter.vcf
## vcf-merge didn't work because I didn't have it installed properly and couldn't figure it out
## I tried picard merge vcf fuction and that gave me a weird error about vcf files having different names
## but bcftools seems to have done the trick! Blessed.
#bcftools merge $src/patagona_genomes_noNK279003_40hetfilter.vcf.gz $src/patagona_tissue_UCE_40hetfilter.vcf.gz > $src/patagona_UCE_TissueUCEAndGenomes_singleref_40hetfilter.vcf

## Now use vcftools to produce a final combined dataset to use downstream
## and note that I write out this final VCF file to the analysis_vcfs directory
vcftools --vcf $src/patagona_UCE_TissueUCEAndGenomes_singleref_40hetfilter.vcf \
	 --out /users/jlwill/wheeler-scratch/patagona/UCE/analysis_vcfs/patagona_UCE_TissueUCEAndGenomes_singleref_40hetfilter_NoWChromosome_minmeanDP6_10kthin_90Complete_2023-04-06 \
	 --not-chr NC_044276.1 \
	 --remove-indels \
	 --remove-filtered-all \
	 --min-alleles 2 \
	 --max-alleles 2 \
	 --mac 2 \
	 --min-meanDP 6 \
	 --thin 10000 \
	 --max-missing .90 \
	 --recode

mv /users/jlwill/wheeler-scratch/patagona/UCE/analysis_vcfs/patagona_UCE_TissueUCEAndGenomes_singleref_40hetfilter_NoWChromosome_minmeanDP6_10kthin_90Complete_2023-04-06.recode.vcf /users/jlwill/wheeler-scratch/patagona/UCE/analysis_vcfs/patagona_UCE_TissueUCEAndGenomes_singleref_40hetfilter_NoWChromosome_minmeanDP6_10kthin_90Complete_2023-04-06.vcf





# Use vcftools to take in the het filter data and write out just a Southern-only dataset for further examination of Chile/Argentina inversion stuff (I think)
#vcftools --vcf patagona_UCE_WGS_hetfilter.vcf \
#	 --out patagona_UCE_WGS_het40_10kthin_90per_onlyS \
#	 --keep sample_list_both_south \
#	 --min-alleles 2 \
#	 --max-alleles 2 \
#	 --mac 2 \
#	 --thin 10000 \
#	 --max-missing .90 \
#	 --recode
