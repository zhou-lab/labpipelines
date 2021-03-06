# arrayExpress data downlaod MCF7
# wget --limit-rate 1M ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR361/ERR361749/ERR361749_1.fastq.gz
# wget --limit-rate 1M ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR361/ERR361749/ERR361749_2.fastq.gz
# mv ERR361749_1.fastq.gz MCF7_1.fastq.gz
# mv ERR361749_2.fastq.gz MCF7_2.fastq.gz

# [sra]
# MCF7_Cunha      SRR1036970,SRR1036971,SRR1036972,SRR1036973,SRR1036974,SRR1036975
# [alignment]
# MCF7_Cunha
# MCF7

source $WZSEQ_ENTRY
wzref_hg19
pipeline_prepare

while read sname; do
  jump_comments

  # ### QC fastq ####
  # input_fastq1=fastq/${sname}_1.fastq.gz
  # input_fastq2=fastq/${sname}_2.fastq.gz
  # output_fastq1=fastq/${sname}_1_trimmomatic.fastq.gz
  # output_fastq2=fastq/${sname}_2_trimmomatic.fastq.gz
  # hour=48; memG=10; ppn=10; queue=all.q
  # pipeline_depend none
  # pipeline_eval 1 __wzseq_trimmomatic_PE

  ### QC fastq ####
  pipeline_depend none
  fastq1=fastq/${sname}_1.fastq.gz
  fastq2=fastq/${sname}_2.fastq.gz
  trim_galore_dir=fastq_trim_galore/$sname/
  ppn=2; queue=all.q
  pipeline_eval 1 __wzseq_trim_galore_PE2
  
  fastq=fastq_trim_galore/${sname}/${sname}_1_val_1.fq.gz
  fastq_sname=${sname}_R1
  ppn=1; queue=all.q
  pipeline_depend none
  pipeline_eval 2 __wzseq_fastqc

  fastq=fastq_trim_galore/${sname}/${sname}_2_val_2.fq.gz
  fastq_sname=${sname}_R2
  ppn=1; queue=all.q
  pipeline_depend none
  pipeline_eval 3 __wzseq_fastqc

  ## alignment
  pipeline_depend none
  # fastq1=fastq/${sname}_1.fastq.gz
  # fastq2=fastq/${sname}_2.fastq.gz
  fastq1=fastq_trim_galore/${sname}/${sname}_1_val_1.fq.gz
  fastq2=fastq_trim_galore/${sname}/${sname}_2_val_2.fq.gz
  output_bam=bam/${sname}.bam
  ppn=12; queue=all.q
  pipeline_depend none
  pipeline_eval 11 __wgbs_biscuit_align_PE
  bam=bam/${sname}.bam
  ppn=1
  pipeline_eval 12 __wzseq_index_bam

  input_bam=bam/${sname}.bam
  output_bam=bam/${sname}_markdup.bam
  hour=36; memG=10; ppn=2; queue=all.q
  pipeline_eval 13 __wgbs_biscuit_markdup
  bam=bam/${sname}_markdup.bam
  hour=1; memG=5; ppn=1; queue=all.q
  pipeline_eval 14 __wzseq_index_bam

  ## pileup
  input_bam=bam/${sname}_markdup.bam
  output_vcf=pileup/${sname}.vcf.gz
  ppn=12; queue=all.q
  pipeline_depend 14
  pipeline_eval 15 __wgbs_biscuit_pileup

  input_bam=bam/${sname}_markdup.bam
  input_vcf=pileup/${sname}.vcf.gz
  hour=48; memG=20; ppn=2; queue=all.q
  pipeline_eval 16 __wgbs_biscuit_QC

  input_bam=bam/${sname}_markdup.bam
  output_sname=$sname
  hour=24; memG=50; ppn=10; queue=all.q
  pipeline_depend 14
  pipeline_eval 23 __wzseq_qualimap_bamqc

  fastq=fastq/${sname}_L005_R1_001.fastq.gz
  output_bam=bam/${sname}_SE_mate1.bam
  hour=48; memG=200; ppn=28; queue=longq;
  pipeline_depend none
  pipeline_eval 50 __wgbs_biscuit_align_SE
  bam=bam/${sname}_SE_mate1.bam
  hour=1; memG=15; ppn=1; queue=longq;
  pipeline_eval 51 __wzseq_index_bam
  
  input_bam=bam/${sname}_SE_mate1.bam
  output_sname=${sname}_SE_mate1
  hour=24; memG=50; ppn=10; queue=all.q
  pipeline_depend none
  pipeline_eval 52 __wzseq_qualimap_bamqc
  
done << EOM
# MCF7
# MCF7_Cunha
MCF7_Cunha10k
EOM


