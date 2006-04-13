# $Id: Makefile.PL,v 1.1 2006-04-13 14:53:17 mike Exp $

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Z3950::IRSpy',
    VERSION_FROM      => 'lib/Net/Z3950/IRSpy.pm', # finds $VERSION
    PREREQ_PM         => {
	Net::Z3950::ZOOM => 1.04,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Z3950/IRSpy.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),
);
