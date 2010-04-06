
IRSPY_ARCHIVE=		records-2010-04-06
IRSPY_ARCHIVE_EXT=	.tar.gz
DUMP_DIR=		irspy-dump
ZEBRA_DIR=		db

DATE:=	$(shell date '+%Y-%m-%d')

all: help


test:
	xmllint --noout --schema zeerex-2.0.xsd zeerex.xml

terse.properties: pqf.properties
	sed -n 's/#.*//; s/[ 	]*//; s/[ 	][ 	]*/ /g; /./p' $? > $@

newdb:
	tar xzf ${DUMP_DIR}/${IRSPY_ARCHIVE}${IRSPY_ARCHIVE_EXT}
	mkdir -p ${ZEBRA_DIR}/lock
	zebraidx-2.0 init
	zebraidx-2.0 update zeerex.xml
	zebraidx-2.0 update ${IRSPY_ARCHIVE}
	zebraidx-2.0 commit

dump:
	rm -rf records-${DATE}.old
	-test -e records-${DATE} && mv records-${DATE} records-${DATE}.old
	mkdir records-${DATE}
	cd records-${DATE} && ../../bin/irspy-dump.pl irspy.indexdata.com:8018/IR-Explain---1
	tar cfz records-${DATE} records-${DATE}
	
clean:
	rm -f terse.properties

distclean: clean
	rm -rf ${IRSPY_ARCHIVE} ${ZEBRA_DIR}

help:
	@echo "make [ dump | test | newdb | clean | distclean ]"

