=head1 NAME

Polloc::RuleI - Generic rules interface

=head1 DESCRIPTION

Use this interface to initialize the Polloc::Rule::* objects.  Any
rule inherits from this Interface.  Usually, rules are initialized
in sets (via the L<Polloc::RuleIO> package).

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Polloc::Polloc::Root>

=back

=cut

package Polloc::RuleI;

use strict;
use Polloc::RuleIO;

use base qw(Polloc::Polloc::Root);


=head1 APPENDIX

Methods provided by the package

=cut

=head2 new

Attempts to initialize a C<Polloc::Rule::*> object

=head3 Arguments

=over

=item -type

The type of rule

=item -value

The value of the rule (depends on the type of rule)

=item -context

The context of the rule.  See L<Polloc::RuleI->context()>.

=back

=head3 Returns

The C<Polloc::Rule::*> object

=head3 Throws

L<Polloc::Polloc::Error> if unable to initialize the proper object

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   # Pre-fix based on type, unless the caller is a proper class
   if($class !~ m/Polloc::Rule::(\S+)/){
      my $bme = Polloc::Polloc::Root->new(@args);
      my($type) = $bme->_rearrange([qw(TYPE)], @args);
      
      if($type){
         $type = Polloc::RuleI->_qualify_type($type);
         $class = "Polloc::Rule::" . $type if $type;
      }
   }

   # Try to load the object
   if($class =~ m/Polloc::Rule::(\S+)/){
      if(Polloc::RuleI->_load_module($class)){;
         my $self = $class->SUPER::new(@args);
	 $self->debug("Got the RuleI class $class ($1)");
	 my($value,$context,$name,$id,$executable) =
	 	$self->_rearrange([qw(VALUE CONTEXT NAME ID EXECUTABLE)], @args);
	 $self->value($value);
	 $self->context(@{$context});
	 $self->name($name);
	 $self->id($id);
	 $self->executable($executable);
         $self->_initialize(@args);
         return $self;
      }
      my $bme = Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   }

   # Throws exception if any previous return
   my $bme = Polloc::Polloc::Root->new(@args);
   $bme->throw("Impossible to load the proper Polloc::RuleI class with ".
   		"[".join("; ",@args)."]", $class);
}

=head2 type

=head3 Purpose

Gets/sets the type of rule

=head3 Arguments

Value (str).  Can be: pattern, profile, repeat, tandemrepeat, similarity, coding,
boolean, composition, crispr.  See the corresponding C<Polloc::Rule::*> objects
for further details.

Some variations can be introduced, like case variations or short versions like
B<patt> or B<rep>.

=head3 Return

Value (str).  The type of the rule, or C<undef> if undefined.  The value returned
is undef or a string from the above list, regardless of the input variations.

=head3 Throws

L<Polloc::Polloc::Error> if an unsupported type is received.

=cut

sub type {
   my($self,$value) = @_;
   if($value){
      my $v = $self->_qualify_type($value);
      $self->throw("Attempting to set an invalid type of rule",$value) unless $v;
      $self->{'_type'} = $v;
   }
   return $self->{'_type'};
}



=head2 context

The context is a reference to an array of two elements (int or str), the first being:
   1 => with respect to the start of the sequence
   0 => somewhere within the sequence (ignores the second)
  -1 => with respect to the end of the sequence

And the second being the number of residues from the reference point.  The second
value can be positive, negative, or zero.

=head3 Purpose

Gets/sets the context of the rule

=head3 Arguments

Three integers, or one integer equal to zero.  Please note that this function is
extremely tolerant, and tries to guess the context regardless of the input.

=head3 Returns

A reference to the array described above.

=cut

sub context {
   my($self,@args) = @_;
   if($#args>=0){
      $self->{'_context'} = [$args[0]+0, $args[1]+0, $args[2]+0];
   }
   $self->{'_context'} ||= [0,0,0];
   if($self->{'_context'}->[0] < 0) {$self->{'_context'}->[0] = -1;}
   elsif($self->{'_context'}->[0] > 0) {$self->{'_context'}->[0] = 1;}
   else {$self->{'_context'}->[0] = 0;}
   $self->{'_context'}->[1]+=0;
   return $self->{'_context'};
}

=head2 value

Gets/sets the value of the rule

=head3 Arguments

Value (mix)

=head3 Returns

Value (mix)

=head3 Note

This function relies on C<_qualify_value()>

=head3 Throws

L<Polloc::Polloc:Error> if unsupported value is received

=cut

sub value {
   my($self,$value) = @_;
   if(defined $value){
      my $v = $self->_qualify_value($value);
      defined $v or $self->throw("Bad rule value", $value);
      $self->{'_value'} = $v;
   }
   return $self->{'_value'};
}

=head2 executable

Sets/gets the B<executable> property.  A rule can be executed even if this
property is false, if the L<Polloc::RuleI::execute> method is called directly
(C<$rule->execute>) or by other rule.  This property is provided only for
L<Polloc::RuleIO> objects.

=head3 Arguments

Boolean (0 or 1; optional)

=head3 Returns

1 if expicilty executable, 0 otherwise

=head3 Note

It is advisable to have only few (ideally one) executable rules, handling
all the others with the rule type B<operation>

=cut

sub executable {
   my($self,$value) = @_;
   $self->{'_executable'} = $value+0 if defined $value;
   $self->{'_executable'} = $self->safe_value('executable')
   	unless defined $self->{'_executable'};
   $self->{'_executable'} =
   	(defined $self->{'_executable'} && $self->{'_executable'} =~ m/^(t|1|y)/i) ? 1 : 
		(defined $self->{'_executable'} ? 0 : undef);
   return $self->{'_executable'};
}


