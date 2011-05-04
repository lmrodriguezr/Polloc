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

=head2 graph_content

Generates the expected gel.  See L<Polloc::TypingI-E<gt>graph()>.

=cut

sub graph_content {
   my($self, $locigroup, $width, $height, $font) = @_;
   return unless defined $locigroup;
   return unless $self->_load_module('GD::Simple');
   
   # Set the gel up
   my $below = 50;
   my($iw, $ih, $nameh, $maxa) = ($width, $height-$below, 75, $self->max_size);
   my($lw, $lh, $nh) = ($iw/($#genomes+1), int($maxa/750), ($ih-$nameh)/$maxa);
   my $img = GD::Simple->new($width, $height);
   $img->bgcolor('black');
   $img->fgcolor('black');
   $img->rectangle(0, $nameh, $iw, $ih+$below);
   $img->font($font);
   my $white = $img->alphaColor(255,255,255,0);
   my $white = $img->alphaColor(255,255,255,0);
   my $b1 = $img->alphaColor(130, 130, 130 ,0);
   
   # ToDo .... use vntrsDiv.pl:89..122 code
   
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
