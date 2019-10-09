# RyanLabShortReadAssembly

### To install scripts in this distribution 

run the following:

    perl Makefile.PL
    make
    sudo make install

if you do not have permission to install to the system see the following:

    http://www.perlmonks.org/index.pl?node_id=128077#permission

----

## Our pipeline for assembling short reads

### 1. trim adapters

requires:http://www.usadellab.org/cms/?page=trimmomatic

    java -jar /usr/local/Trimmomatic-0.38/trimmomatic-0.38.jar PE -threads 12 -phred33 IN.R1.fq IN.R2.fq OUT.trim.R1.fq OUT.trim.unp1.fq OUT.trim.R2.fq OUT.trim.unp2.fq ILLUMINACLIP:/usr/local/Trimmomatic-0.38/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 > trimmo.log 2> trimmo.err &

### 2. error correction

requires:http://software.broadinstitute.org/allpaths-lg/blog/

    cat OUT.trim.unp1.fq OUT.trim.unp2.fq > OUT.trim.unp.concat.fq
    gzip -9 *.fq
    perl /usr/local/allpathslg-44837/src/ErrorCorrectReads.pl PAIRED_READS_A_IN=OUT.trim.R1.fq.gz PAIRED_READS_B_IN=OUT.trim.R2.fq.gz UNPAIRED_READS_IN=OUT.trim.unp.concat.fq.gz PAIRED_SEP=100 THREADS=160 PHRED_ENCODING=33 READS_OUT=Boltenia > ecr.out 2> ecr.err &

### 3. remove mt reads (usually run a preliminary platanus assembly—see plat.45 below—to identify/assemble the MT genome)

