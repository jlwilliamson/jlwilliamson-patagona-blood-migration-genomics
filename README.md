# patagona-blood-migration-genomics

## Williamson et al. 2024, Extreme elevational migration spurred cryptic speciation in giant hummingbirds, PNAS (https://doi.org/10.5281/zenodo.10975589)

Last updated: 2024-04-15

**Other places data are archived:**
*All raw specimen data are accessioned in Arctos (www.arctosdb.org). 
*Migration data are uploaded to MoveBank (Project ID: 3594892529). 
*Code and scripts are in this GitHub repository (DOI: 10.5281/zenodo.10975589). 
*Raw genomes and UCE fastq files are on SRA (https://www.ncbi.nlm.nih.gov/bioproject/1101054). 
*Other raw data are archived on Dryad: (https://doi.org/10.5061/dryad.44j0zpcnp)

This repository contains scripts and code used in a study of latitudinal and elevational migration, blood physiology, morphology, and genomics of giant hummingbirds (*Patagona spp.*) in South America. In our paper, we report the world's longest hummingbird migration with the most extreme elevational shift and describe species-level divergence that had remained hidden in plain sight for hundreds of years. Field sampling spanned Chile to Peru and involved collaborative teams from the Museum of Southwestern Biology at the University of New Mexico, Centro de Ornitología y Biodiversidad (CORBIDI), and Pontificia Universidad Católica de Chile. 

Code and scripts are roughly arranged in sub-folders by topic. Workflow outlined below is roughly in the order of pipelines and analyses. If you use something here, please cite us (Williamson et al. 2024, PNAS; and repository DOI), or contact Jessie about who/what is best to cite. 

This README.md provides a description of data and files. Many .Rmd files include code to make plots; please note that all final plots were produced as multi-panel figures in Adobe Illustrator. 

This project would not have been possible without the tremendous efforts of museum collectors, past and present, and the devoted curators and collections managers who make natural history museums the gems that they are. I am deeply grateful to the following collections for contributions to this project: Museum of Southwestern Biology, American Museum of Natural History, Centro de Ornitología y Biodiversidad, Cornell University Museum of Vertebrates, Louisiana State University Museum of Natural Science, Florida Museum of Natural History, University of Kansas Biodiversity Institute, Harvard University Museum of Comparative Zoology, Smithsonian National Museum of Natural History, and the University of Washington Burke Museum. 


## Folders

**migration:**
`geo_analysis_FLightR_git.Rmd`: Script to analyze raw geolocator data (on MoveBank) using FLightR. Produce some diagnostics and plots. With a few exceptions, this follows online vignettes pretty closely. Patagona distribution shapefile is freely available from BirdLife. 

`patagona_migration_analysis_git.Rmd`: Some post-processing of geolocator tracks to crunch summary metrics and make plots (e.g., Fig. 1a).

`PTT_track_analysis_git.Rmd`: Analysis of PTT data from the one good devie (raw data on MoveBank), including Douglas Argos Filtering (DAF) within the MoveBank interface. Script cleans and analyzes data, crunches summary and other metrics, and includes code for some plots. 

-------

**blood**:
`Patagona_blood_analysis_git.Rmd`: Analysis of blood data collected from wild-caught and specimen-vouchered hummingbirds. All raw data is linked to vouchered specimens at the Museum of Southwestern Biology, other data on Dryad. 

-------

**morpho**:
`Patagona_morpho_analysis_git.Rmd`: Analysis of morphological data collected from wild-caught and specimen-vouchered hummingbirds spanning 154 years. All specimen measurements were taken by JLW. All measurements are linked to vouchered specimens at the museums listed above, data on Dryad.

-------

**gatk_genomes**:
Files for processing WGS data. 

`patagona.pbs`: Sequence data filtering and variant calling w/ GATK pipeline. 

`sample_list`: sample list for GATK pipeline, genomes only.

-------

**UCE_phyluce**:
Phyluce pipeline for UCES. See Brant Faircloth's great and extensive documentation; my scripts are all modified closely from the pipeline. 

`index_individual_bams.pbs`: Script to index bams. 

`patagona_illumi.pbs`: Clean UCE reads w/ Illumiprocessor. 

`taxon-set.conf`: basically the sample list that phyluce uses; required. 

`uce_phylogenomics.slurm`: Process UCEs and get data into usable format for UCE time tree. 

-------

**seqcap_pop**:
Sequence data filtering and variant calling w/ UCE data. 

`seqcappop_script.pbs`: variant calling for UCE data

`seqcappop2_UCEsfromgenomes.pbs`: Harvest UCEs from genomes; then combine UCEs from genomes with UCE data to call indels, realign, and call SNPS on the compiled dataset (n=70 birds). This script assumes that bams have already been made for UCE data; see 'seqcappop_script.pbs'. 

`remove_excessHets.py`: Trim a vcf file to remove loci with X or more individuals that are heterozygous to resolve our paralog problem. 

`run_heterozygote_filter.slurm`: EFG's script to take combined data, remove excess heterozygotes from each tissue UCEs and UCEs from genomes, merge, then output merged and filtered vcf. This dataset contains n=70 birds (all 35 tissue UCE birds and 35 of 36 WGS birds; excludes NK279003, which is related to NK279017).

`sample_list_tissueUCE_copy`: tissue UCE sample list 

`sample_list_from_genomes_noNK279003_copy`: genomes sample list 

-------

**pop_structure**:

`patagona_genomicPCA_git.Rmd`: Read in genomic (WGS and UCE data, run snprelate to make PCAs)

`convert_vcf_to_ped_for_snmf.sh`: Converts vcf to ped for snmf in R

`patagona_sNMF_git.Rmd`: run snmf in R

-------

**psmc**:
Demographic modeling 

`patagona.psmc.slurm`: Make input files for PSMC

`psmcbootstrap.slurm`: Run PSMC with bootstrap. Detailed notes at top of script.

`patagona_psmc_plots_git.Rmd`: Read in bootstrapped PSMC data and wrangle to make pretty plots. 


**toepads**: 
Toepad data involved many iterations of procedures, most of which didn't end up providing the kind of data resolution we wanted. See paper methods and supplement for full details. 

`toegen.slurm`: process genomes from toe pads. Applies to higher quality toepad samples.

-------

**mtgenome**: 

`mtgenome.slurm`: For obtaining mtgenome from references (retrieved from GenBank; see paper). Scripts for UCEs and toepads similar; adjust sample list as necessary. 

-------

**ND2**: 

`patagonaND2.pbs`: Rip ND2 from genomes and UCEs and collate into a nice fasta for multiple alignments and diagnostics. 

-------

**hbba**:
Exons 1 and 2 of the beta-a subunit of Hb. 

`patagonahbba.pbs`: Rips hbba from whole genomes and writes them out to a collated fasta file with all hbba sequences.

`sample_list_hbba`: Sample list for patagonahbba.pbs

-------

**beast**:
Trees were made w/ phyluce outputs, constructed in Beast (w/ Beauti interface) and RAxML. See paper methods for settings/parameters used and outgroups (taken from publicly-available GenBank data). 

`subset-100uce-loci-FiveTips.slurm`: Script to subset 100 UCE loci for making BEAST tree

`run_beast_parallel.slurm`: Run beast in parallel on CARC cluster. 

-------

**Fst**:

`pairwise_fst_all_comparisons.slurm`: Calculate pairwise Fst comparisons. See specific code and notes in this script for comparing with and without certain chromosomes and with and without NK279003. 

`windowed_fst.slurm`: Calculate windowed Fst for Manhattan plots

`sample_list_southern_NoNK279003`: Sample list for Fst pairwise comparisons 

`sample_list_northern`: Sample list for Fst pairwise comparisons 

`rename_vcf_fstpairs_for_manhattan_plot.sh`: Renaming script that's read in for renaming Fst pairs for Manhattan plots

`patagona_FstManhattan_git.Rmd`: Read in processed windowed Fst data to make Manhattan plots. 

-------

**pixy_pi**:

`pixy_pi_git.Rmd`: Calculate pi and nucleotide diversity, from whole Patagona genomes


-------

Questions? Contact me at jlw432 [at] cornell.edu.

