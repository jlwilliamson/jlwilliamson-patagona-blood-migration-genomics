#!/bin/bash

#SBATCH --ntasks=100
#SBATCH --time=1:00:00
#SBATCH --output=psmcboot_out_%j
#SBATCH --error=psmcboot_error_%j
#SBATCH --partition=debug
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

cd $SLURM_SUBMIT_DIR
module load parallel/20210922-cfec

## Script to run PSMC with bootstrapping. See psmc_run_initial.pbs for trials with differnet iterations of PSMC.
## Note that inpput files were made in patagona.psmc.pbs script in patagona > psmc folder on CARC
## Input file contains data for 4 representative birds:
## NK163100 (21.55x coverage; Northern; Peru; Lima)
## NK279172 (27.81x coverage; Southern; Chile)
## B7093 (27.08 x coverage; Ecuador)
## USNM-645339 (21.36x coverage; Argentina; Tucuman)

## Start with default PSMC parameters and work from there; follow CARC GitHub QuickByte tutorial for guidance
## General workflow: run initial run on CARC, move results to Chris' Linux, plot on Linux (bc plotting hard w/ perl on CARC)
## -N is the number of iterations to use
## -t is the maximum coalescence time permitted
## -r is the initial theta/rho ratio (basically the per-base mutation rate divided by per-base recombination rate)
## -p is the most complicated; it effectively delimits the number of time intervals per parameter.
## Using e.g. '-p "25*1"' would mean 25 parameters each spanning one time interval
## The example has 28 parameters spanning 64 intervals (one spanning 4, 25 spanning 2, one spanning 4, then one spanning 6).
## The more recent intervals are on the left side of the expression.
## While you can technically use different parameters for each bird, Ethan said it's good form to use the same for all birds
## Patagona generation time = 2.735 (source: Bird et al. 2020)

## Run bootstrapped PSMC in parallel for each sample (100 bootstraps)
## Repeat this code chunk for each bird. What it does: in parallel, iterates through a single bird to run bootstrapped PSMC, then concatenates to make final file. 
## Note that $PBS_O_WORKDIR wasn't working as a variable because you didn't call module env-parallel (to do this, copy line from patagona.pbs). THEN, this will enable you to do:
## instead of absolute file calls, can change this back to $PBS_O_WORKDIR/ and then just the series of file paths you want to read to/write from, i.e. $PBS_O_WORKDIR/bootstrap
## file called _bootstrap_combined.psmc is -N25 -t12 -r4 -b -p "4+22*2+4+6+8"
## run3: -N25 -t14 -r4 -b -p "4+20*2+2+4+6" - note that I killed run 3 after 173855 was done and Arg was halfway through...going to try other parameters
## run 4: -t5 -r3 -b -p "8+6+4+15*2" So far this is the worse - past looks weird
## run 5: -t5 -r3 -p "4+20*2+4+6+8"
## run 6: -t13 -r5 -p "4+20*2+4+6+8"
## Anecdotally, it seems like -p time parameter doesn't have as much of an impact as t and r. But do NOT end with just 15*2 as you did in run 4; this makes past have a weird "ladder" that sticks out. 

## New Peru  bird - 173855
#     parallel -j 8 --sshloginfile $PBS_NODEFILE \
#        '/users/jlwill/wheeler-scratch/patagona/psmc/psmc -N25 -t13 -r5 -b -p "4+20*2+4+6+8" \
#        -o /users/jlwill/wheeler-scratch/patagona/psmc/bootstrap/peru_173855/Pgigas_northern_173855_bootstrap_r{}.psmc /users/jlwill/wheeler-scratch/patagona/psmc/psmc-inputfiles/Pgigas_northern_173855_psmc_input.psmcfa' \
#        ::: $(seq 50)
#cat Pgigas_northern_173855_bootstrap.psmc bootstrap/peru_173855/Pgigas_northern_173855_bootstrap_r*.psmc > bootstrap/Pgigas_northern_173855_bootstrap_combined_run6.psmc

# Argentina
#     parallel -j 8 --sshloginfile $PBS_NODEFILE \
#	'/users/jlwill/wheeler-scratch/patagona/psmc/psmc -N25 -t13 -r5 -b -p "4+20*2+4+6+8" \
#	-o /users/jlwill/wheeler-scratch/patagona/psmc/bootstrap/argentina_USNM-645339/Pgigas_central_USNM-645339_bootstrap_r{}.psmc /users/jlwill/wheeler-scratch/patagona/psmc/psmc-inputfiles/Pgigas_central_USNM-645339_psmc_input.psmcfa' \
#	::: $(seq 50)
#cat Pgigas_central_USNM-645339_bootstrap.psmc bootstrap/argentina_USNM-645339/Pgigas_central_USNM-645339_bootstrap_r*.psmc > bootstrap/Pgigas_central_USNM-645339_bootstrap_combined_run6.psmc

