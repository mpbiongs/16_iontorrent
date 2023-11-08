params.reads = "$projectDir/analysis2"
params.fastq = "$projectDir/seqs2/*.fastq.gz"
params.trunclen = 400
params.minreads = 50
params.refseqs = "$projectDir/ncbi-refseqs.qza"
params.reftax =  "$projectDir/ncbi-refseqs-taxonomy.qza"
params.maxaccepts = 1
params.artifacts = "$projectDir/artifacts"
params.outdir = "$projectDir/results"
params.input = "$projectDir/samples.csv"

include { INPUT_CHECK  } from './subworkflows/local/input_check'
include { SEQTK_SAMPLE } from './modules/local/seqtk/sample'


log.info """\
    MP - Q I I M E   P I P E L I N E
    ===================================
    Reads        : ${params.reads}
    Trunc Len    : ${params.trunclen}
    Min Reads    : ${params.minreads}
    """
    .stripIndent(true)

println "reads: $params.reads"

process FASTQC {

    tag "FastQC"
    container "andrewatmp/testf"

    input:
    path(reads)

    output:
    path "*_fastqc.{zip,html}", emit: fastqc_results

    script:
    """
    fastqc $reads
    """
}

process IMPORT {
    tag "Importing sequences"
    container "andrewatmp/testf"

    input:
    path(reads)

    output:
    path("demux.qza"), emit: demux
    path("demux.qzv"), emit: demuxvis

    script:

    """
    qiime tools import \
    --type 'SampleData[SequencesWithQuality]' \
    --input-path ${reads} \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt \
    --output-path demux.qza

    qiime demux summarize \
    --i-data demux.qza \
    --o-visualization demux.qzv
    """
}

process DEMUXVIS {

    tag "Quality Visualization"
    container "andrewatmp/testf"


    input:
    path(demux)

    output:
    path("demux.qzv"), emit: demuxvis

    script:

    """
    qiime demux summarize \
    --i-data ${demux} \
    --o-visualization demuxvis.qzv
    """
}

process DADA {

    tag "Dada2 Error Correction"
    container "andrewatmp/testf"


    input:
    path(qza)
    
    output:
    path("rep-seqs.qza"), emit: repseqs
    path("table.qza"), emit: table
    path("stats.qza"), emit: stats

    script:

    """
    qiime dada2 denoise-pyro \
    --i-demultiplexed-seqs $qza \
    --p-trunc-len ${params.trunclen} \
    --p-trim-left 0 \
    --p-trunc-q 4 \
    --p-max-ee 4 \
    --p-n-threads 4 \
    --o-representative-sequences rep-seqs.qza \
    --o-table table.qza \
    --o-denoising-stats stats.qza \
    --verbose
    """

}

process MINREADS {

    tag "Filtering for min reads"
    container "andrewatmp/testf"

    input:
    path(table)

    output:
    path("filtered-table.qza"), emit: filtered

    script:

    """
    qiime feature-table filter-features \
    --i-table ${table} \
    --p-min-frequency ${params.minreads} \
    --o-filtered-table filtered-table.qza
    """
}

process DADARESULTS {

    tag "Generate dada visualizations"
    container "andrewatmp/testf"


    input:
    path(repseqs)
    path(table)
    path(stats)
    path(filtered)

    output:
    path("rep-seqs.qzv"), emit: repseqsvis
    path("table.qzv"), emit: tablevis
    path("stats.qzv"), emit: statsvis
    path("filtered-table.qzv"), emit: filteredtablevis


    script:

    """
    qiime feature-table tabulate-seqs \
    --i-data $repseqs \
    --o-visualization rep-seqs.qzv

    qiime feature-table summarize \
    --i-table $table \
    --o-visualization table.qzv

    qiime feature-table summarize \
    --i-table $filtered \
    --o-visualization filtered-table.qzv

    qiime metadata tabulate \
    --m-input-file $stats \
    --o-visualization stats.qzv
    """
}

