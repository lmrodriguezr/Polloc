=head1 NAME

Polloc::Typing::bandingPattern - banding-pattern-based methods
for typing assessment

=head1 DESCRIPTION

Category 1 of genotyping methods in:

  Li, W., Raoult, D., & Fournier, P.-E. (2009).
  Bacterial strain typing in the genomic era.
  FEMS Microbiology Reviews, 33(5), 892-916.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Typing::bandingPattern;

use strict;
use GD::Simple;

use base qw(Polloc::TypingI);

=head1 APPENDIX

Methods provided by the package

=head2 new

Generic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head1 METHODS FROM Polloc::TypingI

=head2 scan

See L<Polloc::TypingI-E<gt>scan()>.

L<framents()> must be implemented by the C<Polloc::Typing::bandingPattern::*>
object.

=cut

sub scan {
   my($self, @args) = @_;
   my($locigroup) = $self->_rearrange([qw(LOCIGROUP)], @args);
   return $self->_scan_locigroup($self->fragments());
}

=head2 cluster

=head2 typing_value

See L<Polloc::TypingI-E<gt>typing_value()>.

Returns the size of the loci between the minimum (L<min_size())
and the maximum (L<max_size()) size.

=head3 Returns

A reference to an array of integers.

=cut

sub typing_value {
   my($self, @args) = @_;
   my($loci) = $self->_rearrange([qw(LOCI)], @args);
   $self->throw("Impossible to analyze loci", $loci)
   	unless defined $loci and ref($loci) and ref($loci)=~/ARRAY/i;
   my $out = [];
   for my $l (@$loci){
      my $size = abs($l->to - $l->from);
      push @$out, $size if $size<=$self->max_size and $size>=$self->min_size;
   }
   return $out;
}

=head1 SPECIFIC METHODS

=head2 fragments

Generates fragments.

=head3 Arguments

=over

=item -locigroup I<Polloc::LociGroup>

The group of loci to be used as base to design the protocol.

=back

=head3 Returns

A L<Polloc::LociGrop>, where each locus is a fragment.

=head3 Throws

A L<Polloc::Polloc::NotImplementedException> unless implemented
by the specific C<Polloc::Typing::bandingPattern::*> object.

=cut

sub fragments { $_[0]->throw("fragments", $_[0], "Polloc::Polloc::NotImplementedException") }

=head2 gel

Returns a L<GD::Simple> object containing the image of the
expected gel

=head3 Arguments

=over

=item -locigroup I<Polloc::LociGroup>

The group to be used as a basis.  If any, attempts to locate
the last value returned by L<scan()>.  If never called, looks
for the value stored via L<locigroup()> or at initialization.
Otherwise, warns about it and returns C<undef>,

=back

=head3 Returns

A L<GD::Simple> object.

=head3 Synopsis

    # ...
    $typing->scan($lociGroup);
    my $gel = $typing->gel;
    open IMG, ">", "gel.png" or die "I can not open gel.png: $!\n";
    binmode IMG;
    print IMG $gel->png;
    close IMG;

=cut

sub gel {
   my($self, @args) = @_;
   my($locigroup) = $self->_rearrange([qw(LOCIGROUP)], @args);
   $locigroup|| = $self->_scan_locigroup || $self->locigroup;
   unless($locigroup){
      $self->warn("Impossible to find a group of loci.");
      return;
   }
   # ToDo .... use vntrsDiv.pl code
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($minSize, $maxSize) = $self->_rearrange([qw(MINSIZE MAXSIZE)], @args);
   $self->type('bandingPattern');
   $self->min_size($minSize);
   $self->max_size($maxSize);
   $self->_initialize_method(@args);
}

=head2 _initialize_method

=cut

sub _initialize_method { }

1;
