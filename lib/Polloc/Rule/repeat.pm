=head1 NAME

Polloc::Rule::repeat - A rule of type repeat

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 TODO

=head2 Solve this:

The additional parameters (stored with C<safe_value()>) are not
included in the command line.  This is not prioritary, but could
lead more serious errors.

=head2 Standardize

Homogenize the whole values system (see L<Polloc::Rule::composition>).
This should actually solve the former point.

=cut

package Polloc::Rule::repeat;

use strict;
use Polloc::Polloc::IO;
use Polloc::LocusI;

use Bio::SeqIO;

use base qw(Polloc::RuleI);

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
   $self->type('repeat');
}


=head2 execute

 Description	: This is where magic happens.  Translates the parameters of the object
 		  into a call to B<mreps>, and scans the sequence for repeats
 Parameters	: The sequence (-seq) as a Bio::Seq object or a Bio::SeqIO object
 Returns	: An array reference populated with Polloc::Locus::repeat objects

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
   my $cmd_vars = {};
   for my $p ( qw(RES MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP ALLOWSMALL WIN) ){
      my $tv = $self->_search_value($p);
      $cmd_vars->{"-" . lc $p} = $tv if defined $tv;
   }
   my $minsim = $self->_search_value("minsim")+0;
   $minsim ||= 0;
   my $maxsim = $self->_search_value("maxsim")+0;
   $maxsim ||= 100;

   # Create the IO master
   my $io = Polloc::Polloc::IO->new();

   # Search for mreps
   $self->source('mreps');
   my $mreps;
   my $bin = "";
   my $path;
   $path = $self->ruleset->value("path") if defined $self->ruleset;
   $self->debug("Searching the mreps binary for $^O");
   # Note the darwin support.  This is because darwin is unable to execute
   # the linux binary (despite its origin)
   if($^O =~ /(macos|darwin)/i){
      $bin = "mreps.macosx.bin";
   }elsif($^O =~ /mswin/i){
      $bin = "mreps.exe";
   }else{
      $bin = "mreps.linux.bin";
   }
   if($path){
      $mreps = $io->exists_exe($path . $bin) unless $mreps;
      $mreps = $io->exists_exe($path . "mreps") unless $mreps;
      $mreps = $io->exists_exe($path . "mreps.bin") unless $mreps;
   }
   $mreps = $io->exists_exe($bin) unless $mreps;
   $mreps = $io->exists_exe("mreps") unless $mreps;
   $mreps = $io->exists_exe("mreps.bin") unless $mreps;
   
   $mreps or $self->throw("Could not find the mreps binary", $path);
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile;
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   
   # Run it
   my @run = ($mreps);
   push @run, %{$cmd_vars};
   push @run, "-fasta", $seq_file;
   push @run, "2>&1";
   push @run, "|";
   $self->debug("Running: ".join(" ",@run));
   my $run = Polloc::Polloc::IO->new(-file=>join(" ",@run));
   my $ontable = 0;
   my @feats = ();
   while(my $line = $run->_readline){
      if($line =~ m/^ -----------------------------/){
         $ontable = !$ontable;
      }elsif($ontable){
	 chomp $line;
	 #  from   ->       to  :         size    <per.>  [exp.]          err-rate       sequence
	 $line =~ m/^\s+(\d+)\s+->\s+(\d+)\s+:\s+(\d+)\s+<(\d+)>\s+\[([\d\.]+)\]\s+([\d\.]+)\s+([\w\s]+)$/
		or $self->throw("Unexpected line $.",$line,"Polloc::Polloc::ParsingException");
	 my $score = 100 - $6*100;
	 next if $score > $maxsim or $score < $minsim;
	 my $id = $self->_next_child_id;
	 my $cons = $self->_calculate_consensus($7);
	 push @feats, Polloc::LocusI->new(
	 		-type=>$self->type, -rule=>$self, -seq=>$seq,
			-from=>$1+0, -to=>$2+0, -strand=>"+",
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-period=>$4+0, -exponent=>$5+0,
			-error=>$6*100,
			-score=>$score,
			-consensus=>$cons,
			-repeats=>$7);
      }
   }
   $run->close();
   return wantarray ? @feats : \@feats;
}

sub _calculate_consensus {
   my($self,$seq) = @_;
   return unless $seq;
   my $io = Polloc::Polloc::IO->new();
   my $emma = $io->exists_exe("emma");
   my $cons = $io->exists_exe("cons");
   return "no-emma" unless $emma;
   return "no-cons" unless $cons;
   my ($outseq_fh, $outseq) = $io->tempfile;
   my $i=0;
   print $outseq_fh ">".(++$i)."\n$_\n" for split /\s+/, $seq;
   close $outseq_fh;
   return "err-seq" unless -s $outseq;
   my $outaln = "$outseq.aln";
   my $emmarun = Polloc::Polloc::IO->new(-file=>"$emma '$outseq' '$outaln' '/dev/null' -auto >/dev/null |");
   while($emmarun->_readline){ print STDERR $_ }
   $emmarun->close();
   unless(-s $outaln){
      unlink $outaln if -e $outaln;
      return "err-aln";
   }
   my $consout = "";
   my $consrun = Polloc::Polloc::IO->new(-file=>"$cons '$outaln' stdout -auto |");
   while(my $ln = $consrun->_readline){
      chomp $ln;
      next if $ln =~ /^>/;
      $consout .= $ln;
   }
   unlink $outaln;
   $consrun->close();
   $io->close();
   return $consout;
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
   return [qw(RES MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP ALLOWSMALL WIN MINSIM MAXSIM)];
}

=head2 _qualify_value

 Description	: Implements the _qualify_value from the Polloc::RuleI interface
 Arguments	: Value (str or ref-to-hash or ref-to-array)
 		  The supported keys are:
		  	-res : Resolution (allowed error)
			-minsize : Minimum size of the repeat
			-maxsize : Maximum size of the repeat
			-minperiod : Minimum period of the repeat
			-maxperiod : Maximum period of the repeat
			-exp : Minimum exponent (number of repeats)
			-allowsmall : If 1, allows spurious results
			-win : Process by sliding windows of size 2*n overlaping by n
			-minsim : Minimum similarity percent
			-maxsim : Maximum similarity percent
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
