#!/bin/bash -ue
qiime metadata tabulate     --m-input-file blastresults.qza     --o-visualization blastresults.qzv

qiime metadata tabulate     --m-input-file classification.qza     --o-visualization classification.qzv
