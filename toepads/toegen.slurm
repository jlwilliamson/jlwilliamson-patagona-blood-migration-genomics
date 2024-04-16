#!/bin/bash

#SBATCH --ntasks=7
#SBATCH --ntasks-per-node=7
#SBATCH --time=1:00:00
#SBATCH --job-name=toegen
#SBATCH --output=toegen_out_%j
#SBATCH --error=toegen_error_%j
#SBATCH --partition=debug
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

## NOTE: ntasks should be # samples x ntasks-per-node (i.e., if 7 tasks per node with 12 genomes, ntasks should be 84) --> this is super important for parallel
## If just running on a single node, ntasks should just be equivalent to ntasks-per-node

module load miniconda3/4.10.3-an4v
module load parallel/20210922-cfec

## eval conda shell.bash hook line allows conda to be called as conda, not source (EFG thinks this is because they're phasing out source)
## So ideally, run this line, THEN activate gatk-env and env_parallel with "conda" and not "source"
## remember NEED eval conda shell bash hook line BEFORE conda activate env line
#eval "$(conda shell.bash hook)"
#conda activate gatk-env
#conda $(which env_parallel.bash)
## Activate GATK4 environment (you'll activate GATK3 environment down below for UnifiedGenotyper)
source activate gatk-env
source $(which env_parallel.bash)

src=$SLURM_SUBMIT_DIR
#reference=$/users/jlwill/wheeler-scratch/patagona/reference/ANHU_reference
reference=~/wheeler-scratch/patagona/reference/ANHU_reference

## Line to make node list that's called below in parallel
scontrol show hostname > $src/node_list_${SLURM_JOB_ID}

## This is script to process genomes from toe pads
## Note that some chunks are commented out because we've done these at earlier steps in our bioinformatics pipeline


### INDEX REFERENCE  
## brief, only need to do once
## Since this was gone for our Oregon genome processing we don't need to redo it here
#bwa index -p $reference ${reference}.fna
#samtools faidx ${reference}.fna -o ${reference}.fna.fai
#picard CreateSequenceDictionary \
#       R=${reference}.fna \
#       O=${reference}.dict


### TRIMMING SECTION 
## only need to do once
## assumes you have the trimmomatic fasta in your ref folder (or just redirect via direct file path to where these are stored)
## Make sure export LANG=C line is on its own line and outside of the parallel call
#adapters=/users/jlwill/wheeler-scratch/patagona/reference/TruSeq3-PE.fa
#export LANG=C
#cat $src/sample_list_toegen | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#    'read1=$src/raw_reads/{}_R1.fastq.gz
#    read2=$src/raw_reads/{}_R2.fastq.gz
#    paired_r1=$src/clean_reads/{}_paired_R1.fastq.gz
#    paired_r2=$src/clean_reads/{}_paired_R2.fastq.gz
#    unpaired_r1=$src/clean_reads/{}_unpaired_R1.fastq.gz
#    unpaired_r2=$src/clean_reads/{}_unpaired_R2.fastq.gz
#    ## the minimum read length accepted, we do the liberal 30bp here
#    min_length=30
#    trimmomatic PE -threads 1 \
#	$read1 $read2 $paired_r1 $unpaired_r1 $paired_r2 $unpaired_r2 \
#	ILLUMINACLIP:${adapters}:2:30:10:2:keepBothReads \
#	LEADING:3 TRAILING:3 MINLEN:${min_length}'


### SECTION FOR ALIGNMENT AND MARKING DUPLICATES 
## Note we parallelize such that BWA uses exactly one node.
## Then, we have a number of jobs equal to the number of nodes requested.
## MarkDuplicates can take a while depending on the reference and number of reads
## you may need to break it into steps for certain files
## Jessie & Ethan modified lines MarkDuplicates to speed up processing on 12/14/21; definitely helped
## Make sure you remove any bam.parts directories already written before running the gatk code chunk
## or this won't work; also note: seemed faster when each bird had its own directory (as is written
## now) vs when all birds were dumped into the same massive directory
#export LANG=C
#cat $src/sample_list_toegen | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#    'bwa mem \
#    	 -t 8 -M \
#	 -R "@RG\tID:{}\tPL:ILLUMINA\tLB:{}\tSM:{}" \
#	 $reference \
#	 $src/clean_reads/{}_paired_R1.fastq.gz \
#	 $src/clean_reads/{}_paired_R2.fastq.gz \
#	 > $src/alignments/{}.sam
#     mkdir $src/alignments/dedup_temp/{}
#     mkdir $src/alignments/dedup_temp/spark/{}
#     gatk --java-options "-Xmx44g" MarkDuplicatesSpark \
#	 -I $src/alignments/{}.sam \
#	 --tmp-dir $src/alignments/dedup_temp/{} \
#	 --conf "spark.local.dir=$src/alignments/dedup_temp/spark/{}" \
#	 --spark-master local[*] \
#	 --verbosity ERROR \
#	 -O $src/bams/{}_dedup.bam
#    rm $src/alignments/{}.sam'


