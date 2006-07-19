# $Id: Makefile,v 1.1 2006-07-19 16:29:14 mike Exp $

LIBS = -lyaz -lxml2 -lssl	# Ubuntu Linux 6.06

test-zoom-c: test-zoom-c.c
	$(CC) -g -O0 -Wall -Wdeclaration-after-statement -o $@ $? $(LIBS)

clean:
	rm -f test-zoom-c

