#!/bin/bash

#SBATCH --ntasks=8
#SBATCH --ntasks-per-node=8
#SBATCH --time=48:00:00
#SBATCH --job-name=phyluce_assembly
#SBATCH --output=phyluce_assembly_out_%j
#SBATCH --error=phyluce_assembly_error_%j
#SBATCH --partition=normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

#module load miniconda3/4.10.3-an4v
#module load parallel/20210922-cfec
#source activate gatk-env
#source $(which env_parallel.bash)

#src=$SLURM_SUBMIT_DIR


## Script for processing of UCEs to make a UCE time tree 

## Activate environment set up for UCEs
## remember NEED eval conda shell bash hook line BEFORE conda activate env line
eval "$(conda shell.bash hook)"
conda activate uce-env
conda activate phyluce-env

## Since we did our Illumiprocessing and trimming of adaptors before our seqcap_pop pipeline, we'll pick up here with assembling the UCE contigs
## Follow instructions in the phyluce UCE Phylogenomics tutorial, beginning with the step called Assemble the data 

## STEP 1: ASSEMBLE THE DATA 
## Before running, make sure you follow the phyluce format to create the assembly.conf file
## Run phyluce_assembly_assemblo_spades 
## Don't forget to change this between assembly.conf or assembly_2ndround.conf depending on where you are in assembly process (takes ~3 days; you will hit walltime)
## Also note that you ran this step out of script phyluce_assembly_assemblo_spades.slurm, NOT in this script
## Also note that you ran into memory issues and that most tissues didn't fully process; manually specify --memory 46 to get 46GB RAM and note that directory sizes >84 in spades-assemblies likely indicate failure for some reason 
## Check individual spades.log and, if present, warnings.log files 
#phyluce_assembly_assemblo_spades \
#	--conf assembly.conf \
#	--output spades-assemblies \
#	--cores 8 \
#       --memory 46

## Assembly QC
## Tutorial says run this script against all directories of reads
#for i in /users/jlwill/wheeler-scratch/patagona/UCE/spades-assemblies/contigs/*.fasta;
#do
#	phyluce_assembly_get_fasta_lengths --input $i --csv;
#done

## STEP 2: FINDING UCE LOCI 
## Make sure you have UCE probe set downloaded (which I do)
## Run phyluce_assembly_match_contigs_to_probes
#phyluce_assembly_match_contigs_to_probes \
#    --contigs /users/jlwill/wheeler-scratch/patagona/UCE/spades-assemblies/contigs \
#    --probes /users/jlwill/wheeler-scratch/patagona/UCE/uce-5k-probes.fasta \
#    --output uce-search-results

## The output of this will tell us how many UCE loci we recovered of the 5K targeted. It will also tell us how many were removed as duplicates. 

## STEP 3: EXTRACTING UCE LOCI 
## Determine which taxa we want in our analysis, then generate a list of which UCE loci we enriched in each taxon (the "data matrix configuration file")
## Make sure you've created the taxon-set.conf file
## Create the data matrix configuration file 
#phyluce_assembly_get_match_counts \
#    --locus-db /users/jlwill/wheeler-scratch/patagona/UCE/uce-search-results/probe.matches.sqlite \
#    --taxon-list-config /users/jlwill/wheeler-scratch/patagona/UCE/taxon-set.conf \
#    --taxon-group 'all' \
#    --incomplete-matrix \
#    --output taxon-sets/all/all-taxa-incomplete.conf


## NOTE: PHYLUCE DOES NOT LIKE DASHES AND WILL CONVERT DASHES IN FILE NAMES TO UNDERSCORES!!! So names in all-taxa-incomplete.conf will not match contig names (if you started with dashes, as I did)
## I found tutorial online where Brant suggests changing contig names to dashes. I went back and did this at this step, so just note this. 
## Manually renaming contigs worked for me and I was able to run phyluce_assembly_get_fastas_from_match_counts without issue


## STEP 4: EXTRACT FASTA DATA THAT CORRESPOND TO LOCI IN THE ALL-TAXA-INCOMPLETE.CONF
#phyluce_assembly_get_fastas_from_match_counts \
#    --contigs /users/jlwill/wheeler-scratch/patagona/UCE/spades-assemblies/contigs \
#    --locus-db /users/jlwill/wheeler-scratch/patagona/UCE/uce-search-results/probe.matches.sqlite \
#    --match-count-output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/all-taxa-incomplete.conf \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/all-taxa-incomplete.fasta \
#    --incomplete-matrix /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/all-taxa-incomplete.incomplete \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

