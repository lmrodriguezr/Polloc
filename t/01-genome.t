use strict;
use warnings;

use Test::More tests => 12;

# 1
use_ok('Polloc::Genome');

# 2
my $T = Polloc::Genome->new;
isa_ok($T, 'Polloc::Genome');
isa_ok($T, 'Polloc::Polloc::Root');

# 4
$T->file('t/multi.fasta');
ok($#{$T->get_sequences} == 3, 'get_sequences() return all the sequences');
isa_ok($T->get_sequences->[0], 'Bio::Seq');
isa_ok($T->get_sequences->[1], 'Bio::Seq');
isa_ok($T->get_sequences->[2], 'Bio::Seq');
isa_ok($T->get_sequences->[3], 'Bio::Seq');

# 9
$T = Polloc::Genome->new(-file=>'t/multi.fasta');
isa_ok($T, 'Polloc::Genome');
isa_ok($T->get_sequences->[0], 'Bio::Seq');

# 11
isa_ok($T->search_sequence('SEQ2'), 'Bio::Seq');
ok($T->search_sequence('SEQ2')->display_id eq 'SEQ2', 'search_sequences() returns the right sequence');


