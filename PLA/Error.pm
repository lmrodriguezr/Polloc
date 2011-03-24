=head1 NAME

PLA::PLA::Error - Errors handler for the PLA::* packages

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package PLA::PLA::Error;

use strict;
use Error qw(:try);

@PLA::PLA::Error::ISA = qw( Error );


=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=over

=item -text

Text of the message

=item -value

Value or objected refered by the message

=back

=cut

sub new {
   my($class, @args) = @_;
   my($text, $value);
   if(@args % 2 == 0 && $args[0] =~ m/^-/){
      my %params = @args;
      $text = $params{'-text'};
      $value = $params{'-value'};
   }else{
      $text = $args[0];
      $value = $args[1];
   }

   if(defined $value && !$value){
      $value = length($value)==0 ? "\"\"" : "zero (0)";
   }

   my $self = $class->SUPER::new( -text=>$text, -value=>$value );
   return $self;
}

=head2 stringify

=cut

sub stringify {
   my($self, @args) = @_;
   return $self->error_msg(@args);
}

=head2 error_msg

=cut

sub error_msg {
   my($self,@args) = @_;
   my $msg = $self->text;

   my $value = $self->value; 
   my $bme = PLA::PLA::Root->new();
   my $out = " ".("-"x10)." ERROR ".("-"x10)." \n";
   if($msg=~/[\n]/){
      $msg=~s/([\n])/$1\t/g;
      $msg = "\n\t".$msg;
   }
   $out.= ref($self) . "\n";
   $out.= "MSG: $msg.\n";
   if(defined $value){
      if(ref($value)=~/hash/i){
         $out.= "VALUE: HASH: ".$_."=>".
	 	(defined $value->{$_} ? $value->{$_} : "undef" ).
		"\n" for keys %{$value};
      }elsif(ref($value)=~/array/i){
         $out.= "VALUE: ARRAY: ".join(", ",@{$value}) . "\n";
      }elsif($value=~/[\n]/){
         $value =~ s/([\n])/$1\t/g;
	 $out.= "VALUE:\n\t" . $value . "\n";
      }else{
         $out.= "VALUE: ".$value." - ".ref(\$value)."\n";
      }
   }
   $out.= " ".("."x27)." \n";
   $out.= $bme->stack_trace_dump();
   $out.= " ".("-"x27)." \n";
   return $out;
}

=head1 CHILDREN

Children objects included

=head2 PLA::PLA::IOException

I/O related error

=cut

@PLA::PLA::IOException::ISA = qw( PLA::PLA::Error );

=head2 PLA::PLA::ParsingException

Parsing error of some external file

=cut

@PLA::PLA::ParsingException::ISA = qw( PLA::PLA::Error );

=head2 PLA::PLA::LoudWarningException

Warning transformed into C<throw> due to a high verbosity

=cut

@PLA::PLA::LoudWarningException::ISA = qw( PLA::PLA::Error );

=head2 PLA::PLA::NotLogicException

=cut

@PLA::PLA::NotLogicException::ISA = qw( PLA::PLA::Error );

=head2 PLA::PLA::UnexpectedException

An error probably due to an internal bug

=cut

@PLA::PLA::UnexpectedException::ISA = qw( PLA::PLA::Error );

=head2 PLA::PLA::NotImplementedException

Error launched when a method is called from an object
not implementing it, despite it is defined by at least
one parent interface

=cut

@PLA::PLA::NotImplementedException::ISA = qw( PLA::PLA::Error );

1;