## STEP 5: EXPLODING THE MONOLITHIC FASTA FILE 
## explode the monolithic FASTA by taxon (you can also do by locus)
## I don't think this step is totally necessary...but it's also useful
## This step takes ~10 mins, so ok to run on debug with 1hr walltime
#phyluce_assembly_explode_get_fastas_file \
#    --input /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/all-taxa-incomplete.fasta \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/exploded-fastas \
#    --by-taxon

## get summary stats on the FASTAS
#for i in /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/exploded-fastas/*.fasta;
#do
#    phyluce_assembly_get_fasta_lengths --input $i --csv;
#done


## STEP 6: ALIGNING UCE LOCI 
## phyluce tutorial notes many options for this
## When taxa are closely related (<30-50 Mya), phyluce recommends edge-trimming alignments
## Make sure you run this from taxon-sets/all directory 
## align the data (took ~1 hr or maybe a little over)
#phyluce_align_seqcap_align \
#    --input /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/all-taxa-incomplete.fasta \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-edge-trimmed \
#    --taxa 64 \
#    --aligner mafft \
#    --cores 8 \
#    --incomplete-matrix \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

## Output summary data for these alignments
#phyluce_align_get_align_summary_data \
#    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-edge-trimmed \
#    --cores 8 \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

## STEP 7: INTERNAL TRIMMING
## Make sure you run out of taxon-set/all directory
## align the data - turn off trimming and output FASTA
#phyluce_align_seqcap_align \
#    --input /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/all-taxa-incomplete.fasta \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed \
#    --taxa 64 \
#    --aligner mafft \
#    --cores 8 \
#    --incomplete-matrix \
#    --output-format fasta \
#    --no-trim \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

## Trim using Gblocks
# run gblocks trimming on the alignments
#phyluce_align_get_gblocks_trimmed_alignments_from_untrimmed \
#    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks \
#    --cores 8 \
#    --log /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

## Output summary stats, if you wish
#phyluce_align_get_align_summary_data \
#    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks \
#    --cores 8 \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log


## STEP 8: ALIGNMENT CLEANING 
## Make sure this is run out of the taxon-sets/all directory
## Need to clean alignments because each contains a name that is a combination of a taxon name plus locus for each taxon; this isn't what we want downstream. 
## From here on out work with Gblocks trimmed alignments
## align the data - turn off trimming and output FASTA
#phyluce_align_remove_locus_name_from_files \
#    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean \
#    --cores 8 \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log


## STEP 9: FINAL DATA MATRICES 
## Brant says he analyzes 75% nad 95% complete matrices 
## Make sure this is run out of taxon-sets/all 
## Create a 75% complete data matrix
## the integer following --taxa is the number of TOTAL taxa
## and I use "75p" to denote the 75% complete matrix
#phyluce_align_get_only_loci_with_min_taxa \
#    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean \
#    --taxa 64 \
#    --percent 0.75 \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean-75Complete \
#    --cores 8 \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

# Now get 95% complete matrix
#phyluce_align_get_only_loci_with_min_taxa \
#    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean \
#    --taxa 64 \
#    --percent 0.95 \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean-95Complete \
#    --cores 8 \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

# Get 65% complete matrix
#phyluce_align_get_only_loci_with_min_taxa \
#    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean \
#    --taxa 64 \
#    --percent 0.65 \
#    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean-65Complete \
#    --cores 8 \
#    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

## STEP 10: PREPARING DATA FOR DOWNSTREAM ANALYSIS 
## Now we'll generate input files for subsequent phylogenetic analysis. Brant mostly uses Raxml or IQTree, both of which take phylip inputs
## build the concatenated data matrix
phyluce_align_concatenate_alignments \
    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean-65Complete \
    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean-65Complete-phylip \
    --phylip \
    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

phyluce_align_concatenate_alignments \
    --alignments /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean-65Complete \
    --output /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/all/mafft-nexus-internal-trimmed-gblocks-clean-65Complete-nexus \
    --nexus \
    --log-path /users/jlwill/wheeler-scratch/patagona/UCE/taxon-sets/log

## Now these files are ready for downstream tree-making and analysis
## See tutorial notes about specific ways to convert file formats









