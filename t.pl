#!/usr/bin/perl

BEGIN { push @INC, 'lib' }

$Polloc::Polloc::Root::VERBOSITY = 4;

use Polloc::LocusIO;

my $lIO = Polloc::LocusIO->new(-file=>'t/loci.gff3', -format=>'Gff3');
my $fLoci = $lIO->next_locus;

