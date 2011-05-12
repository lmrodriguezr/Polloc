use strict;
use warnings;

use Test::More tests => 13;

# 1
use_ok('Polloc::TypingIO');

# 2
my $T = Polloc::TypingIO->new(-file=>'t/vntrs.bme')->typing;
isa_ok($T, 'Polloc::Typing::bandingPattern::amplification');

# 3
ok($T->type eq 'bandingPattern::amplification', 'Typing method is banding pattern by amplification ('.$T->type.')');

# 4
# This should be replaced by Polloc::LocusIO once created (see Issue #25):
use_ok('Polloc::Genome');
use_ok('Polloc::RuleIO');
my $R = Polloc::RuleIO->new(-file=>'t/vntrs.bme');
my $G = [Polloc::Genome->new(-file=>'t/repeats.fasta')];
$R->genomes($G);
my $L = $R->execute;

# 6
isa_ok($T->locigroup($L), 'Polloc::LociGroup');

# 7
isa_ok($T->scan, 'Polloc::LociGroup');

# 8
my $NM = $T->matrix(-names=>1);
isa_ok($NM, 'HASH');
isa_ok($NM->{'repeats'}, 'ARRAY');
ok($#{$NM->{'repeats'}} == 0, 'The first vector contains one element ('.($#{$NM->{'repeats'}}+1).')');
ok($NM->{'repeats'}->[0] == 105, 'The first value of the first vector in matrix() is 105 ('.$NM->{'repeats'}->[0].')');

# 12
my $BM = $T->binary(-names=>1);
isa_ok($BM, 'HASH');
ok($BM->{'repeats'} == 1, 'The first value in binary() is 1 ('.$BM->{'repeats'}.')');

