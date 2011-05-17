use strict;
use warnings;

use Test::More tests => 24;

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
is($#{$loci->loci}, 81);

# 7
my $l1 = $loci->loci->[0];
isa_ok($l1, 'Polloc::LocusI');
isa_ok($l1, 'Polloc::Locus::repeat');

# 9
ok($l1->error, 'First locus have errors');
is($l1->error, 3);

# 11
is($l1->seq_name, 'Scaffold1');

# 12
my $O = Polloc::LocusIO->new(-file=>'>t/loci_out.gff3', -format=>'Gff3');
isa_ok($O, 'Polloc::LocusIO');
isa_ok($O, 'Polloc::LocusIO::gff3');

# 14
$O->write_locus($loci->loci->[0]);
$O->write_locus($loci->loci->[1]);
$O->write_locus($loci->loci->[2]);
$O->close;
my $I2 = Polloc::LocusIO->new(-file=>'t/loci_out.gff3', -format=>'Gff3');
my $loci2 = $I2->read_loci;
isa_ok($loci2, 'Polloc::LociGroup');
isa_ok($loci2->loci, 'ARRAY');
is($#{$loci2->loci}, 2);

# 17
my $l1_2 = $loci2->loci->[0];
is($l1->id, $l1_2->id);
is($l1->name, $l1_2->name);
is($l1->seq_name, $l1_2->seq_name);
is($l1->source, $l1_2->source);
is($l1->family, $l1_2->family);

# 22
my $ext = $loci->loci->[71];
isa_ok($ext, 'Polloc::Locus::extend');
isa_ok($ext->basefeature, 'Polloc::Locus::repeat');
is($ext->basefeature->id, 'VNTR:2.14');

