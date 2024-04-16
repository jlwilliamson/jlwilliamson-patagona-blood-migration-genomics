#!/bin/bash

#SBATCH --ntasks=144
#SBATCH --ntasks-per-node=8
#SBATCH --time=48:00:00
#SBATCH --job-name=mtgenome
#SBATCH --output=mtgenome_out_%j
#SBATCH --error=mtgenome_error_%j
#SBATCH --partition=normal
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=williamson@unm.edu

## NOTE: 
## WITHOUT the cpus-per-task call, ntasks should be # samples x ntasks-per-node (i.e., if 7 tasks per node with 12 genomes, ntasks should be 84) --> this is super important for parallel
## If just running on a single node, ntasks should just be equivalent to ntasks-per-node
## when cpus-per-task call is there, n-tasks becomes equal to the # nodes requested, and cpus-per-task means # cores per node you want
## Adding in this call allows you to request a full node (whereas this was breaking for us before when we tried to do this using n-tasks only)

## Load modules
module load miniconda3/4.10.3-an4v
module load parallel/20210922-cfec

## Activate modules
## eval conda shell.bash hook line allows conda to be called as conda, not source (EFG thinks this is because they're phasing out source)
## So run eval conda shell.bash hook line, THEN activate gatk-env and env_parallel with "conda" and not "source"
## remember NEED eval conda shell bash hook line BEFORE conda activate env line
#eval "$(conda shell.bash hook)"
#conda activate gatk-env
#conda $(which env_parallel.bash)
## BUT, if this isn't working for some reason (as was the case for me on 9/29/22 when I first tried running this), load these from source: 
source activate gatk-env
source activate bcftools-env
source $(which env_parallel.bash)


## When assigning variable with an absolute path, don't use $
reference=/users/jlwill/wheeler-scratch/patagona/mtgenome/reference-mtgenome/Amazilia_versicolor_mtgenome

> /users/jlwill/wheeler-scratch/patagona/mtgenome/output/mtgenome_secondhalf_combined_consensus.fasta

## Set source directory variable
src=$SLURM_SUBMIT_DIR

## Line to make node list that's called below in parallel
scontrol show hostname > $src/node_list_${SLURM_JOB_ID}


### INDEX REFERENCE
# brief, only need to do once (but do need this for ND2)
# Jessie did this on 12/29/22
#bwa index -p $reference ${reference}.fasta
#samtools faidx ${reference}.fasta -o ${reference}.fasta.fai
#picard CreateSequenceDictionary \
#        R=${reference}.fasta \
#        O=${reference}.dict


## ALIGN WITH  BWA
## assuming you have 8 threads, not that this .sam file will be huge, and we'll remove it at the end
## Make sure export LANG=C line is on its own line and outside of the parallel call
## Note that the flag to remove unmapped reads is "-F 4" down in the samtools line
export LANG=C
cat $PBS_O_WORKDIR/sample_list_mtgenome_secondhalf | env_parallel -j 8 --sshloginfile ./node_list_${SLURM_JOB_ID} \
    'bwa mem \
        -t 8 \
        $reference \
        /users/jlwill/wheeler-scratch/patagona/clean_reads/{}_paired_R1.fastq.gz \
        /users/jlwill/wheeler-scratch/patagona/clean_reads/{}_paired_R2.fastq.gz \
        | samtools view -b -F 4 - > /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/{}_unsort_mtgenome.bam

## sort the .bam file
     picard SortSam \
     -I /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/{}_unsort_mtgenome.bam \
     -O /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/{}_sort_mtgenome.bam \
     -SORT_ORDER coordinate

## remove old files, comment out if you want to keep them to troubleshoot
#rm unsorted_alignment.bam

## pipeline combining bcftool's mpileup and call using 8 threads, then samtools's vcfutils.pl
## vcfutils.pl filters variants with a depth less than 10 or greater than 50, and those with quality score under 30
## the -c = consensus sequence
## the echo part 3 lines from bottom makes the name of the fasta sequence that will appear as header of the fasta file
bcftools mpileup -Q 30 -q 30 -Ou -f $reference.fasta /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/{}_sort_mtgenome.bam --threads 8 | \
        bcftools call -mv -Oz --threads 8 -o /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/{}_mtgenome.vcf.gz
        bcftools index /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/{}_mtgenome.vcf.gz
        cat ${reference}.fasta | bcftools consensus /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/{}_mtgenome.vcf.gz > \
        /users/jlwill/wheeler-scratch/patagona/mtgenome/output/{}_consensus_mtgenome.fasta
        echo \>{}_mtgenome >> /users/jlwill/wheeler-scratch/patagona/mtgenome/output/mtgenome_secondhalf_combined_consensus.fasta
        tail -n +2 /users/jlwill/wheeler-scratch/patagona/mtgenome/output/{}_consensus_mtgenome.fasta >> /users/jlwill/wheeler-scratch/patagona/mtgenome/output/mtgenome_secondhalf_combined_consensus.fasta'

## Index individual bams with a loop
## I just tacked this on afterwards because you need .bam.bai files in order to open bam files using IGV
while read sample; do
    samtools index /users/jlwill/wheeler-scratch/patagona/mtgenome/bams-mtgenome/${sample}_sort_mtgenome.bam
done < /users/jlwill/wheeler-scratch/patagona/mtgenome/sample_list_mtgenome_secondhalf

## and now index unsorted reads so you can also take a look at these in IGV
#while read sample; do
#    samtools index /users/jlwill/wheeler-scratch/patagona/toepad_UCE_plus_genome_angsd/COI/genome-bams-COI/${sample}_unsort_COI.bam
#done < /users/jlwill/wheeler-scratch/patagona/toepad_UCE_plus_genome_angsd/COI/sample_list_genome_COI
