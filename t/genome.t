use strict;
use warnings;

use Test::More tests => 10;

# 1
use_ok('Polloc::Genome');

# 2
my $G = Polloc::Genome->new;
isa_ok($G, 'Polloc::Genome');
isa_ok($G, 'Polloc::Polloc::Root');

# 4
$G->file('t/multi.fasta');
ok($#{$G->get_sequences} == 3, 'get_sequences() return all the sequences');
isa_ok($G->get_sequences->[0], 'Bio::Seq');
isa_ok($G->get_sequences->[1], 'Bio::Seq');
isa_ok($G->get_sequences->[2], 'Bio::Seq');
isa_ok($G->get_sequences->[3], 'Bio::Seq');

# 9
isa_ok($G->search_sequence('SEQ2'), 'Bio::Seq');
ok($G->search_sequence('SEQ2')->display_id eq 'SEQ2', 'search_sequences() returns the right sequence');


