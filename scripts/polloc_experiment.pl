#!perl

use strict;
use Bio::Polloc::LocusIO;
use Bio::Polloc::Genome;
use Bio::Polloc::TypingIO;

my $cnf = shift @ARGV; # Configuration file
my $gff = shift @ARGV; # Input GFF containing the loci in a group
my $out = shift @ARGV; # Output PNG image
my $genomes = Bio::Polloc::Genome->build_set(-files=>\@ARGV);

my $locusIO = Bio::Polloc::LocusIO->new(-file=>$gff, -format=>'gff');
my $loci = $locusIO->read_loci(-genomes=>$genomes);
my $typing = Bio::Polloc::TypingIO->new(-file=>$cnf)->typing;
$typing->scan(-locigroup=>$loci);
my $graph = $typing->graph;
open PNG, '>', $out or die $0.': Unable to open '.$out.': '.$!;
binmode PNG;
print PNG $graph->png;
close PNG;
exit;


