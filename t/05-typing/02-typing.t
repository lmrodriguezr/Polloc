use strict;
use warnings;

use Test::More tests => 13;

# 1
use_ok('Bio::Polloc::TypingIO');

# 2
my $T = Bio::Polloc::TypingIO->new(-file=>'t/vntrs.bme')->typing;
isa_ok($T, 'Bio::Polloc::Typing::bandingPattern::amplification');

# 3
is($T->type, 'bandingPattern::amplification');

# 4
# This should be replaced by Bio::Polloc::LocusIO once created (see Issue #25):
use_ok('Bio::Polloc::Genome');
use_ok('Bio::Polloc::RuleIO');
my $R = Bio::Polloc::RuleIO->new(-file=>'t/vntrs.bme');
my $G = [Bio::Polloc::Genome->new(-file=>'t/repeats.fasta')];
$R->genomes($G);
my $L = $R->execute;

# 6
isa_ok($T->locigroup($L), 'Bio::Polloc::LociGroup');

# 7
isa_ok($T->scan, 'Bio::Polloc::LociGroup');

# 8
my $NM = $T->matrix(-names=>1);
isa_ok($NM, 'HASH');
isa_ok($NM->{'repeats'}, 'ARRAY');
is($#{$NM->{'repeats'}}, 0);
is($NM->{'repeats'}->[0], 105);

# 12
my $BM = $T->binary(-names=>1);
isa_ok($BM, 'HASH');
is($BM->{'repeats'}, 1);