process CLASSIFY {

    tag "Classify using BLAST"
    container "andrewatmp/testf"


    input:
    path(refseqs)
    path(reftax)
    path(repseqs)

    output:
    path("classification.qza"), emit: classification
    path("blastresults.qza"), emit: blastresults

    script:

    """
    qiime feature-classifier classify-consensus-blast \
    --i-query $repseqs \
    --i-reference-reads $refseqs \
    --i-reference-taxonomy $reftax \
    --p-maxaccepts ${params.maxaccepts} \
    --p-perc-identity 0.99 \
    --p-query-cov 0.7 \
    --o-classification classification.qza \
    --o-search-results blastresults.qza 
    """
}

process TABULATE {

    tag "Tabulate Classify Results"
    input:
    path(classification)
    path(blastresults)

    output:
    path("classification.qzv"), emit: classificationvis
    path("blastresults.qzv"), emit: blastresultsvis
    
    script:
    """
    qiime metadata tabulate \
    --m-input-file $blastresults \
    --o-visualization blastresults.qzv

    qiime metadata tabulate \
    --m-input-file $classification \
    --o-visualization classification.qzv
  """
}

process BARPLOT {

    tag "Generate barplot"
    container "andrewatmp/qiime_unzip"
    publishDir params.outdir, mode: 'copy'

    input:
    path(filtered)
    path(classification)

    output:
    path("taxa-bar-plots.qzv"), emit: barplot
    path("*"), emit: data
    path("level-7.csv"), emit: species

    script:

    """
    qiime taxa barplot \
    --i-table $filtered \
    --i-taxonomy $classification \
    --o-visualization "taxa-bar-plots.qzv"

    mkdir extracted
    unzip taxa-bar-plots.qzv '*/data/*' -d extracted
    mv extracted/*/data/* .
    mv index.html Taxonomy_mqc.html
    rm -rf extracted
    """

}

process MAKETABLE {
    tag 'Make Table'
    container 'andrewatmp/plot2'
    stageInMode 'copy'
    stageOutMode 'copy'
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple path(species_csv), val(sample_id)
    path(logo)


    output:
    path("${sample_id}_report.html")
    path(logo)
    path("${sample_id}.csv")

    shell:
    """
    writehtml2.py $species_csv --sample_name "${sample_id}" $logo "${sample_id}_report.html"
    """
}

process MULTIQC {

    tag "MultiQC"
    container "andrewatmp/multiqc"
    stageInMode 'copy'
    stageOutMode 'copy'
    publishDir params.outdir, mode: 'copy'

    input:
    path(fastqc)

    output:
    path "."

    script:
    """
    multiqc .
    """
}

process MULTIQC2 {

    tag "MultiQC2"
    container "andrewatmp/multiqc"

    input:
    path(params.outdir)

    script:
    """
    multiqc .
    """
}




workflow {

    ch_input = file(params.input)
    INPUT_CHECK (
        ch_input
    )
    INPUT_CHECK.out.reads.view()

    SEQTK_SAMPLE(
        INPUT_CHECK.out.reads
    )

    SEQTK_SAMPLE.out.dir.view()

    IMPORT(SEQTK_SAMPLE.out.dir)

    dada_ch = DADA(IMPORT.out.demux)
    filtered_ch = MINREADS(DADA.out.table)
    DADARESULTS(dada_ch, filtered_ch)

    classification_ch = CLASSIFY(params.refseqs, params.reftax, DADA.out.repseqs)
    TABULATE(classification_ch)

    BARPLOT(filtered_ch, CLASSIFY.out.classification)
    MAKETABLE(species_ch, params.logo)

    // species_ch = BARPLOT.out.species
    // MAKETABLE(species_ch)

    //multiqc_files = Channel.empty()
    //multiqc_files = multiqc_files.mix(FASTQC.out.fastqc_results)
    //multiqc_files = multiqc_files.mix(BARPLOT.out.data)
    //multiqc_files = multiqc_files.mix(MAKETABLE.out.table)
    //MULTIQC(multiqc_files.collect())
    // BARPLOT.out.data.view()

    // MULTIQC2(BARPLOT.out.data)
}
