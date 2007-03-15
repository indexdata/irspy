# $Id: .gdbinit,v 1.7 2007-03-15 11:34:51 mike Exp $
set env YAZ_LOG=irspy,irspy_test,irspy_task,zoom,zoom_details,irspy_event
set args -I../lib irspy.pl -t Quick -f 'net.host=*indexdata*' localhost:8018/IR-Explain---1
set args -I../lib irspy.pl -n 2 -t Quick localhost:8018/IR-Explain---1 z3950.loc.gov:7090/Voyager bagel.indexdata.dk/gils bagel.indexdata.dk:210/marc
