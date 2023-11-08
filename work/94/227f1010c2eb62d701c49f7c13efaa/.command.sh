#!/bin/bash -ue
qiime feature-table tabulate-seqs     --i-data rep-seqs.qza     --o-visualization rep-seqs.qzv

qiime feature-table summarize     --i-table table.qza     --o-visualization table.qzv

qiime feature-table summarize     --i-table filtered-table.qza     --o-visualization filtered-table.qzv

qiime metadata tabulate     --m-input-file stats.qza     --o-visualization stats.qzv
