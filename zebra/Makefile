
IRSPY_ARCHIVE=	records-2007-05-01.tar.gz

all: help


test:
	xmllint --noout --schema zeerex-2.0.xsd zeerex.xml

terse.properties: pqf.properties
	sed -n 's/#.*//; s/[ 	]*//; s/[ 	][ 	]*/ /g; /./p' $? > $@

newdb:
	tar xzf ${IRSPY_ARCHIVE}
	zebraidx-2.0 init
	zebraidx-2.0 update zeerex.xml
	zebraidx-2.0 update `basename ${IRSPY_ARCHIVE} .tar.gz`
	zebraidx-2.0 commit

clean:
	rm -f terse.properties

help:
	@echo "make [ test | newdb | clean ]"

