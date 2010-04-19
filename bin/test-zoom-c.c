/*
 * Run the same way as "test-pod.pl".  This is supposed to be an
 * exactly equivalent program but written using the ZOOM-C imperative
 * API for asynchronous events directly rather than through the
 * intermediary of Net::Z3950::ZOOM, ZOOM::Pod and ZOOM-Perl.
 */

#include <assert.h>
#include <stdio.h>
#include <yaz/zoom.h>
#include <yaz/log.h>


struct conn_and_state {
    ZOOM_connection conn;
    ZOOM_resultset rs;
    int next_to_show, next_to_fetch;
};


static void completed_search(struct conn_and_state *csp);
static void got_record(struct conn_and_state *csp);
static void request_records(struct conn_and_state *csp, int count);


int main (int argc, char *argv[]) {
    ZOOM_options options;
    struct conn_and_state cs[100];
    ZOOM_connection zconn[100];
    int i, n;

    if (argc == 1) {
	fprintf(stderr, "Usage: %s <target1> [<target2> ...]\n", argv[0]);
	return 1;
    }

    yaz_log_mask_str("appl");
    options = ZOOM_options_create();
    ZOOM_options_set_int(options, "async", 1);
    ZOOM_options_set(options, "elementSetName", "b");

    n = argc-1;
    for (i = 0; i < n; i++) {
	char *target = argv[i+1];
	cs[i].conn = zconn[i] = ZOOM_connection_create(options);
	ZOOM_connection_connect(cs[i].conn, target, 0);
	cs[i].rs = ZOOM_connection_search_pqf(cs[i].conn, "the");
	cs[i].next_to_show = 0;
	cs[i].next_to_fetch = 0;
    }

    while ((i = ZOOM_event(n, zconn)) != 0) {
	struct conn_and_state *csp = &cs[i-1];
	int ev = ZOOM_connection_last_event(csp->conn);
	int errcode;
	const char *errmsg;
	const char *addinfo;

	yaz_log(yaz_log_module_level("pod"),
		"connection %d: event %d", i-1, ev);

	errcode = ZOOM_connection_error(csp->conn, &errmsg, &addinfo);
	if (errcode != 0) {
	    fprintf(stderr, "error %d (%s) [%s]\n", errcode, errmsg, addinfo);
	    return 2;
	}

	if (ev == ZOOM_EVENT_RECV_SEARCH) {
	    completed_search(csp);
	} else if (ev == ZOOM_EVENT_RECV_RECORD) {
	    got_record(csp);
	}
    }

    return 0;
}


static void completed_search(struct conn_and_state *csp) {
    const char *host = ZOOM_connection_option_get(csp->conn, "host");

    printf("%s: found %d records\n", host, ZOOM_resultset_size(csp->rs));
    request_records(csp, 2);
}


static void got_record(struct conn_and_state *csp) {
    const char *host = ZOOM_connection_option_get(csp->conn, "host");
    int i, len;
    ZOOM_record rec;

    assert(csp->next_to_show < csp->next_to_fetch);
    i = csp->next_to_show++;
    rec = ZOOM_resultset_record(csp->rs, i);
    printf("%s: record %d is %s\n", host, i,
	   rec == 0 ? "undefined" : ZOOM_record_get(rec, "render", &len));
    if (i == csp->next_to_fetch-1)
	request_records(csp, 3);
}


static void request_records(struct conn_and_state *csp, int count) {
    const char *host = ZOOM_connection_option_get(csp->conn, "host");
    int i = csp->next_to_fetch;

    yaz_log(yaz_log_module_level("appl"),
	    "requesting %d records from %d for %s", count, i, host);

    ZOOM_resultset_records(csp->rs, (ZOOM_record*) 0, i, count);
    csp->next_to_fetch += count;
}