=head2 name

Sets/gets the name of the rule

=head3 Arguments

Name (str), the name to set

=head3 Returns

The name (str or undef)

=cut

sub name {
   my($self,$value) = @_;
   $self->{'_name'} = $value if defined $value;
   return $self->{'_name'};
}


=head2 id

Sets/gets the ID of the rule

=head3 Purpose

Provide a somewhat E<unique> but human-readable identifier

=head3 Arguments

The supposedly unique ID of the rule (str), any dot (B<.>) will be changed to B<_>

=head3 Returns

The ID (str or undef)

=cut

sub id {
   my($self,$value) = @_;
   if($value){
      $value =~ s/\./_/g;
      $self->debug("Setting Locus ID '$value'");
      $self->{'_id'} = $value;
   }
   return $self->{'_id'};
}

=head2 restart_index

=cut

sub restart_index {
   my $self = shift;
   $self->{'_children_id'} = 1;
}

=head2 stringify

=head3 Purpose

To provide an easy method for the (str) description of any Polloc::RuleI object.

=head3 Returns

The stringified object (str, off course)

=cut

sub stringify {
   my($self,@args) = @_;
   my $out = ucfirst $self->type;
   $out.= " '" . $self->name . "'" if defined $self->name;
   $out.= " at [". join("..", @{$self->context}) . "]" if $self->context->[0];
   $out.= ": ".$self->stringify_value if defined $self->value;
   return $out;
}

=head2 stringify_value

Dummy function to be overriten if non-string value like in Polloc::Rule::repeat

=head3 Returns

The value as string

=cut

sub stringify_value {
   my($self,@args) = @_;
   return "".$self->value(@args);
}

=head2 ruleset

Gets/sets the parent ruleset of the rule

=head3 Arguments

The ruleset to set (a L<Polloc::RuleIO> object).

=head3 Returns

A Polloc::RuleIO object or undef

=cut

sub ruleset {
   my($self,$value) = @_;
   if(defined $value){
      $self->throw("Unexpected type of value '".ref($value)."'",$value)
      		unless $value->isa('Polloc::RuleIO');
      $self->{'_ruleset'} = $value;
   }
   return $self->{'_ruleset'};
}

=head2 execute

=head3 Purpose

To evaluate the rule in a given sequence.

=head3 Arguments

A Bio::Seq object

=head3 Returns

An array of Polloc::LocusI objects

=head3 Throws

A L<Polloc::Polloc::NotImplementedException> if not implemented

=cut

sub execute {
   my $self = shift;
   $self->throw("execute", $self, "Polloc::Polloc::NotImplementedException");
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
   $self->{'_safe_values'} ||= {};
   return unless $param;
   $param = lc $param;
   if(defined $value){
      $self->{'_safe_values'}->{$param} = $value;
   }
   return $self->{'_safe_values'}->{$param};
}


=head2 source

Sets/gets the source of the annotation

=head3 Arguments

The source (str)

=head3 Returns

The source (str or undef)

=cut
sub source {
   my($self,$source) = @_;
   $self->{'_source'} = $source if defined $source;
   $self->{'_source'} ||= $self->type;
   return $self->{'_source'};
}

=head1 INTERNAL METHODS

Methods intended to be used only witin the scope of Polloc::*

=head2 _qualify_type

=cut

sub _qualify_type {
   my($self,$value) = @_;
   return unless $value;
   $value = lc $value;
   $value = "pattern" if $value=~/^(patt(ern)?)$/;
   $value = "profile" if $value=~/^(prof(ile)?)$/;
   $value = "repeat" if $value=~/^(rep(eat)?)$/;
   $value = "tandemrepeat" if $value=~/^(t(andem)?rep(eat)?)$/;
   $value = "similarity" if $value=~/^((sequence)?sim(ilarity)?|homology|ident(ity)?)$/;
   $value = "coding" if $value=~/^(cod|cds)$/;
   $value = "boolean" if $value=~/^(oper(at(e|or|ion))?|bool(ean)?)$/;
   $value = "composition" if $value=~/^(comp(osition)?|content)$/;
   return $value;
   # TRUST IT! -lrr if $value =~ /^(pattern|profile|repeat|tandemrepeat|similarity|coding|boolean|composition|crispr)$/;
}

=head2 _qualify_value

=cut

sub _qualify_value {
   my $self = shift;
   $self->throw("_qualify_value", $self, "Polloc::Polloc::NotImplementedException");
}

=head2 _initialize

=cut

sub _initialize {
   my $self = shift;
   $self->throw("_initialize", $self, "Polloc::Polloc::NotImplementedException");
}

=head2 _search_value

=head3 Arguments

The key (str)

=head3 Returns

The value (mix) or undef

=cut

sub _search_value {
   my($self, $key) = @_;
   return unless defined $key;
   $key = lc $key;
   return $self->{"_$key"}
   	if defined $self->{"_$key"};
   return $self->value->{"-$key"}
   	if defined $self->value
	and ref($self->value) =~ /hash/i
	and defined $self->value->{"-$key"};
   return $self->safe_value($key)
   	if defined $self->_qualify_value({"-$key"=>$self->safe_value($key)});
   return;
}

=head2 _next_child_id

Gets the ID for the next child.

=head3 Purpose

Provide support for children identification

=head3 Returns

The ID (str) or undef if the ID of the current Rule is not set.

=cut
sub _next_child_id {
   my $self = shift;
   return unless defined $self->id;
   $self->{'_children_id'} ||= 1;
   return $self->id . "." . $self->{'_children_id'}++;
}

1;
