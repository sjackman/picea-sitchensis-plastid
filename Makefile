# Annotate and visualize the white spruce plastid genome
# Written by Shaun Jackman @sjackman

name=pg29-plastid
ref=NC_021456

# Picea abies chloroplast complete genome
edirect_query='Picea abies[Organism] chloroplast[Title] complete genome[Title] RefSeq[Keyword]'

all: $(name).gff.gene $(name).gbk.png $(name)-manual.gbk.png \
	$(name)-manual.tbl $(name)-manual.tbl.gene $(name)-manual.sqn

clean:
	rm -f $(name).orig.gff $(name).gff $(name).orig.gbk $(name).gbk $(name).gbk.png \
		$(name)-manual.tbl $(name)-manual.tbl.gene $(name)-manual.sqn

install-deps:
	brew install edirect genometools maker ogdraw tbl2asn
	pip install --upgrade biopython bcbio-gff

.PHONY: all clean install-deps
.DELETE_ON_ERROR:
.SECONDARY:

# Fetch data from NCBI

cds_aa.orig.fa cds_na.orig.fa: %.fa:
	esearch -db nuccore -query $(edirect_query) \
		|efetch -format fasta_$* >$@

cds_aa.fa cds_na.fa: %.fa: %.orig.fa
	sed -E 's/^>(.*gene=([^]]*).*)$$/>\2|\1/' $< >$@

# asn,faa,ffn,fna,frn,gbk,gff,ptt,rnt,rpt,val
plastids/%:
	mkdir -p plastids
	curl -fsS http://ftp.cbi.pku.edu.cn/pub/database/Genome/Chloroplasts/$@ >$@

%.faa: plastids/%.gbk
	bin/gbk-to-faa <$< >$@

%.frn: plastids/%.frn
	sed 's/^>.*\[gene=/>/;s/\].*$$//' $< >$@

# ARAGORN

# Annotate tRNA using ARAGORN
%.aragorn.tsv: %.fa
	aragorn -gcbact -i -c -w -o $@ $<

# MAKER

# Annotate genes using MAKER
pg29-plastid.maker.output/stamp: %.maker.output/stamp: maker_opts.ctl %.fa $(ref).frn cds_aa.fa
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

%.gbk: %-header.gbk %.orig.gbk
	(cat $< && sed -En '/^FEATURES/,$${ \
		s/Name=/gene=/; \
		s/gene="([^|"]*)\|[^"]*"/gene="\1"/; \
		p;}' $*.orig.gbk) >$@

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
	bin/gff3-to-tbl --centre=BCGSC --locustag=OU3CP $^ >$@

# Extract the names of genes from a TBL file
%.tbl.gene: %.tbl
	awk '$$1 == "gene" {print $$2}' $< >$@

# Add structured comments to the FASTA file
%.fsa: %.fa
	(echo '>1 [organism=Picea glauca] [location=chloroplast] [completeness=complete] [topology=circular] [gcode=11]'; \
		tail -n +2 $<) >$@

# tbl2asn

# Convert TBL to GBF and SQN
%.gbf %.sqn: %.fsa %.sbt %.tbl %.cmt
	tbl2asn -i $< -t $*.sbt -w $*.cmt -Z $*.discrep -Vbv
	gsed -i 's/DEFINITION  Picea glauca/& chloroplast complete genome/' $*.gbf

# Symlinks

pg29-plastid-manual.fa: pg29-plastid.fa
	ln -s $< $@

pg29-plastid-manual.ircoord: pg29-plastid.ircoord
	ln -s $< $@
