package Bio::Polloc::Polloc::Version;

use strict;
our $VERSION = '1.0502';

sub import {
   no strict 'refs';
   my $c = -1;
   while(defined caller(++$c)){
      my $v = caller($c) . "::VERSION";
      ${$v} = $VERSION if $v =~ /^Bio::Polloc::/ and not defined ${$v};
   }
}


1;
