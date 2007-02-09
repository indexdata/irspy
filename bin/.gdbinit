# $Id: .gdbinit,v 1.4 2007-02-09 10:42:28 mike Exp $
set env YAZ_LOG=irspy,irspy_test,irspy_task,zoom,zoom_details,irspy_event
set args -I ../lib irspy.pl -t Quick localhost:8018/IR-Explain---1 z3950.loc.gov:7090/Voyager
