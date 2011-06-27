use strict;
use warnings;

use Bio::Polloc::Rule::crispr;
use Bio::Seq;

$Bio::Polloc::Polloc::Root::VERBOSITY = 4;

my $r = Bio::Polloc::RuleI->new(-type=>'crispr');
$r->value({});
my $loci = $r->execute(-seq=>Bio::SeqIO->new(-file=>'t/crispr_seq.fasta')->next_seq);


