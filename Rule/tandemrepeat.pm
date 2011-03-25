=head1 NAME

PLA::Rule::tandemrepeat - A rule of type tandemrepeat

=head1 DESCRIPTION

This rule is similar to PLA::Rule::repeat, but employes TRF (Benson 1999, NAR 27(2):573-580)
for the repeats calculation.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 TODO

I should add support to the linux32 binary of TRF, based on the local arch.

=cut
package PLA::Rule::tandemrepeat;

use strict;
use PLA::PLA::IO;
use PLA::FeatureI;

use Bio::SeqIO;
# Thanks to TRF:
use File::Spec;
use File::Basename;
use Cwd;

use base qw(PLA::RuleI);

=head1 APPENDIX

 Methods provided by the package

=cut
sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

sub _initialize {
   my($self,@args) = @_;
   $self->type('tandemrepeat');
}


=head2 execute

 Description	: This is where magic happens.  Translates the parameters of the object
 		  into a call to B<TRF>, and scans the sequence for repeats
 Parameters	: The sequence (-seq) as a Bio::Seq object or a Bio::SeqIO object
 Returns	: An array reference populated with PLA::Feature::tandemrepeat objects

=cut
sub execute {
   my($self,@args) = @_;
   my($seq) = $self->_rearrange([qw(SEQ)], @args);
   
   $self->throw("You must provide a sequence to evaluate the rule", $seq) unless $seq;
   
   # For Bio::SeqIO objects
   if($seq->isa('Bio::SeqIO')){
      my @feats = ();
      while(my $s = $seq->next_seq){
         push(@feats, @{$self->execute(-seq=>$s)})
      }
      return wantarray ? @feats : \@feats;
   }
   
   $self->throw("Illegal class of sequence '".ref($seq)."'", $seq) unless $seq->isa('Bio::Seq');

   # Include safe_value parameters
   # MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP MATCH MISMATCH INDELS MINSCORE MAXSCORE PM PI
   my %c_v = (
      "minsize" => 0,	"maxsize" => 1e20,
      "minperiod" => 0,	"maxperiod" => 500,
      "exp" => 0,
      "match" => 2,	"mismatch"=> 3,	"indels" => 5,
      "minscore" => 50,	"maxscore" => 0,
      "minsim" => 0,	"maxsim" => 100,
      "pm" => 80,	"pi" => 20
   );
   for my $k ( keys %c_v){
      my $p = $self->_search_value($k);
      $c_v{$k} = $p if defined $p; # override defaults
   }

   # Create the IO master
   my $io = PLA::PLA::IO->new();

   # Search for TRF
   $self->source('trf'); # For GFF
   my $trf;
   my $bin = "";
   my $path;
   $path = $self->ruleset->value("path") if defined $self->ruleset;
   $self->debug("Searching the trf binary for $^O");
   # Note the darwin support.  This is because darwin is unable to execute
   # the linux binary (despite its origin)
   if($^O =~ /(macos|darwin)/i){
      $bin = "trf.macosx.bin";
   }elsif($^O =~ /mswin/i){
      $bin = "trf.exe";
   }else{
      $bin = "trf.linux32.bin";
   }
   if($path){
      $trf = $io->exists_exe($path . $bin) unless $trf;
      $trf = $io->exists_exe($path . "trf") unless $trf;
      $trf = $io->exists_exe($path . "trf.bin") unless $trf;
      $trf = $io->exists_exe($path . "trf.exe") unless $trf;
      $trf = $io->exists_exe($path . "trf404") unless $trf;
      $trf = $io->exists_exe($path . "trf404.bin") unless $trf;
      $trf = $io->exists_exe($path . "trf404.exe") unless $trf;
   }
   $trf = $io->exists_exe($bin) unless $trf;
   $trf = $io->exists_exe("trf") unless $trf;
   $trf = $io->exists_exe("trf.bin") unless $trf;
   $trf = $io->exists_exe("trf.exe") unless $trf;
   $trf = $io->exists_exe("trf404") unless $trf;
   $trf = $io->exists_exe("trf404.bin") unless $trf;
   $trf = $io->exists_exe("trf404.exe") unless $trf;
   # Other awful naming systems can be used by this package, but here we stop!
   
   $trf or $self->throw("Could not find the trf binary", $path);
   # Next line is because of the horrible practice of creating files at CWD out
   # of thin air (with no possibility to define another way!)
   $trf = File::Spec->rel2abs($trf) unless File::Spec->file_name_is_absolute($trf);
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile;
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   
   # Run it
   my @run = ($trf);
   push @run, $seq_file;
   push @run, $c_v{'match'}, $c_v{'mismatch'}, $c_v{'indels'};
   push @run, $c_v{'pm'}, $c_v{'pi'}, $c_v{'minscore'}, $c_v{'maxperiod'};
   push @run, "-h"; #<- Simplifies output, and produces one file instead of tons!
   push @run, "2>&1";
   push @run, "|";
   my $cwd = cwd();
   # Finger crossed
   my $tmpdir = PLA::PLA::IO->tempdir();
   chdir $tmpdir or $self->throw("I can not move myself to the temporal directory: $!", $tmpdir);
   $self->debug("Hello from ".cwd());
   $self->debug("Running: ".join(" ",@run)." [CWD: ".cwd()."]");
   my $run = PLA::PLA::IO->new(-file=>join(" ",@run));
   while($run->_readline) {} # Do nothing, this is truly unuseful output
   $run->close();
   # Finger crossed (yes, again)
   chdir $cwd or $self->throw("I can not move myself to the original directory: $!", $cwd);
   $self->debug("Hello from ".cwd());
   
   # Try to locate the output (belive it or not)...
   my $outfile = PLA::PLA::IO->catfile($tmpdir, basename($seq_file) . "." .
   		$c_v{'match'} . "." . $c_v{'mismatch'} . "." . $c_v{'indels'} . "." .
		$c_v{'pm'} . "." . $c_v{'pi'} . "." . $c_v{'minscore'} . "." .
		$c_v{'maxperiod'} . ".dat");
   $self->throw("Impossible to locate the output file of TRF", $outfile) unless -e $outfile;
   
   # And finally parse it
   my $ontable = 0;
   my @feats = ();
   $run = PLA::PLA::IO->new(-file=>$outfile);
   while(my $line = $run->_readline){
      if($line =~ m/^Parameters:\s/){
         $ontable = 1;
      }elsif($ontable){
	 chomp $line;
	 next if $line =~ /^\s*$/;
	 #from to period-size copy-number consensus-size percent-matches percent-indels score A T C G entropy consensus sequence
	 #269 316 18 2.6 19 56 3 51 8 45 35 10 1.68 GTCGCGGCCACGTGCACCC GTCGCGTCCACGTGCGCCCGAGCCGGC...
	 my @v = split /\s+/, $line;
	 $#v==14 or $self->throw("Unexpected line $.",$line,"PLA::PLA::ParsingException");
	 # MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP MATCH MISMATCH INDELS MINSCORE MAXSCORE
	 next if length($v[14]) > $c_v{'maxsize'} or length($v[14]) < $c_v{'minsize'};
	 next if $v[2] > $c_v{'maxperiod'} or $v[2] < $c_v{'minperiod'};
	 next if $v[3] < $c_v{'exp'};
	 next if $v[7] < $c_v{'minscore'};
	 next if $c_v{'maxscore'} and $v[7] > $c_v{'maxscore'};
	 next if $v[5] < $c_v{'minsim'} or $v[5] > $c_v{'maxsim'};
	 
	 my $id = $self->_next_child_id;
	 push @feats, PLA::FeatureI->new(
	 		-type=>'repeat', # Be careful, usually $self->type
			-rule=>$self, -seq=>$seq,
			-from=>$v[0]+0, -to=>$v[1]+0, -strand=>"+",
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-period=>$v[2]+0, -exponent=>$v[3]+0,
			-consensus=>$v[13],
			-error=>100-$v[5],
			-score=>$v[7],
			-repeats=>$v[14]);
      }
   }
   $run->close();
   unlink $outfile;
   rmdir $tmpdir;
   return wantarray ? @feats : \@feats;
}


