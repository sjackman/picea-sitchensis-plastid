# Plastid genome of Sitka spruce (*Picea sitchensis*)

![The complete plastid genome of Sitka spruce](KU215903.gbf.png)

# Methods

We annotated the coding (mRNA) and non-coding (rRNA and tRNA) genes of Sitka spruce (*Picea sitchensis*, KU215903) using MAKER 2.31.8 [@Campbell_2013]. The gene sequence of Norway spruce (*Picea abies*, NC_021456.1) [@Nystedt_2013] were used as evidence for MAKER. This automated annotation missed six difficult-to-annotate genes, which we annotated manually, based on visualization of the aligned evidence using IGV 2.3.80 [@Robinson_2011]. The gene *matK* is found inside the intron of *trnK-UUU*. The genes *rpl22* and *rps3* overlap, as do *psbC* and *psbD*. One copy of the gene *psbA* is truncated and annotated as a pseudogene. The gene *trnI-GAU* is not annotated by MAKER for some unknown reason. The gene *rps12* is trans-spliced [@Hildebrand_1988]. MAKER annotated 12 introns and missed three due to short initial exons of length 6, 8 and 9 bp in the genes *petB*, *petD* and *rpl16*, which we annotated manually as above. We identified introns that are group II self-splicing ribozymes using RNAweasel [@Lang_2007]. We annotated open reading frames (ORFs) using Prodigal 2.6.2 [@Hyatt_2010] and aligned these sequences to the NCBI nr protein database using BLASTX [@Altschul_1990] to identify homologous proteins. We aligned the complete genomes of white spruce (*Picea glauca*, KT634228.1) [@Jackman_2015] and Norway spruce to Sitka spruce using BWA-MEM 0.7.15 [@Li_2013] to investigate the conservation of chlorolplast gene synteny between these three closely-related species. We identified the two-copy inverted repeat typical of genomes using MUMmer 3.23 [@Kurtz_2004]. The Makefile script to perform these analyses, including the command line parameters used for each program, are available online at <https://github.com/sjackman/picea-sitchensis-plastid/blob/1.0.0/Makefile>.

# Results

Sitka spruce retains perfect gene synteny both white spruce and Norway spruce. All 114 genes are found in the same copy number and in the same order in Sitka spruce as is observed in white spruce and Norway spruce, including 74 coding genes, 4 ribosomal RNA (rRNA) and 36 transfer RNA (tRNA) genes.

The 15 introns seen in white spruce and Norway spruce are also found in Sitka spruce, with 9 found in coding genes and 6 in tRNA. Of these 15 introns, 12 are group II self-splicing ribozymes identified by RNAweasel, which are common in plastid genomes. One additional group II intron is found upstream of exon 2 of the trans-spliced gene *rps12*, consistent with [@Hildebrand_1988], though not included formally in this annotation due to the difficulty in identifying the 5' coordinate of the intron without additional transcript evidence. It is unclear whether the three introns not annotated as group II, found in the genes *petD*, *trnL-UAA* and *trnI-GAU*, is due to a lack of sensitivity in RNAweasel or a splicing mechanism other than a group II self-splicing ribozyme.

We identify 14 open reading frames (ORFs), 13 of which are larger than 150 bp, and 4 of which are larger than 300 bp. Of these 15 ORFs, four (including three ORFs larger than 300 bp) hit genes of other *Picea* and *Pinus* species, *ndhB*, *ndhK*, *rps4* and *ycf2*, but did not represent the full length of the homologous gene, indicating possible pseudogenes of Sitka spruce. Nine ORFs hit open reading frames and cDNA of *Picea* and *Pinus* species, predominantly Korean pine (*Pinus koraiensis*) and Japanese black pine (*Pinus thunbergii*). One ORF of 288 bp has no significant BLASTX hit to the NCBI nr protein database, but many hits to various confier genomes in the NR nucleotide database.

The two-copy inverted repeat of Sitka spruce is 440 bp, the same size as Norway spruce, and slightly smaller than the 445 bp inverted repeat of white spruce. The inverted repeat of Norway spruce has perfect sequence identity between the two copies. White spruce observed a single nucleotide mismatch between its two copies. Unusually, Sitka spruce has three nucleotide mismatches between its two copies.

# Tables

Table: Best BLASTX hits of the 14 open reading frames (ORFs) to the NCBI nr protein database. Four ORFs hit annotated genes. Nine ORFs hit open reading frames. One ORF has no significant hits. Excluding this ORF with no hits, every ORF has a significant hit to either a *Pinus* or *Picea* species, though it may not be the best hit.

| ORF   | Start  | End    | Strand | Length (bp) | Best hit            | Gene         | Species                 | Score | E value |
|-------|-------:|-------:|--------|-------------|---------------------|--------------|-------------------------|------:|--------:|
| orf1  |  4398  |   4523 | +      |         126 | ref\|YP_001152057.1 | ORF41a       | Pinus koraiensis        |  79.3 | 5e-19   |
| orf2  |  14197 |  14526 | +      |         330 | dbj\|BAA04352.1     | ORF42a       | Pinus thunbergii        |  66.2 | 1e-12   |
| orf3  |  20645 |  20848 | +      |         204 | ref\|NP_042408.1    | ORF119       | Pinus thunbergii        |  36.6 | 0.47    |
| orf4  |  28478 |  28681 | +      |         204 | ref\|NP_817199.1    | ORF67e       | Pinus koraiensis        |  85.1 | 2e-20   |
| orf5  |  30837 |  31148 | +      |         312 | gb\|AAP80884.1      | rps4         | Picea smithiana         | 154   | 6e-46   |
| orf6  |  35749 |  35904 | -      |         156 | ref\|YP_001152092.1 | ORF100       | Pinus koraiensis        |  77.8 | 1e-17   |
| orf7  |  53589 |  53807 | -      |         219 | gb\|ACN39997.1      | unknown      | Picea sitchensis        |  76.3 | 7e-17   |
| orf8  |  68781 |  69188 | +      |         408 | ref\|YP_009158607.1 | ndhK         | Encephalartos lehmannii | 131   | 3e-35   |
| orf9  |  85089 |  85292 | -      |         204 | ref\|NP_042472.1    | ORF77        | Pinus thunbergii        |  78.2 | 1e-17   |
| orf10 | 110595 | 111131 | -      |         537 | ref\|YP_009232295.1 | ycf2         | Picea jezoensis         | 335   | 1e-103  |
| orf11 | 112748 | 112930 | +      |         183 | gb\|KJB79837.1      | hypothetical | Gossypium raimondii     |  49.3 | 6e-06   |
| orf12 | 115029 | 115187 | +      |         159 | gb\|AKJ77598.1      | ndhB         | Dioscorea nipponica     |  85.9 | 4e-19   |
| orf13 | 115241 | 115528 | +      |         288 | No hits found       | NA           | NA                      | NA    | NA      |
| orf14 | 116390 | 116575 | +      |         186 | ref\|YP_001152258.1 | ORF40z       | Pinus koraiensis        |  32.7 | 3.7     |

