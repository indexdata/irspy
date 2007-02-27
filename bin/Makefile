# $Id: Makefile,v 1.2 2007-02-27 14:52:40 mike Exp $

LIBS = -lyaz -lxml2 -lssl	# Ubuntu Linux 6.06

setrlimit: setrlimit.c
	$(CC) -g -O0 -Wall -Wdeclaration-after-statement -ansi -pedantic -o $@ $?

test-zoom-c: test-zoom-c.c
	$(CC) -g -O0 -Wall -Wdeclaration-after-statement -o $@ $? $(LIBS)

clean:
	rm -f test-zoom-c