### COLLECTING METRICS IN PARALLEL
## WHOLE CHUNK COMMENTED OUT
## Remember to change from _recal to _dedup if you can’t do base recalibration.
## Also, depth will take A LOT of room up, 
## so you may not want to run it until you know what to do with it. 
#export LANG=C
#cat $src/sample_list_toegen | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#    'picard CollectAlignmentSummaryMetrics \
#    	    R=${reference}.fna \
#	    I=$src/bams/{}_dedup.bam \
#	    O=$src/alignments/alignment_summary/{}_alignment_summary.txt
#     picard CollectInsertSizeMetrics \
#  	    INPUT=$src/bams/{}_dedup.bam \
#	    OUTPUT=$src/alignments/insert_metrics/{}_insert_size.txt \
#	    HISTOGRAM_FILE=$src/alignments/insert_metrics/{}_insert_hist.pdf
#     samtools depth \
#   	    -a $src/bams/{}_dedup.bam \
#           > $src/alignments/depth/{}_depth.txt'


### SCATTER-GATHER HAPLOTYPE CALLER
## DON'T RUN THIS IF RUNNING UNIFIED GENOTYPER
## probably the most likely to need checkpoints.
## This can take a lot of different forms, this one is best for large files.
## Note that if the job terminates early, you have to redo the whole sample with this set up
## That shouldn't be too big of a problem, tho
#cut -f 1 ${reference}.fna.fai > $src/intervals.list
#export LANG=C
#env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#      'mkdir ${src}/gvcfs/{1}
#      gatk --java-options "-Xmx6g" HaplotypeCaller \
#           -R ${reference}.fna \
#	   -I $src/bams/{1}_dedup.bam \
#	   -O $src/gvcfs/{1}/{1}_{2}_raw.g.vcf.gz \
#	   -L {2} \
#	   -ERC GVCF' ::: $(cat $src/sample_list_toegen) ::: $(cat $src/intervals.list)


# DEACTIVATE GATK4 ENVIRONMENT
conda deactivate    

# ACTIVATE  GATK3 ENVIRONMENT (older gatk3 supports UnifiedGenotyper)
source activate gatk3-env



## INDEL REALIGNER TARGET CREATOR (gatk; UnifiedGenotyper; used instead of HaplotypeCaller for speed/efficiency)
# Start by finding indels and re-aligning (note that this is run on individual birds)
# Per individual; because of this, each uses 1 core. Only want number of cores equal to what we have
# So 5 nodes, 8 cores per node 
# Next code block is per interval
# Flag -T is unique to gatk, means "tool"; dont' need to specify java as before  
#export LANG=C
#cat $src/sample_list_toegen | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#    'gatk -Xmx5g -T RealignerTargetCreator -R ${reference}.fna \
#          -I $src/bams/{}_dedup.bam \
#          -o $src/bams/{}_realign.intervals
#     gatk -Xmx5g -T IndelRealigner -R ${reference}.fna \
#          -targetIntervals $src/bams/{}_realign.intervals \
#          -I $src/bams/{}_dedup.bam \
#          -o $src/bams/{}_realign.bam'



## --> BRING IN NORTHERN AND SOUTHERN REFERENCES HERE!!!! (that will help me place these toepads in a PCA)
## I can do this in two ways: 
## 1) copy SAMPLE_realign.bam files from references into toepad genomes/bams folder; then make a new sample list with these to use 
## 2) Ethan said I can add 2 lines to the end of my loop that call these birds and add them to the bam list
## I think it would be easier to just copy these files into my working bam folder, so I'll take that approach


