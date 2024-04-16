#!/bin/bash

#SBATCH --ntasks=4
#SBATCH --cpus-per-task=8
#SBATCH --time=48:00:00
#SBATCH --job-name=beast_parallel
#SBATCH --output=beast_parallel_out_%j
#SBATCH --error=beast_parallel_error_%j
#SBATCH --partition=normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

## NOTE: ## WITHOUT the cpus-per-task call, ntasks should be # samples x ntasks-per-node (i.e., if 7 tasks per node with 12 genomes, ntasks should be 84) --> this is super important for parallel
## If just running on a single node, ntasks should just be equivalent to ntasks-per-node
## when cpus-per-task call is there, n-tasks becomes equal to the # nodes requested, and cpus-per-task means # cores per node you want
## Adding in this call allows you to request a full node (whereas this was breaking for us before when we tried to do this using n-tasks only)
## Only request ntasks=1 if running Beast on 1 node; if you request 2, nothing will happen on the 2nd becuase this isn't parallelized

## Script to run beast in parallel on CARC
## I made 10 .xml files in Beauti on hard drive, beamed them here, and will now run 2 runs of each iteration, for a total of 20 beast runs
## Beast2 is version 2.6.3

## Set source directory variable
src=$SLURM_SUBMIT_DIR
cd $SLURM_SUBMIT_DIR

## Load modules
module load miniconda3/4.10.3-an4v
#module load miniconda3
module load parallel/20210922-cfec

## Activate modules 
## eval conda shell.bash hook line allows conda to be called as conda, not source (EFG thinks this is because they're phasing out source)
## So run eval conda shell.bash hook line, THEN activate beast2-env and env_parallel with "conda" and not "source"
## remember NEED eval conda shell bash hook line BEFORE conda activate env line
#eval "$(conda shell.bash hook)"
#conda $(which env_parallel.bash)
## BUT, if this isn't working for some reason (as was the case for me on 9/29/22 when I first tried running this), load these from source: 
source activate beast2-env
source $(which env_parallel.bash)

## Line to make node list that's called below in parallel
scontrol show hostname > $src/node_list_${SLURM_JOB_ID}

## RUN BEAST IN PARALLEL
## This will loop through 1 run of each .xml file x 10 xml files
## Note that max threads that can be used on wheeler is 8; keep -j 1 to use Beast's internal parallelization
## Beast's internal parallelization and GNU parallel don't play nice and EFG and I can't figure out how make nested forloop notation work to parallelize 2 runs of 10 xml files
## So, we'll chunk this up, running loop for 10 runs, writing outputs to temp output folder, and then loop for 2nd set of 10 runs, writing loop to output folder
## JESSIE REMEMBER THAT YOU WILL HAVE TO MANUALLY ADD PREFIXES OR SUFFIXES TO FILE OUTPUT NAMES TO KEEP RUNS NAMED APPROPRIATELY

## RUN 1
#export LANG=C
#     env_parallel -j 1 --workdir $SLURM_SUBMIT_DIR --sshloginfile ./node_list_${SLURM_JOB_ID} \
#        'beast -seed 3478 -threads 8 $src/beast_n100_FiveTips_iteration{}_2023-03-30.xml' \
#        ::: {1..10}

#mkdir run1_beast_n100_FiveTips_2023-03-30
#mv beast_n100_FiveTips_iteration*_2023-03-30.trees run1_beast_n100_FiveTips_2023-03-30
#mv beast_n100_FiveTips_iteration*_2023-03-30.log run1_beast_n100_FiveTips_2023-03-30
##Don't uncomment the next line because if you move .xml.state files they don't move and things get weird
##mv beast_n100_FiveTips_iteration*_2023-03-13.xml.state run1_beast_n10_FiveTips_2023-03-13

## RUN 2
#export LANG=C
#     env_parallel -j 1 --workdir $SLURM_SUBMIT_DIR --sshloginfile ./node_list_${SLURM_JOB_ID} \
#        'beast -seed 3475 -threads 8 $src/beast_n100_FiveTips_iteration{}_2023-03-30.xml' \
#        ::: {1..10}

