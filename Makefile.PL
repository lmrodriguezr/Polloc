use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME			=> 'Polloc',
   AUTHOR		=> q{Luis M. Rodriguez-R <lmrodriguezr@gmail.com>},
   VERSION_FROM		=> 'lib/Polloc/Polloc/Root.pm',
   ABSTRACT_FROM	=> 'lib/Polloc/Polloc/Root.pm',
   ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
   PL_FILES		=> {},
   PREREQ_PM		=> {
      'Error'		=> 0,
      'File::Path'	=> 0,
      'File::Spec'	=> 0,
      'File::Temp'	=> 0,
      'List::Util'	=> 0,
      'Symbol'		=> 0,
      'Bio::SeqIO'	=> 0,
   },
   CONFIGURE_REQUIRES	=> {
      'Test::More'	=> 0,
   },
   test			=> { TESTS => 't/*.t' },
   dist			=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean		=> { FILES => 'Polloc-*' },
);

