name=pg29plastid-scaffolds
ref=NC_021456

all: $(name).gbk.png

clean:
	rm -f $(name).gb $(name).gbk $(name).gff $(name).gbk.png

.PHONY: all clean
.DELETE_ON_ERROR:
.SECONDARY:

# asn,faa,ffn,fna,frn,gbk,gff,ptt,rnt,rpt,val
plastids/%:
	mkdir -p plastids
	curl -fsS http://ftp.cbi.pku.edu.cn/pub/database/Genome/Chloroplasts/$@ >$@

%.faa: plastids/%.gbk
	bin/gbk-to-faa <$< >$@

%.frn: plastids/%.frn
	sed 's/^>.*\[gene=/>/;s/\].*$$//' $< >$@

%.maker.output/stamp: maker_opts.ctl %.fa $(ref).frn $(ref).faa
	maker -fix_nucleotides
	touch $@

%.gff: %.maker.output/stamp
	gff3_merge -s -g -n -d $*.maker.output/$*_master_datastore_index.log \
		|sed '/rrn/s/mRNA/rRNA/;/trn/s/mRNA/tRNA/' >$@

%.gb: %.gff %.fa
	bin/gff_to_genbank.py $^ >$@

%.gbk: %-header.gbk %.gb
	(cat $< && sed -n '/^FEATURES/,$${s/Name=/gene=/;s/-gene//;p;}' $*.gb) >$@

%.gbk.png: %.gbk
	drawgenemap --format png --infile $< --outfile $<

%.gff.png: %.gff
	gt sketch $@ $<

# Report the annotated genes

%.gff.gene: %.gff
	ruby -we 'ARGF.each { |s| \
		puts $$1 if s =~ /\tgene\t.*Name=([^;]*)/ \
	}' $< \
	|sed 's/-gene//' >$@
