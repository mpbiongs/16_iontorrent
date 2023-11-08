#!/bin/bash -ue
qiime tools import     --type 'SampleData[SequencesWithQuality]'     --input-path B2-16s_T1_dir     --input-format CasavaOneEightSingleLanePerSampleDirFmt     --output-path demux.qza

qiime demux summarize     --i-data demux.qza     --o-visualization demux.qzv
