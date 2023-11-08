#!/bin/bash -ue
mkdir B2-16s_T1_dir
seqtk sample B2_16s_L001_R1_001.fastq.gz 10000 > B2-16s_T1_L001_R1_001.fastq
gzip *.fastq
mv B2-16s_T1_*_001.fastq.gz B2-16s_T1_dir
