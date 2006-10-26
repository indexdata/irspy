# $Id: Makefile.PL,v 1.7 2006-10-26 13:39:13 sondberg Exp $

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ZOOM::IRSpy',
    VERSION_FROM      => 'lib/ZOOM/IRSpy.pm', # finds $VERSION
    PREREQ_PM         => {
	Net::Z3950::ZOOM => 1.13,
	XML::LibXML::XPathContext => 0.07, # For Web UI
        XML::LibXML => 1.59,
        XML::LibXSLT => 1.59,
	URI::Escape => 3.28, # For Web UI
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ZOOM/IRSpy.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),
);
