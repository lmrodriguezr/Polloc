=head1 NAME

Polloc::Locus::extend - A feature based on another one

=head1 DESCRIPTION

A feature of a sequence, inferred by similarity or surrounding
regions similar to those of a known feature.  Implements
L<Polloc::LocusI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Locus::extend;

use strict;
use base qw(Polloc::LocusI);


=head1 APPENDIX

 Methods provided by the package

=cut


=head2 new

 Description	: Creates a B<Polloc::Locus::repeat> object
 Arguments	: -basefeature : (C<Polloc::LocusI> object) The reference
 			feature or part of the reference collection
 		  -score : (float) The score of extension (bit-score
		  	on BLAST or score on HMMer, for example).
 Returns	: A B<Polloc::Locus::extend> object

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}


=head2 basefeature

 Purpose	: Gets/sets the reference feature of the extension.  Be
 		  careful, this can also refer to one feature in a
		  collection of reference.  Avoid using specific data
		  from this feature.
 Arguments	: The reference feature (Polloc::LocusI object, optional)
 Returns	: The reference feature (Polloc::LocusI object or undef)

=cut

sub basefeature {
   my($self,$value) = @_;
   if (defined $value){
      $self->{'_basefeature'} = $value;
      $self->family($value->family);
   }
   return $self->{'_basefeature'};
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
 Arguments	: See L<Polloc::Locus::repeat::new>
 Returns	: none

=cut

sub _initialize {
   my($self,@args) = @_;
   my($basefeature,$score) = $self->_rearrange([qw(BASEFEATURE SCORE)], @args);
   $self->type('extend');
   $self->comments("Extended feature");
   $self->basefeature($basefeature);
   $self->score($score);
}

1;
