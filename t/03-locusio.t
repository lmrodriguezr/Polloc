use strict;
use warnings;

use Test::More tests => 13;

# 1
use_ok('Polloc::LocusIO');
use_ok('Polloc::Genome');

# 3
my $I = Polloc::LocusIO->new(-file=>'t/loci.gff3', -format=>'Gff3');
isa_ok($I, 'Polloc::LocusIO');
isa_ok($I, 'Polloc::LocusIO::gff3');

#5
my $loci = $I->read_loci;
isa_ok($loci, 'Polloc::LociGroup');
ok($#{$loci->loci} == 81, 'Retrieves 83 loci ('.($#{$loci->loci}+1).')');

# 7
my $l1 = $loci->loci->[0];
isa_ok($l1, 'Polloc::LocusI');
isa_ok($l1, 'Polloc::Locus::repeat');

# 9
ok($l1->error, 'First locus have errors');
ok($l1->error == 3, 'First locus have three mismatches ('.$l1->error.')');

# 11
ok($l1->seq_name eq 'Scaffold1', 'The first locus is at Scaffold1 ('.$l1->seq_name.')');

# 12
my $O = Polloc::LocusIO->new(-file=>'>t/loci_out.gff3', -format=>'Gff3');
isa_ok($O, 'Polloc::LocusIO');
isa_ok($O, 'Polloc::LocusIO::gff3');

# 14
$O->write_locus($loci->loci->[0]);

