=head1 NAME

Polloc::Rule::pattern - A rule determined by a pattern

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Polloc::RuleI>

=back

=cut

package Polloc::Rule::pattern;

use strict;
use base qw(Polloc::RuleI);

=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _qualify_value

Implements the C<_qualify_value()> from the L<Polloc::RuleI> interface

=head3 Arguments

Value (str).

=head3 Return

Value (str or undef).

=cut

sub _qualify_value {
   my($self, $value) = @_;
   return unless $value;
   if( $value !~ /^[\w\[\]\(\)\{\}\d\*,]+$/i){
      $self->warn("Unexpected format for a pattern", $value);
      return;
   }
   return $value;
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->type('pattern');
}

1;
