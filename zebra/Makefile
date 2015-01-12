IRSPY_ARCHIVE=		records-2014-11-24
IRSPY_ARCHIVE_EXT=	.tar.gz
DUMP_DIR=		irspy-dump
ZEBRA_DIR=		db
ZEBRAIDX=		zebraidx-2.0
ZEBRAIDX_TEST=		zebraidx-2.0 -c zebra-test.cfg
IRSPY_DATABASE=		$${IRSpyDbName-"localhost:8018/IR-Explain---1"}
ZEBRA_LOGFILE=		irspy-zebra.log
ZEBRA_PID_FILE=		${ZEBRA_DIR}/lock/zebrasrv.pid


# debugging
ZEBRA_TEST_DIR=		db-test

DATE:=	$(shell date '+%Y-%m-%d')

all: help


test:
	xmllint --noout --schema zeerex-2.0.xsd zeerex.xml

terse.properties: pqf.properties
	sed -n 's/#.*//; s/[ 	]*//; s/[ 	][ 	]*/ /g; /./p' $? > $@

newdb:
	tar xzf ${DUMP_DIR}/${IRSPY_ARCHIVE}${IRSPY_ARCHIVE_EXT}
	mkdir -p ${ZEBRA_DIR}/lock ${ZEBRA_DIR}/register ${ZEBRA_DIR}/shadow ${ZEBRA_DIR}/tmp
	${ZEBRAIDX} init
	${ZEBRAIDX} update zeerex.xml
	${ZEBRAIDX} update ${IRSPY_ARCHIVE}
	${ZEBRAIDX} commit

newdb-test:
	tar xzf ${DUMP_DIR}/${IRSPY_ARCHIVE}${IRSPY_ARCHIVE_EXT}
	mkdir -p ${ZEBRA_TEST_DIR}/lock ${ZEBRA_TEST_DIR}/register ${ZEBRA_TEST_DIR}/shadow ${ZEBRA_TEST_DIR}/tmp
	${ZEBRAIDX_TEST} init
	${ZEBRAIDX_TEST} update zeerex-test.xml
	${ZEBRAIDX_TEST} update ${IRSPY_ARCHIVE}
	${ZEBRAIDX_TEST} commit

# note: the test database use localhost:8019/IR-Explain---1
dump:
	rm -rf records-${DATE}.old
	-test -e records-${DATE} && mv records-${DATE} records-${DATE}.old
	mkdir records-${DATE}
	cd records-${DATE} && ../../bin/irspy-dump.pl ${IRSPY_DATABASE}
	#cd records-${DATE}; for i in *.xml; do echo -n "$$i "; tidy -xml -i -m -w 140 $$i 2>&1 | sed 1q; done
	find records-${DATE} -name '*.xml' -print0 | xargs -n16 -0 -P4 xmllint -format >/dev/null
	tar cf - records-${DATE} | gzip > records-${DATE}.tar.gz

clean:
	rm -f terse.properties

check-running-zebrasrv:
	@if zoomsh  -e "open localhost:8018"  "quit" >/dev/null; then \
	   echo ""; \
	   echo "There is already a running zebrasrv on localhost:8018"; \
	   echo "You may need to run: killall zebrasrv-2.0"; \
	   false; \
	else \
	   true; \
	fi

start-zebra: check-running-zebrasrv
	zebrasrv-2.0 -f $$(pwd)/yazserver.xml > ${ZEBRA_LOGFILE} 2>&1 &

stop-zebra:
	kill `cat ${ZEBRA_PID_FILE}`
	sleep 0.5
	-kill -9 `cat ${ZEBRA_PID_FILE}`

check: newdb start-zebra dump stop-zebra distclean

distclean: clean
	rm -rf ${IRSPY_ARCHIVE} ${ZEBRA_DIR} ${ZEBRA_DIR} ${ZEBRA_TEST_DIR} ${ZEBRA_LOGFILE}

help:
	@echo "make [ newdb | newdb-test | dump | check ]"
	@echo "     [ start-zebra | stop-zebra ]"
	@echo "     [ clean | distclean ]"

