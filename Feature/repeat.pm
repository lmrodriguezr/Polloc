=head1 NAME

PLA::Feature::repeat - A repeat feature

=head1 DESCRIPTION

A feature of repeats.  Implements L<PLA::FeatureI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package PLA::Feature::repeat;

use strict;
use base qw(PLA::FeatureI);


=head1 APPENDIX

 Methods provided by the package

=head2 new

 Description	: Creates a B<PLA::Feature::repeat> object
 Arguments	: -period : (float) The period of the repeat (units length)
 		  -exponent: (float) The exponent (No of units)
		  -error : (float) Mismatches percentage
		  -repeats : (str) Repetitive sequences, repeats space-separated
		  -consensus : (str) Repeats consensus
 Returns	: A B<PLA::Feature::repeat> object

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}


=head2 period

 Purpose	: Gets/sets the period of the repeat.  I.e., the
 		  size of each repeat.
 Arguments	: The period (int)
 Returns	: The period (int or undef)

=cut

sub period {
   my($self,$value) = @_;
   $self->{'_period'} = $value+0 if defined $value;
   return $self->{'_period'};
}


=head2 exponent

 Purpose	: Gets/sets the exponent of the repeat.  I.e., the
 		  number of times the repeat is repeated.
 Arguments	: The exponent (int)
 Returns	: The exponent (int or undef)

=cut

sub exponent {
   my($self,$value) = @_;
   $self->{'_exponent'} = $value if defined $value;
   return $self->{'_exponent'};
}


=head2 repeats

 Description	: Sets/gets the repetitive sequence (each repeat separated by spaces)
 Arguments	: The repetitive sequence (str, optional)
 Returns	: The repetitive sequence (str or undef)

=cut

sub repeats {
   my($self,$value) = @_;
   $self->{'_repeats'} = $value if defined $value;
   return $self->{'_repeats'};
}


=head2 consensus

 Description	: Sets/gets the consensus repeat
 Arguments	: The consensus sequence (str, optional)
 Returns	: The consensus sequence (str or undef)

=cut

sub consensus {
   my($self,$value) = @_;
   $self->{'_consensus'} = $value if defined $value;
   return $self->{'_consensus'};
}

=head2 error

 Purpose	: Gets/sets the error rate of the repeat.  I.e.
 		  the percentage of mismatches.
 Arguments	: The error (float)
 Returns	: The error (float or undef)

=cut

sub error {
   my($self,$value) = @_;
   $self->{'_error'} = $value+0 if defined $value;
   return $self->{'_error'};
}


=head2 score

 Description	: Gets/sets the score
 Arguments	: none
 Returns	: The score (float)

=cut

sub score {
   my($self,$value) = @_;
   $self->{'_score'} = $value+0 if defined $value;
   return $self->{'_score'};
}


=head2 _initialize

 Description	: Initialization function.
 Arguments	: See L<PLA::Feature::repeat::new>
 Returns	: none

=cut

sub _initialize {
   my($self,@args) = @_;
   my($period,$exponent,$score,$error,$repeats,$consensus) = $self->_rearrange(
   		[qw(PERIOD EXPONENT SCORE ERROR REPEATS CONSENSUS)], @args);
   $self->type('repeat');
   $self->period($period);
   $self->comments("Period=" . $self->period) if defined $self->period;
   $self->exponent($exponent);
   $self->comments("Exponent=" . $self->exponent) if defined $self->exponent;
   $self->score($score);
   $self->comments("Score=" . $self->score) if defined $self->score;
   $self->error($error);
   $self->comments("Error=" . $self->error) if defined $self->error;
   $self->repeats($repeats);
   $self->consensus($consensus);
}

1;
