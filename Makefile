# Annotate and visualize the Sitka spruce (Picea sitchensis) plastid genome
# Written by Shaun Jackman @sjackman

# Target genome, Picea sitchensis
name=KU215903

# Reference genome, Picea abies
ref=NC_021456

# Picea abies chloroplast complete genome
edirect_query='Picea abies[Organism] chloroplast[Title] complete genome[Title] RefSeq[Keyword]'

# Number of threads
t=64

all: $(name)-manual.tbl \
	$(name)-manual.tbl.gene \
	$(name)-manual.sqn \
	$(name)-manual.gbf.png

clean:
	rm -f $(name).orig.gff $(name).gff $(name).orig.gbk $(name).gbk $(name).gbk.png \
		$(name)-manual.tbl $(name)-manual.tbl.gene $(name)-manual.sqn

install-deps:
	brew install gnu-sed
	brew tap homebrew/science
	brew install bedtools edirect genometools maker ogdraw seqtk tbl2asn
	pip install --upgrade biopython bcbio-gff

.PHONY: all clean install-deps
.DELETE_ON_ERROR:
.SECONDARY:

# Fetch data from NCBI

$(name).fa $(ref).fa: %.fa:
	efetch -db nuccore -id $* -format fasta |seqtk seq \
		|sed 's/^>/>$* /' >$@

$(name).gb $(ref).gb: %.gb:
	efetch -db nuccore -id $* -format gb >$@

$(ref).tbl: %.tbl:
	efetch -db nuccore -id $* -format ft >$@

cds_aa.orig.fa cds_na.orig.fa: %.fa:
	esearch -db nuccore -query $(edirect_query) \
		|efetch -format fasta_$* >$@

$(ref).gene.orig.fa:
	efetch -db nuccore -id $(ref) -format gene_fasta |seqtk seq >$@

cds_aa.fa cds_na.fa $(ref).gene.fa: %.fa: %.orig.fa
	sed -E 's/^>(.*gene=([^]]*).*)$$/>\2|\1/' $< >$@

%.ncrna.fa: %.gene.fa
	paste -d'\t' - - <$< |egrep 'rrn|trn' |tr '\t' '\n' >$@

$(ref).gene.tsv:
	esearch -db gene -query NC_021456 |efetch -format tabular |cut -f1-17 >$@

%.product.tsv: %.gene.tsv
	mlr --tsvlite cut -f Symbol,description $< |mlr --tsvlite sort -f Symbol |uniq >$@

# asn,faa,ffn,fna,frn,gbk,gff,ptt,rnt,rpt,val
plastids/%:
	mkdir -p plastids
	curl -fsS http://ftp.cbi.pku.edu.cn/pub/database/Genome/Chloroplasts/$@ >$@

%.faa: plastids/%.gbk
	bin/gbk-to-faa <$< >$@

%.frn: plastids/%.frn
	sed 's/^>.*\[gene=/>/;s/\].*$$//' $< >$@

# BLAST

%.fa.blastx: %.fa
	blastx -remote -db nr -query $< -out $@

# MUMmer

%.delta: %.fa
	nucmer -p $* $< $<

%.delta.png: %.delta
	mummerplot -png -p $< $<

# seqtk

# Interlave paired-end FASTQ files and drop orphaned reads.
%.fq.gz: %_1.fq.gz %_2.fq.gz
	gunzip -c $^ | paste - - - - | sort | tr '\t' '\n' | seqtk dropse >$@

# BWA

# Index the target genome.
%.fa.bwt: %.fa
	bwa index $<

# Align sequences to the target genome.
$(name).%.sam: %.fa $(name).fa.bwt
	bwa mem -t$t -xintractg $(name).fa $< >$@

# Align paired-end reads to the target genome.
$(name).%.bam: %.fq.gz $(name).fa.bwt
	bwa mem -t$t -p $(name).fa $< | samtools view -h -F4 | samtools sort -@$t -o $@

# samtools

