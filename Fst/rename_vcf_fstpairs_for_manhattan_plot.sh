#!/bin/bash

# This is a renaming script that's read in for renaming Fst pairs for Manhattan plots
# assumes first argument is vcf file
# second argument is the reference genome interval list, i.e., `intervals.list`
# What this does/says:
# $1 input, $2 interval list; while reading chromosome, do sed find and replace i with 1
# replaces name of first chrome in list with 1 
# adding 1 to i, increased by 1 each time
# No need to create separate files for 10k window and 50k window comparisons; use this same for both
# end says "send $2 into all other shit"

i=1

while read chrom; do
    sed -i "s/$chrom/$i/g" $1
    #echo sed -i 's/$chrom/$i/g' $1
    #echo $chrom $i
    i=$((i+1))
done < $2
