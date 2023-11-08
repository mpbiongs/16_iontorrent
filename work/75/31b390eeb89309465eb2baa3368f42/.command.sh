#!/bin/bash -ue
qiime dada2 denoise-pyro     --i-demultiplexed-seqs demux.qza     --p-trunc-len 400     --p-trim-left 0     --p-trunc-q 4     --p-max-ee 4     --p-n-threads 4     --o-representative-sequences rep-seqs.qza     --o-table table.qza     --o-denoising-stats stats.qza     --verbose
