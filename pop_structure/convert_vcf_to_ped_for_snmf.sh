#!/bin/bash

##Script to convert .vcf file to .ped file, which can then be used by ped2geno() in R to get file ready for sNMF
## (For whatever reason, when vcf2geno() in R works, it's fantastic; but half the time it breaks unexpectedly and R aborts without warning - people have noted this in forums)
## To avoid this, convert to ped first, as that function seems to be more consistent. 

## NOTE!! This didn't work on CARC...something to do with file paths not being recognized. I ran it on local directory instead because fast, name of file is also
## convert_vcf_to_ped_for_snmf.sh (and running on local means no need to specify environment that CARC is being called from). 


## Load the below becuase you need to activate an environment that vcftools is installed in
#cd $SLURM_SUBMIT_DIR
## if using PBS, 'cd $PBS_O_WORKDIR'
cd $PBS_O_WORKDIR
module load miniconda3/4.10.3-an4v
module load parallel/20210922-cfec
eval "$(conda shell.bash hook)"
conda activate uce-env
source $(which env_parallel.bash)

## Take in combined .vcf file for tissue UCEs and UCEs from genomes that Ethan outputted w/ 0.4 het filter (n=70 birds)
vcftools --vcf users/jlwill/wheeler-scratch/patagona/UCE/EFG_hetfilter/patagona_UCE_WGS_het40_10kthin_90per.recode.vcf \
	--out users/jlwill/wheeler-scratch/patagona/UCE/EFG_hetfilter/patagona_UCE_WGS_het40_10kthin_90complete \
	--remove-indels \
	--remove-filtered-all \
	--min-alleles 2 \
	--max-alleles 2 \
	--mac 2 \
	--min-meanDP 10 \
	--max-missing 1 \
	--thin 10000 \
	--plink
