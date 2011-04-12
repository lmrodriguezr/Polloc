#!/usr/bin/perl

use strict;
use Polloc::RuleIO;
use Polloc::Genome;
use Bio::SeqIO;


# ------------------------------------------------- METHODS
# Output methods
sub csv_header();
sub csv_line($$);
# Advance methods
sub _advance_proto($$); # file, msg
sub advance_detection($$$$); # loci, genomes, Ngenomes, rule
sub advance_group($$$); # locus1, locus2, Nloci
sub advance_extension($$$); # group, Ngroups

# ------------------------------------------------- FILES
my $cnf = shift @ARGV;
our $out = shift @ARGV;
my $buildgroups = shift @ARGV;
my $extendgroups = shift @ARGV;
my @names = split ":", shift @ARGV;
my @inseqs = @ARGV;
my $csv = "$out.csv";
my $groupcsv = "$out.group.csv";

open LOG, ">", "$out.log" or die "I can not create the '$out.log' file: $!\n";
Polloc::Polloc::Root->DEBUGLOG(-fh=>\*LOG);
Polloc::Polloc::Root->VERBOSITY(4);

open CSV, ">", $csv or die "I can not create the CSV file '$csv': $!\n";

print CSV &csv_header();


# ------------------------------------------------- READ INPUT
# Configuration
my $ruleIO = Polloc::RuleIO->new(-format=>'Config', -file=>$cnf);
my $genomes = [];
# Sequences
for my $G (0 .. $#inseqs){ push @$genomes, Polloc::Genome->new(-file=>$inseqs[$G], -name=>$names[$G]) }
$ruleIO->genomes($genomes);

# ------------------------------------------------- DETECT VNTRs
my $all_loci = $ruleIO->execute(-advance=>\&advance_detection);
$all_loci->export_gff3(-file=>">$out.gff");
for my $gk (0 .. $#{$all_loci->structured_loci}){
   for my $locus (@{$all_loci->structured_loci->[$gk]}){
      print CSV &csv_line($locus, $ruleIO->genomes->[$gk]->name);
   }
}





sub advance_detection($$$$){
   my($loci, $gF, $gN, $rk) = @_;
   our $out;
   &_advance_proto("$out.nfeats", $loci);
   &_advance_proto("$out.nseqs", "$gF/$gN");
}

sub advance_group($$$){
   my($i,$j,$n) = @_;
   our $out;
   &_advance_proto("$out.ngroups", $i+1);
}

sub advance_extension($$$){

}

sub _advance_proto($$) {
   my($file, $msg) = @_;
   open ADV, ">", $file or die "I can not open the '$file' file: $!\n";
   print ADV $msg;
   close ADV;
}

sub csv_header() {
   return "Genome\tID\tSeq\tFrom\tTo\tUnit length\tCopy number\tMismatch percent\tScore\t".
		"Left 500bp\tRight 500bp (rc)\tRepeats\tConsensus/Notes\n";
}
sub csv_line($$) {
   my $f = shift;
   my $n = shift;
   $n||= '';
   my $left = $f->seq->subseq(max(1, $f->from-500), $f->from);
   my $right = Bio::Seq->new(-seq=>$f->seq->subseq($f->to, min($f->seq->length, $f->to+500)));
   $right = $right->revcom->seq;
   my $seq;
   $seq = $f->repeats if $f->can('repeats');
   $seq = $f->seq->subseq($f->from, $f->to) unless defined $seq;
   if(defined $seq and $f->strand eq '-'){
      my $seqI = Bio::Seq->new(-seq=>$seq);
      $seq = $seqI->revcom->seq;
   }
   my $notes = '';
   if($f->can('consensus')){
      $notes = $f->consensus;
   }else{
      $notes = $f->comments if $f->type eq 'extend';
      $notes =~ s/\s*Extended feature\s*/ /i; # <- not really clean, but works ;)
   }
   $notes =~ s/[\n\r]+/ /g;
   return sprintf(
   		"\%s\t\%s\t\%s\t\%d\t\%d\t%.2f\t%.2f\t%.0f%%\t%.2f\t\%s\t\%s\t\%s\t\%s\n",
   		$n, (defined $f->id ? $f->id : ''), $f->seq->display_id,
		$f->from, $f->to, ($f->can('period') ? $f->period : 0),
		($f->can('exponent') ? $f->exponent : 0),
		($f->can('error') ? $f->error : 0), $f->score,
   		$left, $right, $seq, $notes);
}

close CSV;
close LOG;

__END__

=pod

=head1 AUTHOR

Luis M. Rodriguez-R < lmrodriguezr at gmail dot com >

=head1 LICENSE

This script is distributed under the terms of
I<The Artistic License>.  See LICENSE.txt for details.

=head1 SYNOPSIS

    perl polloc_vntrs.pl

=cut
