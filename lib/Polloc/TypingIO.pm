=head1 NAME

Polloc::TypingIO - I/O interface for genotyping methods (L<Polloc::TypingI>)

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Polloc::Polloc::Root>

=item *

L<Polloc::Polloc::IO>

=back

=cut

package Polloc::TypingIO;

use strict;
use base qw(Polloc::Polloc::Root Polloc::Polloc::IO);

=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=head3 Arguments

The same arguments of L<Polloc::Polloc::IO>, plus:

=over

=item -format

The format of the file

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Polloc::TypingIO::(\S+)/){
      my $bme = Polloc::Polloc::Root->new(@args);
      my($format,$file) = $bme->_rearrange([qw(FORMAT FILE)], @args);
      
      if(!$format && $file){
         $format = $file;
         $format =~ s/.*\.//;
      }
      if($format){
         $format = Polloc::TypingIO->_qualify_format($format);
         $class = "Polloc::TypingIO::" . $format if $format;
      }
   }

   if($class =~ m/Polloc::TypingIO::(\S+)/){
      if(Polloc::TypingIO->_load_module($class)){;
         my $self = $class->SUPER::new(@args);
	 $self->debug("Got the TypingIO class $class ($1)");
	 $self->format($1);
         $self->_initialize(@args);
         return $self;
      }
      my $bme = Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   } else {
      my $bme = Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the proper Polloc::TypingIO class with [".
      		join("; ",@args)."]", $class);
   }
}

=head2 format

Sets/gets the format.

=cut

sub format {
   my($self,$value) = @_;
   $value = $self->_qualify_format($value);
   $self->{'_format'} = $value if $value;
   return $self->{'_format'};
}

=head2 read

=cut

sub read {
   my $self = shift;
   $self->throw("read",$self,"Polloc::Polloc::NotImplementedException");
}


=head2 typing

Sets/gets the L<Polloc::TypingI> object

=head3 Arguments

A L<Polloc::TypingI> object (optional).

=head3 Returns

A L<Polloc::TypingI> object or C<undef>.

=head3 Throws

L<Polloc::Polloc::Error> if trying to set some value
other than a L<Polloc::TypingI> object.

=cut

sub typing {
   my($self, $value) = @_;
   if(defined $value){
      $self->throw('Unexpected object type', $value)
      		unless UNIVERSAL::can($value, 'isa')
		and $value->isa('Polloc::TypingI');
      $self->{'_typing'} = $value;
   }
   return $self->{'_typing'};
}

=head2 safe_value

Sets/gets a parameter of arbitrary name and value

=head3 Purpose

To provide a safe interface for setting values from the parsed file

=head3 Arguments

=over

=item -param

The parameter's name (case insensitive)

=item -value

The value of the parameter (optional)

=back

=head3 Returns

The value of the parameter or undef

=cut

sub safe_value {
   my ($self,@args) = @_;
   my($param,$value) = $self->_rearrange([qw(PARAM VALUE)], @args);
   $self->{'_values'} ||= {};
   return unless $param;
   $param = lc $param;
   if(defined $value){
      $self->{'_values'}->{$param} = $value;
   }
   return $self->{'_values'}->{$param};
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->throw("_initialize", $self, "Polloc::Polloc::NotImplementedException");
}

=head2 _qualify_format

=cut

sub _qualify_format {
   my($caller, $format) = @_;
   return unless $format;
   $format = lc $format;
   $format =~ s/[^a-z]//g;
   $format = "cfg" if $format =~ /^(conf|config|bme)$/;
   return $format;
   return;
}

1;
