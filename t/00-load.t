#!perl -T

use Test::More tests => 1;

BEGIN {
   use_ok( 'Polloc::Polloc::Root' ) || print "Bail out!\n";
}

diag( "Testing Polloc $Polloc::Polloc::Root::VERSION, Perl $], $^X" );