## BAM_LIST LOOP OF SAMPLES TO FEED INTO UNIFIED GENOTYPER 
## IT IS ESSENTIAL THAT THIS IS UNCOMMENTED WHEN YOU RUN UNIFIED GENOTYPER OTHERWISE IT WON'T WORK!! 
## This is because this bam_list isn't written to a file; it's just a list that is created and then fed into UnifiedGenotyper
## similar to step below in genomicsdb import with interval_list=""
## says: get every bam file we have and put them together; string of -I; prevents manually writing many lines
## Use echo $bam_list to verify that the bam list is working properly; your string of output sample names will appear in the _output file for the job 
#bam_list=""
#while read sample; do
#    bam_list="${bam_list}-I ${src}/bams/${sample}_realign.bam "
#done < $src/sample_list_toegen_northsouthrefs
#echo $bam_list

## UNIFIED GENOTYPER ...but w/ interval call instead of samples 
## -glm is genotype likelihood model; EFG thinks optional but good to include; ploidy = diploid (also optional)
## basically same out at genotype GVCFS; one interaval, all indivs
## each output is one interval for all indivs (-L = interval list) BUT w/ parallel, ultimately, output is all intervals and all individuals
## Ethan said there's a samtools call to discard unmapped reads, which might help us 
#export LANG=C 
#cat $src/intervals.list | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#    'gatk -Xmx40g -T UnifiedGenotyper -R ${reference}.fna \
#          ${bam_list} \
#          -ploidy 2 -glm SNP \
#          -L {} \
#          -o $src/combined_vcfs/intervals/{}_genotyped.vcf.gz'

## NOW DEACTIVATE GATK3 ENVIRONMENT
conda deactivate 

# ACTIVATE GATK4 ENVIRO (what we want for rest of analyses)
source activate gatk-env


#######

## NOTE!!! If running Unified Genotyper, you do NOT need GenomicsDBImport and GenotypGVCFS since already done
## Skip these and pick up at "make a file with a list of paths for GatherVCFS to use" below  

### GENOMICSDBIMPORT (Skip if running GATK3 UnifiedGenotyper)
## This runs it scatter-gather for all samples
## the path to each interval (genomics_databases/{interval}) must be empty
#export LANG=C
#cat $src/intervals.list | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#    'mkdir $src/gendb_temp/{}
#    interval_list=""
#    # loop to generate list of sample-specific intervals to combine
#    while read sample; do
#          interval_list="${interval_list}-V ${src}/gvcfs/${sample}/${sample}_{}_raw.g.vcf.gz "
#          done < $src/sample_list_toegen
#    gatk --java-options "-Xmx6g" GenomicsDBImport \
#         ${interval_list} \
#         --genomicsdb-workspace-path $src/genomics_databases/{} \
#         --tmp-dir $src/gendb_temp/{} \
#         -L {}'

## GENOTYPEGVCFS (Skip if running GATK3 UnifiedGenotyper)
## Runs on each interval GVCF
#export LANG=C
#cat $src/intervals.list | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
#    'gatk --java-options "-Xmx6g" GenotypeGVCFs \
#    	  -R ${reference}.fna \
#	  -V gendb://$src/genomics_databases/{} \
#	  -O $src/combined_vcfs/intervals/{}_genotyped.vcf.gz'


#######


## TRANSITION TO USING A SINGLE NODE HERE 
## This point onward doesn't use parallel; bump n tasks down to match the number of n-tasks-per-node (likely 7 total) 
## Best practice would be to stop here and restart with a single node


## Make a file with a list of paths for GatherVcfs to use
## Overwrite gather list from before; but now, spit out path to file; output = text file w/ new line for 
## every interval we're combining 
#> $src/combined_vcfs/gather_list
#while read interval; do
#      echo ${src}/combined_vcfs/intervals/${interval}_genotyped.vcf.gz >> \
#      $src/combined_vcfs/gather_list
#done < $src/intervals.list

## RUN GATHERVCFS
#gatk GatherVcfs \
#     -I $src/combined_vcfs/gather_list \
#     -O $src/combined_vcfs/combined_vcf.vcf.gz

## INDEX THE GATHERED VCF
## gather VCF doesn't automatically index, so we do it here 
#gatk IndexFeatureFile \
#     -I $src/combined_vcfs/combined_vcf.vcf.gz

