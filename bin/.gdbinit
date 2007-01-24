# $Id: .gdbinit,v 1.3 2007-01-24 09:28:02 mike Exp $
set env YAZ_LOG=irspy,irspy_test,irspy_task
set args -I ../lib irspy.pl -t Quick localhost:8018/IR-Explain---1 bagel.indexdata.dk/gils