# Sort a SAM file and produce a sorted BAM file.
%.bam: %.sam
	samtools sort -@$t -o $@ $<

# Index a BAM file.
%.bam.bai: %.bam
	samtools index $<

# Select properly paired reads.
%.proper.bam: %.bam
	samtools view -Obam -f2 -o $@ $<

# Calculate depth of coverage.
%.depth.tsv: %.bam
	(printf "Seq\tPos\tDepth\n"; samtools depth -a $<) >$@

# bcftools

# Call variants of reads aligned to a reference.
%.vcf.gz: %.bam $(name).fa
	samtools mpileup -u -f $(name).fa $< | bcftools call -c -v --ploidy=1 -Oz >$@

# Filter variants to select locations that differ from the reference.
%.filter.vcf.gz: %.vcf.gz
	bcftools filter -Oz -i '(DP4[0]+DP4[1]) < (DP4[2]+DP4[3]) && DP4[2] > 0 && DP4[3] > 0' $< >$@

# Index a VCF file.
%.vcf.gz.csi: %.vcf.gz
	bcftools index $<

# Prodigal

# Annotate genes using Prodigal
%.prodigal.gff: %.fa
	prodigal -c -m -g 11 -p meta -f gff -a $*.prodigal.faa -d $*.prodigal.ffn -s $*.prodigal.tsv -i $< -o $@

# Select Prodigal annotations not overlapping manual annotations using bedtools
%.prodigal.orf.orig.gff: %.prodigal.gff %.maker.manual.gff
	bedtools intersect -v -header -a $< -b $*.maker.manual.gff |gt gff3 -sort - >$@

# Convert the Prodigal GFF file to GFF 3.
%.prodigal.orf.gff: %.prodigal.orf.orig.gff
	awk -F'\t' -vOFS='\t' '/^##/ { print } !/^#/ { ++i; \
			$$3 = "gene"; $$8 = "."; $$9 = "ID=gene" i ";Name=orf" i; print; \
			$$3 = "mRNA"; $$9 = "ID=mRNA" i ";Parent=gene" i ";Name=orf" i; print; \
			$$3 = "exon"; $$9 = "Parent=mRNA" i; print; \
			$$3 = "CDS"; $$8 = "0"; $$9 = "Parent=mRNA" i; print; \
			}' $< \
		| gt gff3 -sort - >$@

# Extract DNA sequences of ORF features from a FASTA file
%.prodigal.orf.gff.fa: %.prodigal.orf.gff %.fa
	gt extractfeat -type CDS -coords -matchdescstart -retainids -seqid -seqfile $*.fa $< >$@

# ARAGORN

# Annotate tRNA using ARAGORN
%.aragorn.tsv: %.fa
	aragorn -gcbact -i -c -w -o $@ $<

# MAKER

# Annotate genes using MAKER
$(name).maker.output/stamp: %.maker.output/stamp: maker_opts.ctl %.fa $(ref).frn cds_aa.fa
	maker -fix_nucleotides
	touch $@

%.orig.gff: %.maker.output/stamp
	gff3_merge -s -g -n -d $*.maker.output/$*_master_datastore_index.log >$@

%.gff: %.orig.gff
	gsed '/rrn/s/mRNA/rRNA/; \
		/trn/s/mRNA/tRNA/' $< \
	|gt gff3 -addintrons - >$@

# Extract DNA sequences of GFF CDS features from a FASTA file
%.gff.CDS.fa: %.gff %.fa
	gt extractfeat -type CDS -join -coords -matchdescstart -retainids -seqid -seqfile $*.fa $< >$@

# Extract aa sequences of GFF CDS features from a FASTA file
# Hack: The gene chlL uses an alternative GUG start codon.
%.gff.aa.fa: %.gff %.fa
	gt extractfeat -type CDS -join -translate -coords -matchdescstart -retainids -seqid -seqfile $*.fa $< | \
		sed 's/^VKIAVYGKGG/MKIAVYGKGG/' >$@