## Chile
## For some reason this one didn't want to load unless I specified direct input file path to psmc folder with the actual program
#     parallel --sshloginfile $PBS_NODEFILE \
#	'/users/jlwill/wheeler-scratch/patagona/psmc/psmc -N25 -t13 -r5 -b -p "4+20*2+4+6+8" \
#        -o /users/jlwill/wheeler-scratch/patagona/psmc/bootstrap/chile_279172/Pgigas_southern_279172_bootstrap_r{}.psmc /users/jlwill/wheeler-scratch/patagona/psmc/psmc-inputfiles/Pgigas_southern_279172_psmc_input.psmcfa' \
#        ::: $(seq 50)
#cat Pgigas_southern_279172_bootstrap.psmc bootstrap/chile_279172/Pgigas_southern_279172_bootstrap_r*.psmc > bootstrap/Pgigas_southern_279172_bootstrap_combined_run6.psmc

# Ecuador
#     parallel -j 8 --sshloginfile $PBS_NODEFILE \
#	'/users/jlwill/wheeler-scratch/patagona/psmc/psmc -N25 -t13 -r5 -b -p "4+20*2+4+6+8" \
#        -o /users/jlwill/wheeler-scratch/patagona/psmc/bootstrap/ecuador_B7903/Pgigas_northern_B7903_bootstrap_r{}.psmc /users/jlwill/wheeler-scratch/patagona/psmc/psmc-inputfiles/Pgigas_northern_B7903_psmc_input.psmcfa' \
#        ::: $(seq 50)
#cat Pgigas_northern_B7903_bootstrap.psmc bootstrap/ecuador_B7903/Pgigas_northern_B7903_bootstrap_r*.psmc > bootstrap/Pgigas_northern_B7903_bootstrap_combined_run6.psmc

# Peru
#     parallel -j 8 --sshloginfile $PBS_NODEFILE \
#	'psmc -N25 -t12 -r4 -b -p "8+4+22*2+4+6+8" \
#        -o /users/jlwill/wheeler-scratch/patagona/psmc/bootstrap/peru_163100/Pgigas_northern_163100_bootstrap_r{}.psmc /users/jlwill/wheeler-scratch/patagona/psmc/psmc-inputfiles/Pgigas_northern_163100_psmc_input.psmcfa' \
#        ::: $(seq 100)
#cat Pgigas_northern_163100_bootstrap.psmc bootstrap/peru_163100/Pgigas_northern_163100_bootstrap_r*.psmc > bootstrap/Pgigas_northern_163100_bootstrap_combined.psmc

## Chile - 279111
     parallel --sshloginfile $SLURM_JOB_NODELIST \
        '/users/jlwill/wheeler-scratch/patagona/psmc/psmc -N25 -t13 -r5 -b -p "4+20*2+4+6+8" \
        -o /users/jlwill/wheeler-scratch/patagona/psmc/bootstrap/chile_279111/Pgigas_southern_279111_bootstrap_r{}.psmc /users/jlwill/wheeler-scratch/patagona/psmc/psmc-inputfiles/Pgigas_southern_279111_psmc_input.psmcfa' \
        ::: $(seq 50)
cat Pgigas_southern_279111_bootstrap.psmc bootstrap/chile_279111/Pgigas_southern_279111_bootstrap_r*.psmc > bootstrap/Pgigas_southern_279111_bootstrap_combined_run6.psmc

## Chile - 252134
     parallel --sshloginfile $SLURM_JOB_NODELIST \
        '/users/jlwill/wheeler-scratch/patagona/psmc/psmc -N25 -t13 -r5 -b -p "4+20*2+4+6+8" \
        -o /users/jlwill/wheeler-scratch/patagona/psmc/bootstrap/chile_252134/Pgigas_southern_252134_bootstrap_r{}.psmc /users/jlwill/wheeler-scratch/patagona/psmc/psmc-inputfiles/Pgigas_southern_252134_psmc_input.psmcfa' \
        ::: $(seq 50)
cat Pgigas_southern_252134_bootstrap.psmc bootstrap/chile_252134/Pgigas_southern_252134_bootstrap_r*.psmc > bootstrap/Pgigas_southern_252134_bootstrap_combined_run6.psmc