requires: https://github.com/josephryan/FastqSifter 

    FastqSifter --out=PREFIX_FOR_OUTFILES --fasta=CONTAM_OR_MT_FASTA {--left=LEFT_FASTQ --right=RIGHT_FASTQ and/or --unp=UNPAIRED_FASTQ --savereads 

### 4. Assemble genome (plat.pl from this repo)
requires: http://platanus.bio.titech.ac.jp/

(each assembly should be performed in it's own directory)


    plat.pl --out=blah.31 --k=31 --m=500 --left=blah.A.fq --right=blah.B.fq --unp=blah.unp.fq

    plat.pl --out=blah.45 --k=45 --m=500 --left=blah.A.fq --right=blah.B.fq --unp=blah.unp.fq

    plat.pl --out=blah.59 --k=59 --m=500 --left=blah.A.fq --right=blah.B.fq --unp=blah.unp.fq

    plat.pl --out=blah.73 --k=73 --m=500 --left=blah.A.fq --right=blah.B.fq --unp=blah.unp.fq

    plat.pl --out=blah.87 --k=87 --m=500 --left=blah.A.fq --right=blah.B.fq --unp=blah.unp.fq

### 4b. We are now removing contigs shorter than 200 at this stage:

requires: remove_short_and_sort from this repo and https://github.com/josephryan/JFR-PerlModules

    remove_short_and_sort blah.31/out_gapClosed.fa 200 > blah.31/out_gapClosed.fa.gte200

    remove_short_and_sort blah.45/out_gapClosed.fa 200 > blah.45/out_gapClosed.fa.gte200

    remove_short_and_sort blah.59/out_gapClosed.fa 200 > blah.59/out_gapClosed.fa.gte200

    remove_short_and_sort blah.73/out_gapClosed.fa 200 > blah.73/out_gapClosed.fa.gte200

    remove_short_and_sort blah.87/out_gapClosed.fa 200 > blah.87/out_gapClosed.fa.gte200

### 5. Choose best of five assemblies based on N50 and conserved orthologs. We use this tool:

    https://gvolante.riken.jp/analysis.html

### 6. Since different regions of the genome assemble better with different k-mers, we find that there are joins that can be gleaned from sub-optimal assemblies. To make these joins we generate artificial matepairs from suboptimal assemblies using matemaker: https://github.com/josephryan/matemaker 

(if blah.45 was optimal assembly)

    matemaker --assembly=../blah.31/out_gapClosed.fa.gte200 --insertsize=2000 --out=blah31.2k


    matemaker --assembly=../blah.31/out_gapClosed.fa.gte200 --insertsize=5000 --out=blah31.5k


    matemaker --assembly=../blah.31/out_gapClosed.fa.gte200 --insertsize=10000 --out=blah31.10k



    matemaker --assembly=../blah.59/out_gapClosed.fa.gte200 --insertsize=2000 --out=blah59.2k


    matemaker --assembly=../blah.59/out_gapClosed.fa.gte200 --insertsize=5000 --out=blah59.5k


    matemaker --assembly=../blah.59/out_gapClosed.fa.gte200 --insertsize=10000 --out=blah59.10k



    matemaker --assembly=../blah.73/out_gapClosed.fa.gte200 --insertsize=2000 --out=blah73.2k


    matemaker --assembly=../blah.73/out_gapClosed.fa.gte200 --insertsize=5000 --out=blah73.5k


    matemaker --assembly=../blah.73/out_gapClosed.fa.gte200 --insertsize=10000 --out=blah73.10k


    matemaker --assembly=../blah.87/out_gapClosed.fa.gte200 --insertsize=2000 --out=blah87.2k


    matemaker --assembly=../blah.87/out_gapClosed.fa.gte200 --insertsize=5000 --out=blah87.5k


    matemaker --assembly=../blah.87/out_gapClosed.fa.gte200 --insertsize=10000 --out=blah87.10k

### 7. Create a libraries.txt file that can be used by SSPACE to scaffold the best assembly with the artificial matepairs:

use a text editor:

    lib1 bwa blah31.2k.A.fq blah31.2k.B.fq 2000 0.25 FR
    lib2 bwa blah31.5k.A.fq blah31.5k.B.fq 5000 0.25 FR
    lib3 bwa blah31.10k.A.fq blah31.10k.B.fq 10000 0.25 FR
    lib4 bwa blah59.2k.A.fq blah59.2k.B.fq 2000 0.25 FR
    lib5 bwa blah59.5k.A.fq blah59.5k.B.fq 5000 0.25 FR
    lib6 bwa blah59.10k.A.fq blah59.10k.B.fq 10000 0.25 FR
    lib7 bwa blah73.2k.A.fq blah73.2k.B.fq 2000 0.25 FR
    lib8 bwa blah73.5k.A.fq blah73.5k.B.fq 5000 0.25 FR
    lib9 bwa blah73.10k.A.fq blah73.10k.B.fq 10000 0.25 FR
    lib10 bwa blah87.2k.A.fq blah87.2k.B.fq 2000 0.25 FR
    lib11 bwa blah87.5k.A.fq blah87.5k.B.fq 5000 0.25 FR
    lib12 bwa blah87.10k.A.fq blah87.10k.B.fq 10000 0.25 FR

Alternatively, you can run this command in the directory where the mate.fq files were created by matemaker. The regular expression would need to be adjusted according to the names of your files. The following would work if your files have names like this (assuming the 2nd number (10000) is insert size): plat.45.10000.A.fq

    ls -1 *.A.fq | perl -ne '$i++; m/(plat\.(\d+)\.(.*))\.A.fq/; print "lib$i bwa $1.A.fq $1.B.fq $3 0.25 FR\n";' > libraries.txt

### 8. We use SSPACE to scaffold the best assembly with the artificial matepairs:

requires: https://github.com/nsoranzo/sspace_basic


    perl /usr/local/SSPACE-STANDARD-3.0_linux-x86_64/SSPACE_Standard_v3.0.pl -l libraries.txt -s ../blah.87/out_gapClosed.fa -T 20 -k 5 -a 0.7 -x 0 -b blah

### 9. Remove scaffolds shorter than 200 basepairs (this is smallest accepted by GenBank) and sort by scaffold length
NOTE: We know remove short contigs earlier in the process, but this is still usually necessary for sorting SSPACE scaffolds

requires: remove_short_and_sort from this repo and https://github.com/josephryan/JFR-PerlModules

    remove_short_and_sort blah.final.scaffolds.fasta 200 > blah.gte200.fa

### 10. Replace definition lines. 

utility script in: https://github.com/josephryan/JFR-PerlModules

First determine the pad value by running:

    grep -c '^>' blah.gte200.fa | perl -ne '$num = scalar(split/|/); print "$num\n";'
    
Then replace the deflines using the pad value

    replace_deflines.pl --fasta=blah.gte200.fa --prefix=blah --pad=OUTPUT_OF_PREVIOUS_CMD > blah_scf.v1.fa
