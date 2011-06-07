#!/usr/bin/perl

use strict;
use Bio::Polloc::LocusIO 1.5010;
use Bio::Polloc::Genome;
use Bio::Polloc::TypingI;

sub usage($);

# ------------------------------------------------- INPUT
my $gff_in =  shift @ARGV;
my $out    =  shift @ARGV;
my @names  = split /:/, shift @ARGV;

&usage('') unless $gff_in and $out and $#names > -1;
Bio::Polloc::Polloc::Root->DEBUGLOG(-file=>">$out.log");
$Bio::Polloc::Polloc::Root::VERBOSITY = 4;

# ------------------------------------------------- READ INPUT
my $genomes = [];
for my $G (0 .. $#names){
   push @$genomes, Bio::Polloc::Genome->new(-name=>$names[$G], -id=>$G) }
my $LocusIO = Bio::Polloc::LocusIO->new(-file=>$gff_in);
my $inloci = $LocusIO->read_loci(-genomes=>$genomes);

# ------------------------------------------------- TYPING
my $typing = Bio::Polloc::TypingI->new(-type=>'bandingPattern::amplification');
open IMG, ">", "$out.png" or die "I can not open '$out.png': $!\n";
binmode IMG;
print IMG $typing->graph(-locigroup=>$inloci)->png;
close IMG;

# ------------------------------------------------- SUBROUTINES
sub usage($) {
   my $m = shift;
   print "$m\n" if $m;
   print <<HELP

   polloc_draw.pl - Draws the expected gel for a given set of amplicons.

   Usage: $0 [Params]
   Params, in that order:
      gff (path):	GFF3 file containing the amplicons.
      			Example: /tmp/polloc-primers.out.amplif.1.gff
      out (path):	Path to the base of the output files.
      			Example: /tmp/polloc-gel.out
      names (str):	The names of the genomes separated by colons (:).
      			Alternatively, can be an empty string ('') to
			assign genome names from files.
      			Example: Xci3:Xeu8:XamC
      
HELP
   ;exit;
}

