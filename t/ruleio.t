use strict;
use warnings;

use Test::More tests => 15;

# 1
use_ok('Polloc::RuleIO');

# 2
my $T = Polloc::RuleIO->new(-file=>'t/vntrs.bme');
isa_ok($T, 'Polloc::RuleIO');
isa_ok($T, 'Polloc::RuleSet::cfg');

# 4
ok($T->prefix_id eq 'VNTR', 'prefix_id() returns the value of "glob prefix_id"');

# 5
ok($T->init_id==1, 'init_id() is initialized at 1');

# 6
ok($T->format eq 'cfg', 'format() returns the right format');

# 7
ok($#{$T->get_rules}==1, 'get_rules() returns the right number of rules');

# 8
isa_ok($T->get_rule(0), 'Polloc::RuleI');
isa_ok($T->get_rule(0), 'Polloc::Rule::tandemrepeat');
isa_ok($T->get_rule(1), 'Polloc::Rule::boolean');

# 11
my $i = 0;
while($T->next_rule){ $i++ }
ok($i==2, 'next_rule() iterates through all the rules');

# 12
isa_ok($T->groupcriteria, 'ARRAY');
ok($#{$T->groupcriteria} == 0, 'groupcriteria() returns only one instance');
isa_ok($T->groupcriteria->[0], 'Polloc::GroupCriteria');
isa_ok($T->grouprules->[0], 'Polloc::GroupCriteria');

# ToDo
# lib/Polloc/RuleIO:270 onwards

