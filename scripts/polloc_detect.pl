#!perl

use strict;
use Bio::Polloc::Genome;
use Bio::Polloc::RuleIO;
use Bio::Polloc::LocusIO;

my $cnf = shift @ARGV; # Input configuration file
my $gff = shift @ARGV; # Output GFF file
my $genomes = Bio::Polloc::Genome->build_set(-files=>\@ARGV);
my $ruleIO = Bio::Polloc::RuleIO->new(-file=>$cnf, -genomes=>$genomes);
my $lociSet = $ruleIO->execute();

my $locusIO = Bio::Polloc::LocusIO->new(-file=>'>'.$gff, -format=>'GFF');
$locusIO->write_locus($_) for @{$lociSet->loci};
exit;


