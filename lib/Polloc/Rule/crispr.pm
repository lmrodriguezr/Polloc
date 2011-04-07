=head1 NAME

Polloc::Rule::crispr - A rule of type CRISPR

=heqd1 DESCRIPTION

Runs CRISPRFinder to search CRISPRs

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Rule::crispr;

use strict;
use Polloc::Polloc::IO;
use Polloc::LocusI;

use Bio::SeqIO;
# For CRISPRFinder:
use File::Spec;
use Cwd;

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
   $self->type('CRISPR');
}


=head2 execute

 Description	: Runs CRIPRRfinder and parses the output.
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

   # Create the IO master
   my $io = Polloc::Polloc::IO->new();

   # Search for CRISPRFinder
   $self->source('CRISPRFinder');
   my ($cf_dir, $cf_script, $cf_def_dir);
   my $root;
   $root = $self->ruleset->value("root") if defined $self->ruleset;
   my $cf_loc;
   $cf_loc = $self->ruleset->value("crisprfinder") if defined $self->ruleset;
   
   $self->debug("Searching the CRISPRFinder directory for $^O");
   if($^O =~ /mswin/i){
      $self->throw("Unsupported platform", $^O);
   }else{
      $cf_def_dir = "CRISPRFinder";
   }
   $cf_dir = $cf_loc if $cf_loc && -d $cf_loc;
   $cf_dir ||= $root . $cf_def_dir if $root && -d $root . $cf_def_dir;
   $cf_dir ||= "~/" . $cf_def_dir if -d "~/" . $cf_def_dir;
   $cf_dir ||= "/opt/" . $cf_def_dir if -d "/opt/" . $cf_def_dir;
   $cf_dir ||= "/var/" . $cf_def_dir if -d "/var/" . $cf_def_dir;
   $cf_dir or $self->throw("Could not find the CRISPRFinder directory", $root);
   $cf_dir = File::Spec->rel2abs($cf_dir) unless File::Spec->file_name_is_absolute($cf_dir);
   $cf_dir.= "/";
   
   my $perl = $io->exists_exe("perl");
   $perl ||= $io->exists_exe("perl5");
   $perl or $self->throw("Where is perl?");
   
   $cf_script = "CRISPRFinder-v3.pl";
   $cf_script = "CRISPRFinder-v3" unless -e $cf_dir . $cf_script;
   $cf_script = "CRISPRFinder.pl" unless -e $cf_dir . $cf_script;
   $cf_script = "CRISPRFinder" unless -e $cf_dir . $cf_script;
   -e $cf_dir . $cf_script or $self->throw("I can not find the CRISPRFinder script", $cf_dir);
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile(-suffix=>'.fasta'); # required by CRISPRFinder
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   
   # Run it
   my $cwd = cwd();
   $self->debug("Sequence file: $seq_file (".(-s $seq_file).")");
   my @run = ($perl, $cf_script, $seq_file);
   push @run, "2>&1";
   push @run, "|";
   chdir $cf_dir or $self->throw("I can not move myself to the CRISPRFinder directory: $!", $cf_dir);
   $self->debug("Hello from ".cwd());
   $self->debug("Running: ".join(" ",@run));
   my $run = Polloc::Polloc::IO->new(-file=>join(" ",@run));
   my @dirs = ();
   while(my $line = $run->_readline){
      if($line =~ m/\*\*\* your results files will be in the (.*) directory \*\*\*/){
         push @dirs, $1;
      }
   }
   $run->close();
   chdir $cwd or $self->throw("I can not come back to the previous folder: $!", $cwd);
   $self->debug("Hello from ".cwd());
   
   my $getProbables = ! $self->_search_value("IGNOREPROBABLE");
   my @feats = ();
   my $out = "";
   for my $dir (@dirs){
      $dir = $cf_dir . '/' . $dir;
      next unless -d $dir; # CRISPRFinder automatically delete empty directories
      $self->debug("Gathering results for $dir");
      for my $file (<$dir/*>){
         $self->debug("Reading $file");
	 if($file=~m/_Crispr_(\d+)$/i || ($getProbables && $file=~m/_PossibleCrispr_(\d+)$/i)){
	    #my $id = $1+0;
	    #my $spacers = $dir . '/' . "Spacers_$id";
	    my $from;
	    my $to;
	    my $spacers;
	    my $dr;
	    open CR, "<", $file or $self->throw("I can not open the file: $!", $file);
	    while(<CR>){
	       if(m/^# Crispr_begin_position:\s+(\d+)\s+Crispr_end_position:\s+(\d+)/){
	          $from = $1+0;
		  $to = $2+0;
	       }elsif(m/^# DR:\s+(\S+)\s+DR_length:\s+(\d+)\s+Number_of_spacers:\s+(\d+)/){
	          $dr = $1;
		  $spacers = $3+0;
	       }
	    } #while line
	    close CR;
	    if(defined $from && defined $to){
	       $dr ||= "";
	       $spacers ||= 0;
	       my $id = $self->_next_child_id;
	       my $score = $file=~/_PossibleCrispr_\d+$/i ? 50 : 100;
	       push @feats, Polloc::LocusI->new(
	 		-type=>$self->type, -rule=>$self, -seq=>$seq,
			-from=>$from, -to=>$to, -strand=>"+",
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-dr=>$dr,
			-score=>$score,
			-spacers_no=>$spacers);
	    }
	 } # if proper file
	 unlink $file;
      } # for files
      rmdir $dir;
   } # for dirs
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
   return [qw(IGNOREPROBABLE)];
}

=head2 _qualify_value

 Description	: Implements the _qualify_value from the Polloc::RuleI interface
 Arguments	: Value (str or ref-to-hash or ref-to-array)
 		  The supported keys are:
			-ignoreprobable : Should I ignore the 'ProbableCrispr' results?
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
   my $out = {};

   return $out unless defined $args[0];
   if($args[0] !~ /^-/){
      $self->warn("Expecting parameters in the format -parameter value", @args);
      return;
   }
   unless($#args%2){
      $self->warn("Unexpected (odd) number of parameters", @args);
      return;
   }

   my %vals = @args;
   for my $k ( @{$self->_parameters} ){
      my $p = $self->_rearrange([$k], @args);
      next unless defined $p;
      if( $p !~ /^([\d\.eE+-]+|t(rue)?|f(alse)?)$/i ){
         $self->warn("Unexpected value for ".$k, $p);
	 return;
      }
      $out->{"-".lc $k} = $p=~m/^f(alse)$/i ? 0 : $p; # This is because the str 'false' evaluates as true ;-)
   }
   return $out;
}

1;
