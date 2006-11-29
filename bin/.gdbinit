# $Id: .gdbinit,v 1.2 2006-11-29 11:05:40 mike Exp $
set env YAZ_LOG=irspy,irspy_test,irspy_task
set args -I ../lib irspy.pl -t Quick localhost:3313/IR-Explain---1 bagel.indexdata.dk/gils
