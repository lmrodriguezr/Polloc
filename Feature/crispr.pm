=head1 NAME

Polloc::Feature::crispr - A CRISPR feature

=head1 DESCRIPTION

A feature of CRISPR.  Implements L<Polloc::FeatureI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Feature::crispr;

use strict;
use base qw(Polloc::FeatureI);


=head1 APPENDIX

 Methods provided by the package

=head2 new

 Description	: Creates a B<Polloc::Feature::repeat> object
 Arguments	: -spacers_no : (int) The number of spacers
 		  -dr: (str) Direct repeat sequence
 Returns	: A B<Polloc::Feature::repeat> object

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}


=head2 spacers_no

 Purpose	: Gets/sets the number of spacers.
 Arguments	: The number of spacers (int, optional)
 Returns	: The number of spacers (int or undef)

=cut

sub spacers_no {
   my($self,$value) = @_;
   $self->{'_spacers_no'} = $value if defined $value;
   return $self->{'_spacers_no'};
}


=head2 dr

 Description	: Sets/gets the Direct Repeat sequence.
 Arguments	: The direct repeat sequence (str, optional)
 Returns	: The direct repeat sequence (str or undef)

=cut

sub dr {
   my($self,$value) = @_;
   $self->{'_dr'} = $value if defined $value;
   return $self->{'_dr'};
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
 Arguments	: See L<Polloc::Feature::repeat::new>
 Returns	: none

=cut

sub _initialize {
   my($self,@args) = @_;
   my($spacers_no, $dr, $score) = $self->_rearrange( [qw(SPACERS_NO DR SCORE)], @args);
   $self->type('crispr');
   $self->spacers_no($spacers_no);
   $self->comments("Spacers=" . $self->spacers_no) if defined $self->spacers_no;
   $self->dr($dr);
   $self->comments("DR=" . $self->dr) if defined $self->dr;
   $self->score($score);
   $self->comments("Probable") if defined $self->score && $self->score < 60;
}

1;
