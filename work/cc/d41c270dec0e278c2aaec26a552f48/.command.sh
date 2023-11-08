#!/bin/bash -ue
qiime feature-classifier classify-consensus-blast     --i-query rep-seqs.qza     --i-reference-reads ncbi-refseqs.qza     --i-reference-taxonomy ncbi-refseqs-taxonomy.qza     --p-maxaccepts 1     --p-perc-identity 0.99     --p-query-cov 0.7     --o-classification classification.qza     --o-search-results blastresults.qza
