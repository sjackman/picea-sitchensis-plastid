name=pg29plastid-scaffolds
ref=NC_021456

all: $(name).png

clean:
	rm -f $(name).gb $(name).gbk $(name).gff $(name).png

.PHONY: all clean
.DELETE_ON_ERROR:
.SECONDARY:

# asn,faa,ffn,fna,frn,gbk,gff,ptt,rnt,rpt,val
plastids/%:
	mkdir -p plastids
	curl -fsS http://ftp.cbi.pku.edu.cn/pub/database/Genome/Chloroplasts/$@ >$@

%.faa: plastids/%.faa
	bin/gbk-to-faa <$< >$@

%.frn: plastids/%.frn
	sed 's/^>.*\[gene=/>/;s/\].*$$//' $< >$@

maker_opts.ctl: maker_opts.ctl.diff
	maker -CTL
	patch <maker_opts.ctl.diff

%.maker.output/%.db: maker_opts.ctl %.fa $(ref).frn $(ref).faa
	maker -fix_nucleotides

%.gff: %.maker.output/%.db
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