# Extract sequences of GFF intron features
%.gff.intron.fa: %.gff %.fa
	gt extractfeat -type intron -coords -matchdescstart -retainids -seqid -seqfile $*.fa $< >$@

# Convert GFF to GenBank format
%.orig.gbk: %.gff %.fa
	bin/gff_to_genbank.py $^
	mv $*.gb $@

# Extract the header from a GenBank record.
%-header.gbk: %.gb
	sed '/Assembly-Data-END/q' $< >$@

%.gbk: %-header.gbk %.orig.gbk
	(cat $< && sed -En '/^FEATURES/,$${ \
		s/Name=/gene=/; \
		s/gene="([^|"]*)\|[^"]*"/gene="\1"/; \
		p;}' $*.orig.gbk) >$@

# Merge MAKER and manual annotations using bedtools.
%.maker.manual.gff: %.gff %.manual.gff
	bedtools intersect -v -header -a $< -b $*.manual.gff \
		|gt gff3 -sort $*.manual.gff - >$@

# Merge MAKER, manual and Prodigal ORF annotations using bedtools.
%-manual.gff: %.gff %.manual.gff %.prodigal.orf.gff
	bedtools intersect -v -header -a $< -b $*.manual.gff \
		|gt gff3 -sort - $*.manual.gff $*.prodigal.orf.gff >$@

# Organellar Genome Draw

%.gbf.png: %.gbf %.ircoord
	drawgenemap --format png --infile $< --outfile $< \
		--gc --ircoord `<$*.ircoord` \
		--density 126
	mogrify -units PixelsPerInch -density 300 $@

%.gbk.png: %.gbk %.ircoord
	drawgenemap --format png --infile $< --outfile $< \
		--gc --ircoord `<$*.ircoord` \
		--density 126
	mogrify -units PixelsPerInch -density 300 $@

# GenomeTools sketch

%.gff.png: %.gff
	gt sketch $@ $<

# Report the annotated genes

%.gff.gene: %.gff
	sort -k1,1 -k4,4n -k5,5n $< \
	|gsed -nE '/\tgene\t/!d; \
		s/^.*Name=([^|;]*).*$$/\1/; \
		s/-gene//; \
		p' >$@

# Generate a tbl file for tbl2asn and GenBank submission

%-gene-product.tsv: %.gff
	(printf "gene\tproduct\n" \
		&& sed -En 's/%2C/,/g;s~%2F~/~g; \
			s/^.*gene=([^;]*);.*product=([^;]*).*$$/\1	\2/p' $< |sort -u) >$@

# Convert GFF to TBL
%.tbl: %.gff %-product.tsv %.gff.aa.fa
	bin/gff3-to-tbl --centre=BCGSC --locustag=Q903CP $^ >$@

# Extract the names of genes from a TBL file
%.tbl.gene: %.tbl
	awk '$$1 == "gene" {print $$2}' $< >$@

# Add structured comments to the FASTA file
%.fsa: %.fa
	(echo '>$(name) [organism=Picea sitchensis] [location=chloroplast] [completeness=complete] [topology=circular] [gcode=11]'; \
		tail -n +2 $<) >$@

# tbl2asn

# Convert TBL to GBF and SQN
%.gbf %.sqn: %.fsa %.sbt %.tbl %.cmt
	tbl2asn -i $< -t $*.sbt -w $*.cmt -Z $*.discrep -Vbv

# Symlinks

$(name)-manual.fa: $(name).fa
	ln -s $< $@

$(name)-manual.ircoord: $(name).ircoord
	ln -s $< $@

$(name)-manual.cmt: $(name).cmt
	ln -s $< $@

$(name)-manual.sbt: $(name).sbt
	ln -s $< $@

$(name)-manual-header.gbk: $(name)-header.gbk
	ln -s $< $@

$(name)-manual-product.tsv: $(name)-product.tsv
	ln -s $< $@

# Render Markdown to HTML using Pandoc
%.html: %.md %.bib
	pandoc -s -F pandoc-citeproc --bibliography=$*.bib -o $@ $<
