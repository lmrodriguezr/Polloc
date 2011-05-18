use strict;
use warnings;

use Test::More tests => 24;

# 1
use_ok('Polloc::GroupCriteria');
use_ok('Polloc::RuleIO');

# 5
my $T = Polloc::RuleIO->new(-file=>'t/vntrs.bme');
isa_ok($T, 'Polloc::RuleSet::cfg');

# 6
my $C = $T->groupcriteria->[0];
isa_ok($C, 'Polloc::GroupCriteria');

# 7
is($C->source, 'VNTR');
is($C->target, 'VNTR');

# 9
isa_ok($C->condition, 'Polloc::GroupCriteria::operator');
isa_ok($C->extension, 'HASH');
is($C->extension->{'-function'}, 'context');
is($C->extension->{'-upstream'}, 500);
is($C->extension->{'-downstream'}, 500);
is($C->extension->{'-detectstrand'}, 1);
is($C->extension->{'-alldetected'}, 0);
is($C->extension->{'-feature'}, 0);
is($C->extension->{'-lensd'}, 1.5);
is($C->extension->{'-maxlen'}, 500);
is($C->extension->{'-minlen'}, 0);
is($C->extension->{'-similarity'}, 0.56);
is($C->extension->{'-oneside'}, 0);
is($C->extension->{'-algorithm'}, 'blast');
is($C->extension->{'-score'}, 200);
is($C->extension->{'-consensusperc'}, 60);
is($C->extension->{'-e'}, 1e-5);
is($C->extension->{'-p'}, 'blastn');

