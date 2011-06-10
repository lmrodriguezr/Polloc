#!perl

use strict;
use Bio::Polloc::Genome;
use Bio::Polloc::RuleIO;
use Bio::Polloc::LocusIO;
use Bio::Polloc::Polloc::IO;

my $cnf = shift @ARGV; # Input configuration file
my $gff = shift @ARGV; # Input GFF file containing loci to be grouped
my $out = shift @ARGV; # Output file with the list loci ID per groups
my $genomes = Bio::Polloc::Genome->build_set(-files=>\@ARGV);

my $groupCriteria = Bio::Polloc::RuleIO->new(-file=>$cnf)->grouprules->[0];
my $locusIO = Bio::Polloc::LocusIO->new(-file=>$gff, -format=>'gff');
my $lociSet = $locusIO->read_loci(-genomes=>$genomes);
$groupCriteria->locigroup($lociSet);
my $groups = $groupCriteria->build_groups(-locigroup=>$lociSet);
my $table = Bio::Polloc::Polloc::IO->new(-file=>'>'.$out);
for my $group ( @$groups ){
   $table->_print(join("\t", map {$_->id} @{$group->loci})."\n");
}
$table->close;
exit;


