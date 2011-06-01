=head1 NAME

Bio::Polloc::Locus::crispr - A CRISPR locus

=head1 DESCRIPTION

A CRISPR locus.  Implements L<Bio::Polloc::LocusI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::crispr;

use strict;
use base qw(Bio::Polloc::LocusI);


=head1 APPENDIX

Methods provided by the package

=head2 new

Creates a B<Bio::Polloc::Locus::repeat> object.

=head3 Arguments

=over

=item -spacers_no I<int>

The number of spacers.

=item -dr I<str>

Direct repeat sequence.

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 spacers_no

Gets/sets the number of spacers.

=head3 Arguments

The number of spacers (int, optional).

=head3 Returns

The number of spacers (int or undef).

=cut

sub spacers_no {
   my($self,$value) = @_;
   $self->{'_spacers_no'} = $value if defined $value;
   return $self->{'_spacers_no'};
}


=head2 dr

Sets/gets the Direct Repeat sequence.

=head3 Arguments

The direct repeat sequence (str, optional).

=head3 Returns

The direct repeat sequence (str or undef).

=cut

sub dr {
   my($self,$value) = @_;
   $self->{'_dr'} = $value if defined $value;
   return $self->{'_dr'};
}

=head2 score

Gets/sets the score.

=head3 Arguments

The score (float, optional).

=head3 Returns

The score (float or undef).

=cut

sub score {
   my($self,$value) = @_;
   $self->{'_score'} = $value+0 if defined $value;
   return $self->{'_score'};
}


=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

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
