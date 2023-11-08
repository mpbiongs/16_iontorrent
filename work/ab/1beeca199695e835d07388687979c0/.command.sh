#!/bin/bash -ue
mkdir B1-16s_SE_T1_dir
seqtk sample B1_16s_L001_R1_001.fastq.gz 10000 > B1-16s_SE_T1_L001_R1_001.fastq
seqtk sample null 10000 > B1-16s_SE_T1_L001_R2_001.fastq 
gzip *.fastq
mv B1-16s_SE_T1_*_001.fastq.gz B1-16s_SE_T1_dir
