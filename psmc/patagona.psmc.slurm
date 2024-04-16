#!/bin/bash

#SBATCH --ntasks=32
#SBATCH --time=48:00:00
#SBATCH --job-name patagona
#SBATCH --mail-type=BEGIN|FAIL|END
#SBATCH --mail-user=williamson@unm.edu

cd $SLURM_SUBMIT_DIR
# if using PBS, 'cd $PBS_O_WORKDIR'
#cd $PBS_O_WORKDIR
module load miniconda3/4.8.2-pilj
eval "$(conda shell.bash hook)"
conda activate psmc-env

# Align with BWA
# When assigning variable with an absolute path, don't use $
reference=/users/jlwill/wheeler-scratch/patagona/reference/ANHU_reference.fna
bwa index -p $reference ${reference}.fna

# assuming you have 8 threads, not that this .sam file will be huge, and we'll remove it at the end
cat $src/psmc_sample_list | env_parallel -j 1 --sshloginfile $PBS_NODEFILE \
    'bwa mem \
        -t 8 \
        $reference \
        /users/jlwill/wheeler-scratch/patagona/clean_reads/{}_paired_R1.fastq.gz \
        /users/jlwill/wheeler-scratch/patagona/clean_reads/{}_paired_R2.fastq.gz \
        | samtools view -s -b - > /users/jlwill/wheeler-scratch/patagona/psmc/{}_unsort.bam

     # sort the .bam file
     picard SortSam I=/users/jlwill/wheeler-scratch/patagona/psmc/{}_unsort.bam \
     O=/users/jlwill/wheeler-scratch/patagona/psmc/{}_sort.bam SORT_ORDER=coordinate

# remove old files, comment out if you want to keep them to troubleshoot
#rm unsorted_alignment.bam

# pipeline combining bcftool's mpileup and call (consensus mode) using 8 threads, then samtools's vcfutils.pl
# the latter filters variants with a depth less than 10 or greater than 50, and those with quality score under 30
# -c = consensus sequence 
bcftools mpileup -Q 30 -q 30 -Ovu -f $reference.fna /users/jlwill/wheeler-scratch/patagona/psmc/{}_sort.bam --threads 8 | \
        bcftools call -c --threads 8 | \
        vcfutils.pl vcf2fq -d 10 -D 50 -Q 30 > /users/jlwill/wheeler-scratch/patagona/psmc/{}_psmc_variant_consensus.fq

# generate PSMC input
users/jlwill/wheeler-scratch/patagona/psmc/utils/fq2psmcfa /users/jlwill/wheeler-scratch/patagona/psmc/{}_psmc_variant_consensus.fq > \
/users/jlwill/wheeler-scratch/patagona/psmc/{}_psmc_input.psmcfa'

