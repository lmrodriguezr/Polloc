=head1 NAME

PLA::Rule::composition - A rule of type composition

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package PLA::Rule::composition;

use strict;
use base qw(PLA::RuleI);
use PLA::FeatureI;
use Bio::SeqIO;


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
   $self->type('composition');
}


=head2 execute

 Description	: Counts the number of letters or groups of letters and compares this
 		  number with the requested range (See
		  L<PLA::Rule::composition::_qualify_value>)
 Parameters	: The sequence (-seq) as a Bio::Seq object or a Bio::SeqIO object
 Returns	: An array reference populated with PLA::Feature::composition objects
 		  or undef.  Note that this method returns one Feature per sequence at
		  most.

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
   $self->value($self->value);
   
   # Run it
   my @feats;
   my $ln = $seq->length();
   my $al = $self->letters();
   my $oc = 0;
   my $sq = $seq->seq;
   for ( ; $sq =~ s/[$al]// ; $oc++ ) {}
   $sq=undef;
   my $perc = 100 * $oc / $ln;
   if($perc > $self->min_perc && $perc < $self->max_perc){
      my $id = $self->_next_child_id;
      push @feats, PLA::FeatureI->new(
      			-type=>$self->type, -rule=>$self, -seq=>$seq,
			-from=>1, -to=>$ln, -strand=>'+',
			-name=>$self->name,
			-id=>(defined $id ? $id : ''),
			-letters=>$self->letters,
			-composition=>$perc );
   }
   return wantarray ? @feats : \@feats;
}


sub stringify_value {
   my ($self,@args) = @_;
   my $out = "";
   $out.= $self->min_perc if defined $self->min_perc;
   $out.= "..";
   $out.= $self->max_perc if defined $self->max_perc;
   return $out;
}


=head2 letters

 Description	: Sets/gets the residues
 Arguments	: Residues (str, optional)
 Returns	: Residues (str or undef)

=cut

sub letters { shift->_search_value("letters", shift) }


=head2 min_perc

 Description	: Sets/gets the minimum percentage
 Arguments	: Percentage (float, optional)
 Returns	: Percentage (float or undef)

=cut

sub min_perc { shift->_search_value("min_perc", shift) }


=head2 max_perc

 Description	: Sets/gets the maximum percentage
 Arguments	: Percentage (float, optional)
 Returns	: Percentage (float or undef)

=cut

sub max_perc { shift->_search_value("max_perc", shift) }


=head2 _qualify_value

 Description	: Implements the _qualify_value from the PLA::RuleI interface
 Arguments	: Value (str or ref-to-hash or ref-to-array)
 		  The supported keys are:
		  	-letters : The residues to take into account as a string
			-range : The allowed (perc.) range in the format 20..50
			-min_perc : The minimum percentage (ignored if range is set)
			-max_perc : The maximum percentage (ignored if range is set)
 Return		: Value (ref-to-hash or undef)

=cut

sub _qualify_value {
   my($self,$value) = @_;
   return unless defined $value;
   if(ref($value) =~ m/hash/i){
      my @arr = %{$value};
      $value = \@arr;
   }
   my @args = ref($value) =~ /array/i ? @{$value} : split(/\s+/, $value);
   my($letters,$range,$min_perc,$max_perc) =
   		$self->_rearrange([qw(LETTERS RANGE MIN_PERC MAX_PERC)], @args);
   
   my $out = {};
   
   if($letters && $letters =~ /^[A-Za-z]+$/){
      $out->{'-letters'} = uc $letters;
   }elsif($letters){
      $self->warn("Unknown signs within the letters", $letters);
      return;
   }

   if(defined $min_perc and defined $max_perc and not $range){
      $range = "$min_perc..$max_perc";
   }
   
   if($range && $range =~ /^([\d\.]+)\.\.([\d\.]+)$/){
      $out->{'-min_perc'} = $1+0;
      $out->{'-max_perc'} = $2+0;
   }elsif($range){
      $self->warn("Unexpected range", $range);
      return;
   }
   
   return $out;
}

1;
