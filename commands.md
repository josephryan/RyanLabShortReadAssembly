# Commands used in Steinworth_et_al_2020-CnidarianHox
1\. Use  hmm2aln.pl to identify Hox/ParaHox and related homeodomains from translated transcriptomes and protein model files of selected cnidarian datasets.
--requires: `HMMer` (http://hmmer.org/) and `hmm2aln.pl` (https://github.com/josephryan/hmm2aln.pl )

 `./hmm2aln.pl --hmm=hd60.hmm --name=HD --fasta_dir=02-RENAMED_DATA --threads=40 --nofillcnf=nofill.hox.conf > cnid_hox_plus.fa`

_Manually combined all sequences in cnid_hox_plus.fa with bilaterian and known cnidarian homeoboxes to create file, all_hox_plus.fa_

2\. Generate an initial phylogenetic tree using resulting alignment from `hmm2aln.pl`
(requires IQ-tree (ADD URL)

iqtree-omp -s all_hox_plus.fa -nt AUTO -bb 1000 -m LG -pre MLtree_withgaps > iq.out 2> iq.err

3\. Using resulting tree and alignment, prune non-Hox/ParaHox genes using make subalignment
(requires `make_subalignment` (https://github.com/josephryan/make_subalignment)
`./make_subalignment2 --tree=MLtree_withgaps.treefile --aln=all_hox_plus.fa --root=Anthopleura_elegantissima_45195 --pre=Nvec`

4\. Using the resulting alignment from make_subalignment run the following ML trees 

  a\. RAXML with 25 starting parsimony trees
  `raxmlHPC-PTHREADS-SSE3 -T 25 -p 1234 -# 25 -m PROTGAMMALG -s subalign -n raxMLwithGaps_mp

  b\. RAXML with 25 random starting trees
  `raxmlHPC-PTHREADS-SSE3 -T 25 -d -p 1234 -# 25 -m PROTGAMMALG -s subalign -n raxMLwithGaps_rt`

  c\. IQTREE
  `iqtree -m LG+G4 -s subalign -pre iqtree_withgaps -bb 1000`

5\. Evaluate the likelihood scores of the IQTREE using RAxML (for apples-to-apples comparison of likelihoods)
`raxmlHPC-SSE3 -f e -m PROTGAMMALG -t iqtree_withgaps.treefile -s subalign -n iqtree_raxml`

_Manually compared Final GAMMA-based score of RAXML trees and IQTREE tree_ 

6\. for the best tre (RAxML maximum parsimony starting tree) ran and applied bootstraps

`raxmlHPC -m PROTGAMMALG -s subalign -p 12345 -x 12345 -# 100 -n raxml_mp_best `

`raxmlHPC -m PROTGAMMALG -p 12345 -f b -t RAxML_bestTree.raxMLwithGaps_mp -z RAxML_bootstrap.raxml_mp_best -n T15`

[DOES IT MAKE SENSE TO REPORT THE PREVIOUS STEPS SINCE THEY WERE ALL REDONE?  I WOULD JUST MOVE nogaps.py to #4 AND adjust filenames if necessary]
7\. Removed sequences with 5 or more gaps using custom script
./nogaps.py all_hox_plus.fa

_Manually added back in sequences cloned from Cassiopea xamachana to file all_hox_plus.fa_wholeSeqs and called this file final_all_hox_plus.fa_

ML tree
iqtree-omp -s final_all_hox_plus.fa -nt AUTO -bb 1000 -m LG -pre IQtree_init > iq.out 2> iq.err

Prune non-Hox/ParaHox genes using custom script
./make_subalignment2 --tree=IQtree_init.treefile --aln=final_all_hox_plus.fa --root=Alatina_alata_53079 --pre=Nvec

RAXML with 25 starting parsimony trees
raxmlHPC-PTHREADS-SSE3 -T AUTO -p 1234 -# 25 -m PROTGAMMALG -s ../02-SUBALIGN/subalign -n raxMLnoGaps_mp

RAXML with 25 random starting trees
raxmlHPC-PTHREADS-SSE3 -T AUTO -d -p 1234 -# 25 -m PROTGAMMALG -s ../02-SUBALIGN/subalign -n raxMLnoGaps_rt

IQTREE
iqtree -m LG+G4 -s subalign -pre IQtree_noGaps -bb 1000
raxmlHPC-SSE3 -f e -m PROTGAMMALG -t IQtree_noGaps.treefile -s subalign -n iqtree_raxml

Manually compared Final GAMMA-based score of RAXML trees and IQTREE tree, for the best tree (maximum parsimony starting tree) ran and applied bootstraps
raxmlHPC -m PROTGAMMALG -s subalign -p 12345 -x 12345 -# 100 -n nogaps_bootstraps

raxmlHPC -m PROTGAMMALG -p 12345 -f b -t RAxML_bestTree.raxMLnoGaps_mp -z RAxML_bootstrap.nogaps_bootstraps -n T15


Bayesian tree
fasta2phy.pl subalign > sub.phy
phy2bayesnex.pl sub.phy > hox.nex

paste execution block into hox.nex
execution block:
mcmcp ngen=10000000 samplefreq=10000 mcmcdiagn=yes stoprule=yes stopval=0.01       nruns=2 nchains=5 savebrlens=yes; mcmc; sumt filename=FILE.nex nRuns=2 Relburnin=YES BurninFrac=.25 Contype=Allcompat;).

mpirun -np 25 mb hox.nex


raxmlHPC-SSE3 -f e -m PROTGAMMALG -t hox.nex.run1.newick -s ../subalign -n bayes_run1_raxml

raxmlHPC-SSE3 -f e -m PROTGAMMALG -t 03_hox.nex.run2.newick -s ../subalign -n bayes_run2_raxml

raxmlHPC-SSE3 -f e -m PROTGAMMALG -t hox.nex.con.newick -s ../subalign -n bayes_con_raxml

Manually compare final GAMMA-based score to RAxML trees


AU Test
perl make_constraint_trees.pl > iq_script.sh

This script creates constraint trees for every paired combo of the following:
   1. cnidarian + cnidarian
   2. cnidarian + bilat
   3. cnidarian + mixed (mixed = clade like Gbx includes cnid + bilat)

It also creates 4 additional constraint trees:
   1. ax6,ax6a,bilat_hox1
   2. hd065,cdx,xlox
   3. ax1,ax1a,bilat_post
   4. ax1,ax1a,bilat_post,cent

Also prints out iqtree command lines to STDOUT which we directed to iq_script.sh

cat *.treefile > autest.treels

iqtree -s subalign -m LG+G4 -z autest.treels -n 0 -zb 1000 -au

Removing duplicate sequences from final tree
java -jar /usr/local/phyutility/phyutility.jar -pr -in TREENAME -out TREENAME.pruned -names NAME1 NAME2 NAME3

java -jar /usr/local/phyutility/phyutility.jar -pr -in RAxML_bipartitions.T15 -out RAxML_bipartitions.T15.pruned -names Corallium_rubrum_87184, Corallium_rubrum_87185, Corallium_rubrum_17719, Craspedacusta_sowerbyi_16174, Calvadosia_cruxmelitensis_1956, Corallium_rubrum_75060, Haliclystus_sanjuanensis_2068, Craspedacusta_sowerbyi_25502, Craspedacusta_sowerbyi_93900, Corallium_rubrum_89239, Corallium_rubrum_91898, Eunicella_cavolinii_29512, Alatina_alata_18573, Craspedacusta_sowerbyi_43026, Craspedacusta_sowerbyi_85141, Corallium_rubrum_75469, Cxam_transcriptome_73398

java -jar /usr/local/phyutility/phyutility.jar -pr -in RAxML_bipartitions.T15.pruned.renamed -out RAxML_bipartitions.T15.pruned.renamed -names Cxam_transcriptome_40272

^just because I forgot to remove Cxam_transcriptome_40272
