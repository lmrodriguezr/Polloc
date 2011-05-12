use strict;
use warnings;

use Test::More tests => 11;

# 1
use_ok('Polloc::TypingIO');

# 2
my $T = Polloc::TypingIO->new(-file=>'t/vntrs.bme');
isa_ok($T, 'Polloc::TypingIO');
isa_ok($T, 'Polloc::TypingIO::cfg');
ok($T->format eq 'cfg', 'Format is cfg');

# 5
isa_ok($T->typing, 'Polloc::TypingI');
isa_ok($T->typing, 'Polloc::Typing::bandingPattern');
isa_ok($T->typing, 'Polloc::Typing::bandingPattern::amplification');

# 8	Polloc::Typing::bandingPattern
ok($T->typing->min_size==1, 'Parses minimum size');
ok($T->typing->max_size==2000, 'Parses maximum size');

# 10	Polloc::Typing::bandingPattern::amplification
ok($T->typing->primer_conservation==0.9, 'Parses primer conservation');
ok($T->typing->primer_size==20, 'Parses primer size');




