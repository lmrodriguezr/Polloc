use strict;
use warnings;

use Test::More tests => 26;

# 1
use_ok('Polloc::RuleIO');
use_ok('Polloc::Genome');

# 3
my $T = Polloc::RuleIO->new(-file=>'t/vntrs.bme');
isa_ok($T, 'Polloc::RuleIO');
isa_ok($T, 'Polloc::RuleSet::cfg');

# 5
is($T->prefix_id, 'VNTR');

# 6
is($T->init_id, 1);

# 7
is($T->format, 'cfg');

# 8
is($#{$T->get_rules}, 1);

# 9
isa_ok($T->get_rule(0), 'Polloc::RuleI');
isa_ok($T->get_rule(0), 'Polloc::Rule::tandemrepeat');
isa_ok($T->get_rule(1), 'Polloc::Rule::boolean');

# 12
my $i = 0;
while($T->next_rule){ $i++ }
is($i, 2);

# 13
isa_ok($T->groupcriteria, 'ARRAY');
is($#{$T->groupcriteria}, 0);
isa_ok($T->groupcriteria->[0], 'Polloc::GroupCriteria');
isa_ok($T->grouprules->[0], 'Polloc::GroupCriteria');

# 17
my $G = [Polloc::Genome->new(-file=>'t/multi.fasta'), Polloc::Genome->new(-file=>'t/repeats.fasta')];
$T->genomes($G);
isa_ok($T->genomes, 'ARRAY');
isa_ok($T->genomes->[0], 'Polloc::Genome');
isa_ok($T->genomes->[1], 'Polloc::Genome');

# 20
my $L = $T->execute;
isa_ok($L, 'Polloc::LociGroup');
isa_ok($L->loci, 'ARRAY');
is($#{$L->loci}, 1);
isa_ok($L->loci->[0], 'Polloc::Locus::repeat');
isa_ok($L->loci->[1], 'Polloc::Locus::repeat');
is($L->loci->[0]->from, 1672);
is($L->loci->[1]->from, 1642);

