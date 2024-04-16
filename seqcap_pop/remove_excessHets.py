#!/usr/bin/env python

'''
Made by Ethan Gyllenhaal (egyllenhaal@unm.edu)
Last updated 15 July 2019, for Python 2.7

Script for trimming a vcf file to remove loci with X or more individuals that are heterozygous.
This is primarily meant to resolve what we believe is a paralog problem
Assumes the input has a format of '[locus]_ID|<rest of line>'.
If your format is only '[locus]|<rest of line>' comment lines with locus_list and remove from conditionals.
If your format has a different locus name delimiter (e.g. '[locus]-'), change split char in assignment of locus variable.
For usage, need to decide how many heterozygotes are permissible at a given site.
Note that this takes the VCF into memory, so huge ones may have a memory problem. Also, assumes a complete matrix.

Usage is:
remove_excessHets.py -i /path/to/input.vcf -o /path/to/output.vcf -n *proportion heterozygote threshold*
'''

import sys, getopt, random

def main(argv):
    # initializing variables
    in_path = ''
    out_path = ''
    # read command line input
    # -h or --help for basic usage info
    # -i or --input for input fasta
    # -o or --output for output location for trimmed fasta
    # -n or --number for max proportion of heterozygotes at a given site, 
    try:
        opts, args = getopt.getopt(argv,"hi:o:n:",["input=","output=","number="])
    except:
        print 'random_vcf.py -i [input] -o [output] -n [max proportion heterozygote]'
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-help", "-h"):
            print 'random_vcf.py -i [input]  -o [output]'
            print 'Input is a vcf file with rows in order per locus with name starting with "[locus name]|".'
        elif opt in ("-i", "--input"):
            in_path = arg
        elif opt in ("-o", "--output"):
            out_path = arg
        elif opt in ("-n", "--number"):
            max_het = float(arg)            
    # sets up input and output files
  	in_vcf = open("{0}".format(in_path), 'r')
    vcf_lines = in_vcf.readlines()
    vcf_out = open("{0}".format(out_path), 'wg')
    snp_count = 0
    remove_count = 0
    indiv_count = 0
    # works through input lines
    for line in vcf_lines:
        # outputs non-locus lines
        if line.startswith("#"):
            vcf_out.write(line)
            if line.startswith("#CHROM"):
                indiv_count = len(line.split('\t'))-9
        else:
            temp_line = line.split('\t')
            het_count = 0
            for i in temp_line:
                if i.startswith("0/1"):
                    het_count += 1
            if max_het > float(het_count)/indiv_count:
                vcf_out.write(line)
                snp_count += 1
            else:
                remove_count += 1
    print("Kept {0} SNPs, removed {1}.".format(snp_count, remove_count))
        

if __name__ == '__main__':
    main(sys.argv[1:])
