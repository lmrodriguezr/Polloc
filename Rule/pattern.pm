package PLA::Rule::pattern;

use strict;

use base qw(PLA::RuleI);

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




=head2 _qualify_value
 Purpose	: Implements the _qualify_value from the PLA::RuleI interface
 Arguments	: Value (str)
 Return		: Value (str or undef)
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

1;
