# $Id: .gdbinit,v 1.1 2006-10-26 17:18:08 mike Exp $
set env YAZ_LOG=irspy,irspy_task
set args -I ../lib irspy.pl -t Quick localhost:3313/IR-Explain---1 bagel.indexdata.dk/gils
