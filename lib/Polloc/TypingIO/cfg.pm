=head1 NAME

Polloc::TypingIO::cfg - Implementation of Polloc::TypingIO for .cfg files

=head1 DESCRIPTION

Reads .cfg files (a.k.a. .bme files) and produces a L<Polloc::TypingIO>
object.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Polloc::TypingIO>

=back

=cut

package Polloc::TypingIO::cfg;

use strict;
use Polloc::Polloc::Config;
use Polloc::TypingI;

use base qw(Polloc::TypingIO);

=head1 APPENDIX

Methods provided by the package

=cut

=head2 new

Generic initialization method.

=head3 Arguments

=over

=item *

Any parameter accepted by L<Polloc::TypingIO>.

=item *

Any parameter accepted by L<Polloc::Polloc::Config>.

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 read

Configures and parses the file.

=cut

sub read {
   my($self,@args) = @_;
   $self->_cfg->_register_handle_function(
   		-obj=>$self,
		-fun=>"_parse_eval",
		-token=>".typing.eval");
   $self->_cfg->parse(@args);
}

=head2 value

Sets/gets a stored value.

=head3 Arguments

=over

=item -key

The key.

=item -value

The value (if any).

=item alert

If true, alerts if the key is not set.

=back

=head3 Returns

The value (mix).

=cut

sub value {
   my($self,@args) = @_;
   my($key,$value,$alert) = $self->_rearrange([qw(KEY VALUE ALERT)], @args);
   $self->_cfg->_save(-key=>$key, -value=>$value, -space=>"rule") if $value;

   # Search first in the Typing space
   $value = $self->_cfg->value(-key=>$key, -space=>"typing", -noalert=>1);
   return $value if defined $value;
   # Search in the root space otherwise
   return $self->_cfg->value(-key=>$key, -space=>".", -noalert=>!$alert);
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _cfg

Sets/gets the L<Polloc::Polloc::Config> main object.

=head3 Throws

L<Polloc::Polloc::Error> if the object is not of the proper class.

=cut

sub _cfg {
   my($self,$value) = @_;
   $self->{'_cfg_obj'} = $value if $value;
   return unless $self->{'_cfg_obj'};
   $self->{'_cfg_obj'}->isa('Polloc::Polloc::Config') or
   	$self->throw("Unexpected type of cfg object", $self->{'_cfg_obj'});
   return $self->{'_cfg_obj'};
}

=head2 _parse_eval

=cut

sub _parse_eval {
   my($self, $body,$defaults) = @_;
   $self->throw("Trying to define Polloc::TypingI object, but no type given")
   	unless defined $body;
   $body =~ s/^\s*(.*)\s*$/$1/;
   $body =~ s/^'\s*(.*)\s*'$/$1/;
   $body =~ m/^[a-z]+(::[a-z]+)*$/i
   	or $self->throw("Bad format for the body of .typing.eval, ".
			"expecting the type of typing", $body,
			'Polloc::Polloc::ParsingException');
   # Read arguments
   my %args = ();
   for my $k ($self->_cfg->all_keys('.typing')){
   	(my $name = $k) =~ s/^\.typing\.//;
	$name =~ s/^(?!-)/-/;
	$args{$name} = $self->value($k);
   }
   $args{'-type'} = $body;
   $self->typing(Polloc::TypingI->new(%args));
}

=head2 _parse_cfg

=cut

sub _parse_cfg {
   my($self,@args) = @_;
   $self->_cfg( Polloc::Polloc::Config->new(-noparse=>1, @args) );
   $self->_cfg->spaces(".typing");
   $self->read(@args);
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->_parse_cfg(@args);
}


1;
