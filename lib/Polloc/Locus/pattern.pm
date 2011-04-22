=head1 NAME

Polloc::Locus::pattern - A loci matching a pattern.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Locus::pattern;

use strict;

use base qw(Polloc::LocusI);

=head1 APPENDIX

Methods provided by the package

=head2 new

Initialization method.

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
   my($self,@args) = @_;
   $self->type('pattern');
}

1;
