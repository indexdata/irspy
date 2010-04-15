#!/bin/sh
#
# wrapper for irspy.pl
#
# run irspy with a smaller set of records in a loop to avoid out-of-memory
#

home=/usr/local/src/git
cd $home/irspy/bin || exit 2
logdir=../tmp

for i in 0 1 2 3 4 5 6
do
   logfile=$logdir/irspy-mod-$i.log.`date '%w'`
   YAZ_LOG=irspy,irspy_test nice -10 time perl -I../lib irspy.pl -n 50 -d -M 3500 -a -t Main -m 7,$i localhost:8018/IR-Explain---1 > $logfile 2>&1
   gzip -f $logfile
done

