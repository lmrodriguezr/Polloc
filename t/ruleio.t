use strict;
use warnings;

use Test::More tests => 22;

# 1
use_ok('Polloc::RuleIO');
use_ok('Polloc::Genome');

# 3
my $T = Polloc::RuleIO->new(-file=>'t/vntrs.bme');
isa_ok($T, 'Polloc::RuleIO');
isa_ok($T, 'Polloc::RuleSet::cfg');

# 5
ok($T->prefix_id eq 'VNTR', 'prefix_id() returns the value of "glob prefix_id"');

# 6
ok($T->init_id==1, 'init_id() is initialized at 1');

# 7
ok($T->format eq 'cfg', 'format() returns the right format');

# 8
ok($#{$T->get_rules}==1, 'get_rules() returns the right number of rules');

# 9
isa_ok($T->get_rule(0), 'Polloc::RuleI');
isa_ok($T->get_rule(0), 'Polloc::Rule::tandemrepeat');
isa_ok($T->get_rule(1), 'Polloc::Rule::boolean');

# 12
my $i = 0;
while($T->next_rule){ $i++ }
ok($i==2, 'next_rule() iterates through all the rules');

# 13
isa_ok($T->groupcriteria, 'ARRAY');
ok($#{$T->groupcriteria} == 0, 'groupcriteria() returns only one instance');
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
ok($#{$L->loci}==1, 'Checking if the number of loci ('.($#{$L->loci}+1).') is equal to two');


# ToDo
# lib/Polloc/RuleIO:270 onwards


