/* $Id: setrlimit.c,v 1.2 2007-02-27 14:54:52 mike Exp $ */

/*
 * A simple wrapper program for the setrlimit(2) system call, which
 * can be used to run a subprocess under a different regime -- much
 * like "nice", "time", etc.  This is needed for IRSpy, since when it
 * runs against many servers simultaneously, it runs out of file
 * descriptors -- a condition, by the way, which Perl sometimes
 * reports very misleadingly (e.g. "Can't locate Scalar/Util.pm in
 * @INC" when the open() failure was due to EMFILE rather than
 * ENOENT).
 *
 * Since the file-descriptor limit can only be raised (from the
 * default of 1024 in Ubuntu) by root, this program often needs to run
 * as root -- hence the option for resetting the UID after performing
 * the limit-change.
 */

#include <getopt.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <unistd.h>
#include <pwd.h>

int main(int argc, char **argv) {
    int verbose = 0;
    int n = 0;
    char *user = 0;
    int c;

    while ((c = getopt(argc, argv, "vn:u:")) != -1) {
	switch (c) {
	case 'v': verbose++; break;
	case 'n': n = atoi(optarg); break;
	case 'u': user = optarg; break;
	default:
	USAGE:
	    fprintf(stderr, "Usage: %s [options] <command>\n\
	-v		Verbose mode\n\
	-n <number>	Set maximum open files to <number>\n\
	-u <user>	Run subcommand as <user>\n",
		    argv[0]);
	    exit(1);
	}
    }

    if (optind == argc)
	goto USAGE;

    if (n != 0) {
	struct rlimit old, new;
	getrlimit(RLIMIT_NOFILE, &old);
	new = old;
	new.rlim_cur = n;
	if (n > new.rlim_max)
	    new.rlim_max = n;
	if (verbose) {
	    if (new.rlim_cur != old.rlim_cur)
		printf("%s: changing soft NOFILE from %ld to %ld\n",
		       argv[0], (long) old.rlim_cur, (long) new.rlim_cur);
	    if (new.rlim_max != old.rlim_max)
		printf("%s: changing soft NOFILE from %ld to %ld\n",
		       argv[0], (long) old.rlim_max, (long) new.rlim_max);
	}
	if (setrlimit(RLIMIT_NOFILE, &new) < 0) {
	    fprintf(stderr, "%s: setrlimit(n=%d): %s\n",
		    argv[0], n, strerror(errno));
	    exit(2);
	}
    }

    if (user != 0) {
	struct passwd *pwd;
	if ((pwd = getpwnam(user)) == 0) {
	    fprintf(stderr, "%s: user '%s' not known\n", argv[0], user);
	    exit(3);
	}

	if (setuid(pwd->pw_uid) < 0) {
	    fprintf(stderr, "%s: setuid('%s'=%ld): %s\n",
		    argv[0], user, (long) pwd->pw_uid, strerror(errno));
	    exit(4);
	}
    }

    if (verbose)
	printf("%s: n=%d, user='%s', optind=%d, new argc=%d, argv[0]='%s'\n",
	       argv[0], n, user, optind, argc-optind, argv[optind]);

    execvp(argv[optind], argv+optind);
    fprintf(stderr, "%s: execvp('%s'): %s\n",
	    argv[0], argv[optind], strerror(errno));
    exit(5);
}
