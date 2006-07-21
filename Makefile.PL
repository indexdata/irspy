# $Id: Makefile.PL,v 1.3 2006-07-21 16:48:32 mike Exp $

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ZOOM::IRSpy',
    VERSION_FROM      => 'lib/ZOOM/IRSpy.pm', # finds $VERSION
    PREREQ_PM         => {
	Net::Z3950::ZOOM => 1.04,
	XML::LibXML::XPathContext => 0.07,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ZOOM/IRSpy.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),
);
