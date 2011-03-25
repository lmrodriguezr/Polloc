=head1 NAME

PLA::Rule::boolean - A rule of type boolean operator

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package PLA::Rule::boolean;

use strict;
use PLA::PLA::IO;
use PLA::FeatureI;

use Bio::SeqIO;

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
   $self->type('boolean');
}


=head2 execute

 Description	: 
 Parameters	: -seq, a Bio::Seq or Bio::SeqIO object
 Returns	: An array reference populated with PLA::Feature::* objects
 Throws		: PLA::PLA::UnexpectedException if the operator is not supported
 		  PLA::PLA::Error if the rule is not within a rule set

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
   
   # Preset the environment
   $self->throw("Impossible to qualify a boolean outside a Rule Set (PLA::RuleIO)", $self)
   		unless defined $self->ruleset;
   $self->throw("Illegal object as Rule Set", $self->ruleset)
   		unless $self->ruleset->isa('PLA::RuleIO');
   $self->value($self->value); # To implicitly call _qualify_value
   
   $self->throw("Illegal class of sequence '".ref($seq)."'", $seq)
   		unless $seq->isa('Bio::Seq');
   $self->throw("Impossible to compare with '".$self->operator.
   	"' on undefined second object", $self->rule2)
   		if $self->operator and not defined $self->rule2;
   
   my @feats = ();
   for my $feat_obj (@{$self->rule1->execute(-seq=>$seq)}){
      if($self->operator eq 'and' or $self->operator eq 'not'){
      # And or Not
         my $sbj_seq = Bio::Seq->new(	-display_id => $seq->display_id,
	 				-seq => $seq->subseq($feat_obj->from, $feat_obj->to) );
         my @feat_sbjs = @{ $self->rule2->execute(-seq=>$sbj_seq) };
	 next if $#feat_sbjs<0 and $self->operator eq 'and';
	 next if $#feat_sbjs>=0 and $self->operator eq 'not';
	 if($self->operator eq 'not'){
	 # Not
	    $feat_obj->comments('Not ' . $self->rule2->stringify);
	    push @feats, $feat_obj;
	 }else{
	 # And
	    my $comm = 'And ' . $self->rule2->stringify . '{';
	    for my $feat_sbj ( @feat_sbjs ){
	       my $ft_comm = defined $feat_sbj->comments ? " (".($feat_sbj->comments).")" : "";
	       $ft_comm =~ s/[\n\r]+/; /g;
	       $comm.= $feat_sbj->stringify . $ft_comm . ", ";
	    }
	    $feat_obj->comments(substr($comm,0,-2) . '}');
	    push @feats, $feat_obj;
	 }
      }elsif($self->operator eq 'or' || not defined $self->rule2){
      # Or or any operation
         push @feats, $feat_obj;
      }else{
      # Oops!
         $self->throw("Unsupported operator",
	 	$self->operator, 'PLA::PLA::UnexpectedException');
      }
   }
   if($self->operator eq 'or'){
   # Or simply adds the two sets of features
      push @feats, @{$self->rule2->execute(-seq=>$seq)};
   }
   
   return wantarray ? @feats : \@feats;
}


=head2 rule1

 Description	: Gets/sets the first rule
 Arguments	: A PLA::RuleI object (optional)
 Returns	: PLA::RuleI object or undef

=cut

sub rule1 {
   my($self,$value) = @_;
   $self->{'_rule1'} = $value if defined $value;
   $self->{'_rule1'} = $self->safe_value('rule1') unless defined $self->{'_rule1'};
   return $self->{'_rule1'};
}


=head2 operator

 Description	: Gets/sets the operator
 Arguments	: A string with the operator
 Returns	: string 'and', 'or', 'not' or undef

=cut

sub operator {
   my($self,$value) = @_;
   # Set by received value
   if($value){
      $value = lc $value;
      $value =~ s/\&/and/;
      $value =~ s/\|/or/;
      $value =~ s/\^/not/;
      $self->throw("Unsupported operator", $value) if $value !~ /^(and|or|not)$/;
      $self->{'_operator'} = $value;
   }
   
   # Set by value()
   unless($self->{'_operator'}){
      my $op = $self->value;
      $self->operator($op) if $op;
   }

   # Set by safe_value()
   unless($self->{'_operator'}){
      my $op = $self->safe_value('operator');
      $self->operator($op) if $op;
   }
   
   # Return
   $self->{'_operator'} ||= '';
   return $self->{'_operator'};
}


=head2 rule2

 Description	: Gets/sets the second rule
 Arguments	: A PLA::RuleI object (optional)
 Returns	: PLA::RuleI object or undef

=cut

sub rule2 {
   my($self,$value) = @_;
   $self->{'_rule2'} = $value if defined $value;
   $self->{'_rule2'} = $self->safe_value('rule2') unless defined $self->{'_rule2'};
   return $self->{'_rule2'};
}

sub stringify_value {
   my ($self,@args) = @_;
   my $out = "";
   return $out unless defined $self->rule1;
   $out.= $self->rule1->stringify;
   return $out unless defined $self->rule2;
   $out.= ' ' . $self->operator . ' ' . $self->rule2->stringify ;
   return $out;
}


=head2 _qualify_value

 Description	: Implements the _qualify_value from the PLA::RuleI interface
 Arguments	: Anything, the operation should be set using the
 		  L<PLA::Rule::boolean::rule1()>, L<PLA::Rule::boolean::operator()>
		  and L<PLA::Rule::boolean::rule2()> functions
 Return		: The received value.
 Note		: Do not call L<PLA::RuleI::value()> with an undefined value, it is
 		  the only way to make it crash for booleans

=cut

sub _qualify_value {
   return $_[1];
}

1;
