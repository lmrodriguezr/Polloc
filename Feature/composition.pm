=head1 NAME

Polloc::Feature::composition - A composition feature

=head1 DESCRIPTION

This feature is intended to save the content of a group of
residues in a certain sequence.  This feature was first
created to reflect the G+C content.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Feature::composition;

use strict;
use base qw(Polloc::FeatureI);


=head1 APPENDIX

 Methods provided by the package

=cut

=head2 new

 Description	: Initializes the feature
 Arguments	: -letters : (str) The residues
 		  -composition : (float) The percentage of the sequence covered by
		  	the residues (letters).
 Returns	: A Polloc::Feature::composition object

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

sub _initialize {
   my($self,@args) = @_;
   my($letters, $composition) = $self->_rearrange(
   		[qw(LETTERS COMPOSITION)], @args);
   $self->type('composition');
   $self->letters($letters);
   $self->comments("Residues=" . $self->letters) if defined $self->letters;
   $self->composition($composition);
   $self->comments("Perc=" . sprintf("%.2f",$self->composition)) if defined $self->composition;
}


=head2 letters

 Purpose	: Gets/sets the analysed residues.
 Arguments	: The residues (str, optional)
 Returns	: The residues (str or undef)

=cut

sub letters {
   my($self,$value) = @_;
   $self->{'_letters'} = $value if defined $value;
   return $self->{'_letters'};
}


=head2 composition

 Purpose	: Gets/sets the percentage of the sequence
 		  covered by the residues (letters).
 Arguments	: The percentage (float, optional)
 Returns	: The percentage (float or undef)

=cut

sub composition {
   my($self,$value) = @_;
   $self->{'_composition'} = $value if defined $value;
   return $self->{'_composition'};
}


=head2 score

 Description	: Dummy function, required by the L<Polloc::FeatureI>
 		  interface.  Returns undef because any score is associated
 Arguments	: none
 Returns	: undef

=cut

sub score { return }

1;
