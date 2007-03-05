# $Id: .gdbinit,v 1.6 2007-03-05 19:39:30 mike Exp $
set env YAZ_LOG=irspy,irspy_test,irspy_task,zoom,zoom_details,irspy_event
set args -I../lib irspy.pl -t Quick -f 'net.host=*indexdata*' localhost:8018/IR-Explain---1
