=head1 NAME

Polloc::Locus::generic - An unknown feature

=head1 DESCRIPTION

A feature loaded by some external source, but not directly created by
some L<Polloc::RuleI> object.  Implements L<Polloc::LocusI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Locus::generic;

use strict;
use base qw(Polloc::LocusI);


=head1 APPENDIX

Methods provided by the package

=head2 new

Creates a B<Polloc::Locus::repeat> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _initialize

=cut

sub _initialize {
   # my($self,@args) = @_;
   # Do nothing ;-), just to avoid the unimplemented error.
}

1;
