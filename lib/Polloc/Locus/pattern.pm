package Polloc::Locus::pattern;

use strict;

use base qw(Polloc::LocusI);

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

sub _initialize {
   my($self,@args) = @_;
   $self->type('pattern');
}

1;