#mkdir run2_beast_n100_FiveTips_2023-03-30
#mv beast_n100_FiveTips_iteration*_2023-03-30.trees run2_beast_n100_FiveTips_2023-03-30
#mv beast_n100_FiveTips_iteration*_2023-03-30.log run2_beast_n100_FiveTips_2023-03-30
##Don't	uncomment the next line	because	if you move .xml.state files they don't	move and things	get weird
##mv beast_n100_FiveTips_iteration*_2023-03-13.xml.state run2_beast_n100_FiveTips_2023-03-13


## Redo runs with a subset of .xmls
export LANG=C
     env_parallel -j 1 --workdir $SLURM_SUBMIT_DIR --sshloginfile ./node_list_${SLURM_JOB_ID} \
        'beast -seed 0516 -threads 8 $src/beast_n100_FiveTips_iteration{}_2023-03-30_ForSingletonRun_2023-04-02.xml' \
        ::: {1..4}

mkdir run2_beast_n100_FiveTips_2023-03-30_ForSingletonRun_2023-04-02
mv beast_n100_FiveTips_iteration*_2023-03-30_ForSingletonRun_2023-04-02.trees run2_beast_n100_FiveTips_2023-03-30_ForSingletonRun_2023-04-02
mv beast_n100_FiveTips_iteration*_2023-03-30_ForSingletonRun_2023-04-02.log run2_beast_n100_FiveTips_2023-03-30_ForSingletonRun_2023-04-02







## Note on requesting nodes 
## Since this is parallelized to run one sample per node, and since you can only run 10 at once (because 10 subsets), request a max of 10 nodes. 
## Requesting something like 20 nodes would finish 2 runs/xml x 10 xmls = 20 runs in like 1.5 hours. BUT, 20 nodes could take days to queue up. 
## Requesting something like 5 nodes (in ntasks up top)  would take ~8 hours for 20 runs. 
## in the below call, -j is # jobs per node 
## jobs and threads have to be balanced; can do -j 8 and -threads 1 or -j 1 and threads 8; or intermediates like -j 2 and -threads 4
## -j 8 and threads 8 means things run slower because they’re competing with each other

## This 4-tip tree is taking ~30 mins/run. I need 20 trees. With ntasks= 5 nodes requested, I can run 5 trees at once and need 4 iterations of that to finish. So I think this means entire job would finish in 2 hours. 


###############


## This was the original script to try to iterate through parallel runs of 10 trees, looping through to run 2 runs of each tree
## BUT, THIS DOESN'T WORK!! 
## with -prefix flag, this breaks because it can't write .xml.state files. This is because Beast assumes prefix is a directory for some things (state files) but not others (names) 
#export LANG=C
#     env_parallel -j 1 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#        'beast -threads 8 -prefix run{1}_ $src/beast_n50_iteration{2}_ANHU-OREO_2023-02-11.xml' \
#        ::: 1 2 ::: {1..10}

## Old notes about this
## These 4 lines will make 2 independent runs of each .xml file x 10 xml files
## This is basically a nested for loop: first for loop is run number (corresponds to {1}); second for loop is iteration number (corresponds to {2})
##  use the ::: separator with parallel to specify multiple lists of parameters you would like to iterate over
## Problem with beast is that if you run it twice you just overwrite the first file in the next run. We want the same .xml to be able to output something different.
## To do this we’ll use “prefix”, which appends a prefix to the .xml name – hence why we use run#_

## super weirdly, "-prefix run{1}_" makes it so that .xml.state files can't be written or found. Every time this flag is there, I get the following error:
## "java.io.FileNotFoundException: run2_/beast_n50_iteration10_ANHU-OREO_2023-02-11.xml.state.new (No such file or directory)"
## I have no idea why, but I'm going to try removing this
## If that works and this means parallel runs, I'm just going to have to chunk this up and run two batches of 10 runs each, manually changing file names, and then run this a second time for a second batch

