# $Id: Makefile,v 1.2 2006-06-20 11:02:58 mike Exp $

test:
	xmllint --noout --schema zeerex-2.0.xsd zeerex.xml

terse.properties: pqf.properties
	sed -n 's/#.*//; s/[ 	]*//; s/[ 	][ 	]*/ /g; /./p' $? > $@

clean:
	terse.properties

