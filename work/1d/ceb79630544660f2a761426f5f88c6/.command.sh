#!/bin/bash -ue
qiime feature-table filter-features     --i-table table.qza     --p-min-frequency 50     --o-filtered-table filtered-table.qza