## SELECT AND FILTER VARIANTS
## Saying: we have called variants (SNPs and indels); take SNPS, put in one file, then take indels and put them
## in another file
## can look inside combined_vcfs folder; can compare indel and SNP file sizes, roughly match combined_vcf
## Select SNPS
#gatk SelectVariants \
#     -R ${reference}.fna \
#     -V $src/combined_vcfs/combined_vcf.vcf.gz \
#     -select-type SNP \
#     -O $src/combined_vcfs/raw_snps.vcf.gz

## SELECT INDELS
#gatk SelectVariants \
#     -R ${reference}.fna \
#     -V $src/combined_vcfs/combined_vcf.vcf.gz \
#     -select-type INDEL \
#     -O $src/combined_vcfs/raw_indel.vcf.gz

## FILTERING STEP
## EFG SAYS MAYBE REMOVE DEPTH FILTER BC LOW COVERAGE (DP AND QD, REMOVE BOTH)
## DP is depth of coverage
## QD is quality by depth; EFG says 2 is standard
#gatk VariantFiltration \
#     -R ${reference}.fna \
#     -V $src/combined_vcfs/raw_snps.vcf.gz \
#     -O $src/analysis_vcfs/filtered_snps.vcf  \
#     -filter "QUAL < 30.0" --filter-name "Q_filter" \
#     -filter "FS > 60.0" --filter-name "FS_filter" \
#     -filter "MQ < 40.0" --filter-name "MQ_filter"

## Removed these following Ethan's recommendations becasue of low coverage for toepads:
##     -filter "DP < 4" --filter-name "DP_filter" \
##     -filter "QD < 2.0" --filter-name "QD_filter" \




#### PRODUCE FINAL DATA MATRICES FOR ANALYSIS 

## VCFTOOLS FILTER TO PRODUCE FINAL ANALYSIS VCF
## mac = don't want singleton on one chromosome
## min-meanDP = min depth for a site NOT individual (determine based in estimates in idepth file)
## not-chr flag means exclude W chromosome (NC_044276.1); which we want so we don't get weird alignment issues for males
## Can  circle back later and get W chromosome info for females

## Make a 75% complete matrix file
#vcftools --vcf $src/analysis_vcfs/filtered_snps.vcf --out $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_75complete \
#	--not-chr NC_044276.1 \
#	--remove-indels \
#	 --remove-filtered-all \
#	--min-alleles 2 \
#	--max-alleles 2 \
#	--mac 2 \
#	--max-meanDP 8 \
#	--max-missing .75 \
#	--thin 10000 \
#	--recode
#mv $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_75complete.recode.vcf $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_75complete.vcf

## Now make a 50% complete matrix
## This is option pessimistic (based on quick peek at low coverage that Ethan pulled 
#vcftools --vcf $src/analysis_vcfs/filtered_snps.vcf --out $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_50complete \
#        --not-chr NC_044276.1 \
#        --remove-indels \
#	--remove-filtered-all \
#        --min-alleles 2 \
#	--max-alleles 2 \
#	--mac 2 \
#        --max-meanDP 8 \
#	--max-missing .50 \
#	--thin 10000 \
#	--recode
#mv $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_50complete.recode.vcf $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_50complete.vcf

## Now make a 100% complete matrix
#vcftools --vcf $src/analysis_vcfs/filtered_snps.vcf --out $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_100complete \
#	--not-chr NC_044276.1 \
#	--remove-indels \
#	--remove-filtered-all \
#	--min-alleles 2 \
#	--max-alleles 2 \
#	--mac 2 \
#	--max-meanDP 8 \
#	--max-missing 1 \
#	--thin 10000 \
#	--recode
#mv $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_100complete.recode.vcf $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_100complete.vcf



###


## Script to get depth and coverage for all birds in our whole genome dataset 
## Note that we normally use the pre-final filtered_snps.vcf file (GATK output) but because vcftools eliminates probelmatic SNPS
## So to see if our depth improves by eliminating those, we'll run this on the vcftools (final) output

vcftools --vcf $src/analysis_vcfs/patagona_toepadgenomes_northsouthrefs_vcftoolsfilter_10kthin_100complete.vcf \
	--out $src/analysis_vcfs/vcftools_filtered_toepadgenomes_depth \
	--remove-indels \
	--depth
