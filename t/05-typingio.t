use strict;
use warnings;

use Test::More tests => 11;

# 1
use_ok('Polloc::TypingIO');

# 2
my $T = Polloc::TypingIO->new(-file=>'t/vntrs.bme');
isa_ok($T, 'Polloc::TypingIO');
isa_ok($T, 'Polloc::TypingIO::cfg');
is($T->format, 'cfg');

# 5
isa_ok($T->typing, 'Polloc::TypingI');
isa_ok($T->typing, 'Polloc::Typing::bandingPattern');
isa_ok($T->typing, 'Polloc::Typing::bandingPattern::amplification');

# 8	Polloc::Typing::bandingPattern
is($T->typing->min_size, 1);
is($T->typing->max_size, 2000);

# 10	Polloc::Typing::bandingPattern::amplification
is($T->typing->primer_conservation, 0.9);
is($T->typing->primer_size, 20);

