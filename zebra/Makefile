# $Id: Makefile,v 1.4 2007-09-13 12:19:58 mike Exp $

test:
	xmllint --noout --schema zeerex-2.0.xsd zeerex.xml

terse.properties: pqf.properties
	sed -n 's/#.*//; s/[ 	]*//; s/[ 	][ 	]*/ /g; /./p' $? > $@

newdb:
	tar xzf records-2007-05-01.tar.gz
	zebraidx-2.0 init
	zebraidx-2.0 update zeerex.xml
	zebraidx-2.0 update records-2007-05-01
	zebraidx-2.0 commit

clean:
	rm -f terse.properties

