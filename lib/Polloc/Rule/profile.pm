=head1 NAME

Polloc::Rule::profile - A rule of type profile

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Rule::profile;

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

 Description	: Runs the search using HMMer
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
   
   $self->throw("Illegal class of sequence '".ref($seq)."'", $seq)
   		unless $seq->isa('Bio::Seq');

   # Create the IO master
   my $io = Polloc::Polloc::IO->new();

   # Search for hmmersearch
   $self->source('hmmer');
   my $hmmer;
   my $path;
   my $bin = "hmmsearch";
   $path = $self->ruleset->value("path") if defined $self->ruleset;
   $self->debug("Searching the $bin binary for $^O");
   if($path){
      $hmmer = $io->exists_exe($path . $bin) unless $hmmer;
   }
   $hmmer = $io->exists_exe($hmmer) unless $hmmer;
   $hmmer or $self->throw("Could not find the i$bin binary", $path);
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile;
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   
   # Run it
   my @run = ($hmmer);
   my %cmd_args = (	'evalue'=>'-E', 'score'=>'-T',
   			'ince'=>'--incE', 'inct'=>'--incT',
			'incdome'=>'--incdomE', 'incdomt'=>'--incdomT',
			'f1'=>'--F1', 'f2'=>'--F2', 'f3'=>'--F3',
			'domz'=>'--domZ', 'seed'=>'--seed', 'tformat'=>'--tformat',
			'cpu'=>'--cpu');
   for my $k (keys %cmd_args){
      my $v = $self->_search_value($k);
      push @run, $cmd_args{$k}, $v if defined $v;
   }
   my %cmd_flags = (	'acc'=>'--acc',
   			'cut_ga'=>'--cut_ga', 'cut_nc'=>'--cut_nc', 'cut_tc'=>'--cut_tc',
			'max'=>'--max', 'noheuristics'=>'--max', 'nobias'=>'--nobias',
			'nonull2'=>'--nonull2');
   for my $k (keys %cmd_flags){
      my $v = 0+$self->_search_value($k);
      push @run, $cmd_flags{$k} if $v;
   }
   push @run, $self->_search_value('hmm'), $seq_file, "|";
   $self->debug("Running: ".join(" ",@run));
   my $run = Polloc::Polloc::IO->new(-file=>join(" ",@run));
   my @feats = ();
   while(my $line = $run->_readline){
      # TODO PARSE IT
      if($line =~ m/^ -----------------------------/){
         $ontable = !$ontable;
      }elsif($ontable){
	 chomp $line;
	 #  from   ->       to  :         size    <per.>  [exp.]          err-rate       sequence
	 $line =~ m/^\s+(\d+)\s+->\s+(\d+)\s+:\s+(\d+)\s+<(\d+)>\s+\[([\d\.]+)\]\s+([\d\.]+)\s+([\w\s]+)$/
		or $self->throw("Unexpected line $.",$line,"Polloc::Polloc::ParsingException");
	 my $id = $self->_next_child_id;
	 push @feats, Polloc::LocusI->new(
	 		-type=>$self->type, -rule=>$self, -seq=>$seq,
			-from=>$1+0, -to=>$2+0, -strand=>"+",
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-period=>$4+0, -exponent=>$5+0,
			-error=>$6*100 );
      }
   }
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
 Return		: Value (ref-to-hash or undef)

=cut
sub _qualify_value {
   my($self,$value) = @_;
   return unless defined $value;
   if(ref($value) =~ m/hash/i){
      my @arr = %{$value};
      $value = \@arr;
   }
   $value = join(" ", @{$value}) if ref($value) =~ m/array/i;

   $self->debug("Going to parse the value '$value'");
   
   if( $value !~ /^(\s*-\w+\s+[\d\.]+\s*)*$/i){
      $self->warn("Unexpected parameters for the repeat", $value);
      return;
   }
   
   my @args = split /\s+/, $value;
   unless($#args % 2){
      $self->warn("Unexpected (odd) number of parameters", @args);
      return;
   }
   
   my %params = @args;
   $value = {};
   for my $k (("res","minsize","maxsize","minperiod","maxperiod","exp","allowsmall","win")){
      $value->{"-$k"} = $params{"-$k"}+0 if defined $params{"-$k"};
      $value->{"-$k"} = $self->safe_value("-$k") 
			if not defined $value->{"-$k"}
      			and defined $self->safe_value("-$k");
   }
   $value->{"-allowsmall"} = "" if defined $value->{"-allowsmall"};
   return $value;
}

1;
