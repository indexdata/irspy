# $Id: .gdbinit,v 1.5 2007-02-28 11:13:41 mike Exp $
set env YAZ_LOG=irspy,irspy_test,irspy_task,zoom,zoom_details,irspy_event
set args -I ../lib irspy.pl -t Main -a localhost:8018/IR-Explain---1
