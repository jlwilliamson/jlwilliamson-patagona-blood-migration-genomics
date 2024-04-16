#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=8
#SBATCH --time=1:00:00
#SBATCH --job-name=subsetuceloci
#SBATCH --output=subsetuceloci_out_%j
#SBATCH --error=subsetuceloci_error_%j
#SBATCH --partition=debug
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

## NOTE:
## WITHOUT the cpus-per-task call, ntasks should be # samples x ntasks-per-node (i.e., if 7 tasks per node with 12 genomes, ntasks should be 84) --> this is super important for parallel
## If just running on a single node, ntasks should just be equivalent to ntasks-per-node
## when cpus-per-task call is there, n-tasks becomes equal to the # nodes requested, and cpus-per-task means # cores per node you want
## Adding in this call allows you to request a full node (whereas this was breaking for us before when we tried to do this using n-tasks only)

## Script to subset 100 UCE loci for making BEAST tree
## From	"subsetting for BEAST" section of this tutorial: https://jasonleebrown.github.io/UCE_phyluce_pipeline/

src=$SLURM_SUBMIT_DIR

## Activate environment set up for UCEs
## remember NEED eval conda shell bash hook line BEFORE conda activate env line
eval "$(conda shell.bash hook)"
conda activate uce-env
conda activate phyluce-env


## SUBSET RANDOM LOCI - Ethan's elegant solution
## Creates a .txt file that contains 100 random loci
## writes out to main UCE folder
## Now create 10 subsets of 100 random UCE loci:
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration1.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration2.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration3.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration4.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration5.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration6.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration7.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration8.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration9.txt
ls $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13 | shuf -n100 > $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration10.txt

## COPY RANDOM LOCI INTO NEW FOLDER
## The for loop identifies each locus in the .txt file and then copies those loci

## Now make new sub-directories for the 10 subsets (only do this once!)
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration1
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration2
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration3
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration4
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration5
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration6
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration7
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration8
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration9
mkdir $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration10

## Now loop through each of the 10 subsets and copy loci into appropriate subdirectories
for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration1.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration1/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration2.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration2/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration3.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration3/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration4.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration4/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration5.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration5/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration6.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration6/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration7.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration7/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration8.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration8/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration9.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration9/; \
done

for i in $(cat $src/taxon-sets-tissues-2023-02-13/all-tissues/random_loci_n100_iteration10.txt); \
    do cp $src/taxon-sets-tissues-2023-02-13/all-tissues/mafft-nexus-internal-trimmed-gblocks-clean-100Complete_2023-02-13/$i $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration10/; \
done

## CONCATENATE LOCI INTO A SINGLE ALIGNMENT
## note that we specified —nexus output instead of phylip
## Now concatenate the 10 subsets into a single alignment:
phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration1 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration1/beast_n100_iteration1 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration2 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration2/beast_n100_iteration2 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration3 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration3/beast_n100_iteration3 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration4 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration4/beast_n100_iteration4 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration5 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration5/beast_n100_iteration5 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration6 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration6/beast_n100_iteration6 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration7 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration7/beast_n100_iteration7 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration8 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration8/beast_n100_iteration8 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration9 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration9/beast_n100_iteration9 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues

phyluce_align_concatenate_alignments \
        --alignments $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration10 \
        --output $src/taxon-sets-tissues-2023-02-13/all-tissues/subset100_iteration10/beast_n100_iteration10 \
        --nexus \
        --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets-tissues-2023-02-13/log-tissues
