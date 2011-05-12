use strict;
use warnings;

use Test::More tests => 2;

# 1
use_ok('Polloc::TypingIO');

# 2
my $T = Polloc::TypingIO->new(-file=>'t/vntrs.bme')->typing;
isa_ok($T, 'Polloc::Typing::bandingPattern::amplification');

