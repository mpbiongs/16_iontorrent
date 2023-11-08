#!/bin/bash -ue
mkdir B2-16s_SE_T1_dir
seqtk sample B2_16s_L001_R1_001.fastq.gz 10000 > B2-16s_SE_T1_L001_R1_001.fastq
seqtk sample null 10000 > B2-16s_SE_T1_L001_R2_001.fastq 
gzip *.fastq
mv B2-16s_SE_T1_*_001.fastq.gz B2-16s_SE_T1_dir