sub stringify_value {
   my ($self,@args) = @_;
   my $out = "";
   for my $k (keys %{$self->value}){
      $out.= "$k=>".(defined $self->value->{$k} ? $self->value->{$k} : "")." ";
   }
   return $out;
}

sub _parameters {
   return [qw(MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP MATCH MISMATCH INDELS MINSCORE MAXSCORE MINSIM MAXSIM PM PI)];
}

=head2 _qualify_value

 Description	: Implements the _qualify_value from the PLA::RuleI interface
 Arguments	: Value (str or ref-to-hash or ref-to-array)
 		  The supported keys are:
			-minsize : Minimum size of the repeat
			-maxsize : Maximum size of the repeat
			-minperiod : Minimum period of the repeat
			-maxperiod : Maximum period of the repeat
			-exp : Minimum exponent (number of repeats)
			-match : Matching weight
			-mismatch : Mismatching penalty
			-indels : Indel penalty
			-minscore : Minimum score
			-maxscore : Maximum score
			-minsim : Minimum similarity percent
			-maxsim : Maximum similarity percent
			-pm : match probability
			-pi : indel probability
 Return		: Value (ref-to-hash or undef)

=cut
sub _qualify_value {
   my($self,$value) = @_;
   unless (defined $value){
      $self->warn("Empty value");
      return;
   }
   if(ref($value) =~ m/hash/i){
      my @arr = %{$value};
      $value = \@arr;
   }
   my @args = ref($value) =~ /array/i ? @{$value} : split/\s+/, $value;

   return unless defined $args[0];
   if($args[0] !~ /^-/){
      $self->warn("Expecting parameters in the format -parameter value", @args);
      return;
   }
   unless($#args%2){
      $self->warn("Unexpected (odd) number of parameters", @args);
      return;
   }

   my %vals = @args;
   my $out = {};
   for my $k ( @{$self->_parameters} ){
      my $p = $self->_rearrange([$k], @args);
      next unless defined $p;
      if( $p !~ /^[\d\.eE+-]+$/ ){
         $self->warn("Unexpected value for ".$k, $p);
	 return;
      }
      $out->{"-".lc $k} = $p;
   }
   return $out;
}

1;
