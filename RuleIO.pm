=head1 NAME

Polloc::RuleIO - I/O interface for the sets of rules (L<Polloc::RuleI>)

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

package Polloc::RuleIO;

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
   
   if($class !~ m/Polloc::RuleSet::(\S+)/){
      my $bme = Polloc::Polloc::Root->new(@args);
      my($format,$file) = $bme->_rearrange([qw(FORMAT FILE)], @args);
      
      if(!$format && $file){
         $format = $file;
         $format =~ s/.*\.//;
      }
      if($format){
         $format = Polloc::RuleIO->_qualify_format($format);
         $class = "Polloc::RuleSet::" . $format if $format;
      }
   }

   if($class =~ m/Polloc::RuleSet::(\S+)/){
      if(Polloc::RuleIO->_load_module($class)){;
         my $self = $class->SUPER::new(@args);
	 $self->debug("Got the RuleIO class $class ($1)");
	 $self->format($1);
         $self->_initialize(@args);
         return $self;
      }
      my $bme = Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   } else {
      my $bme = Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the proper Polloc::RuleIO class with [".
      		join("; ",@args)."]", $class);
   }
}

=head2 prefix_id

Sets/gets the prefix ID, unique for the RuleSet

=head3 Purpose

To allow the identification of children in a unique namespace

=head3 Arguments

A string, supposedly unique.  Any colon (:) will be changed to '_'

=head3 Returns

The prefix ID.

=cut

sub prefix_id {
  my($self,$value) = @_;
  if(defined $value && "$value"){ #<- to avoid empty string ('') but allow zero (0)
     $value =~ s/:/_/g;
     $self->{'_prefix_id'} = "$value";
  }
  # Attempt to set from the parsed values if not explicitly setted
  $self->{'_prefix_id'} = $self->safe_value('prefix_id') unless defined $self->{'_prefix_id'};
  return $self->{'_prefix_id'};
}

=head2 init_id

=cut

sub init_id {
   my($self,$value) = @_;
   $self->{'_init_id'} = $value if defined $value;
   $self->{'_init_id'} ||= 1;
   return $self->{'_init_id'};
}

=head2 format

=cut

sub format {
   my($self,$value) = @_;
   $value = $self->_qualify_format($value);
   $self->{'_format'} = $value if $value;
   return $self->{'_format'};
}



=head2 add_rule

Appends rules to the rules set.

=head2 Arguments

One or more L<Polloc::RuleI> objects

=head2 Returns

The index of the last rule

=head2 Throws

A L<Polloc::Polloc::Error> exception if some object is not a L<Polloc::RuleI>

=cut

sub add_rule {
   my($self, @rules) = @_;
   return unless $#rules >= 0;
   $self->get_rules; #<- to initialize the array if does not exist
   for my $rule (@rules){
      $self->throw("Trying to add an illegal class of Rule", $rule)
      		unless $rule->isa('Polloc::RuleI');
      $rule->ruleset($self);
      push @{$self->{'_registered_rules'}}, $rule;
   }
   return $#{$self->{'_registered_rules'}};
}


=head2 get_rule

Gets the rule at the given index

=head3 Arguments

The index (int)

=head3 Returns

A L<Polloc::RuleI> object or undef

=cut

sub get_rule {
   my($self,$index) = @_;
   return unless defined $index;
   return if $index < 0;
   return if $index > $#{$self->get_rules};
   return $self->get_rules->[$index];
}

=head2 get_rules

=cut

sub get_rules {
   my($self, @args) = @_;
   $self->{'_registered_rules'} ||= [];
   return $self->{'_registered_rules'};
}

=head2 next_rule

=head3 Returns

A L<Polloc::RuleI> object

=cut
sub next_rule {
   my($self, @args) = @_;
   my $rule = $self->get_rule($self->{'_loop_index_rules'} || 0);
   $self->{'_loop_index_rules'}++;
   $self->_end_rules_loop unless $rule;
   return $rule;
}

=head2 grouprules

Sets/gets the grouprules objects.

=head3 Arguments

A L<Polloc::GroupRules> array ref (optional)

=head3 Returns

A L<Polloc::GroupRules> array ref or undef

=cut

sub grouprules {
   my($self,$value) = @_;
   $self->{'_grouprules'} = $value if defined $value;
   return $self->{'_grouprules'};
}

=head2 addgrouprules

Adds a grouprules object

=head3 Arguments

A L<Polloc::GroupRules> object

=head3 Throws

A L<Polloc::Polloc::Error> if not a proper object

=cut

sub addgrouprules {
   my($self,$value) = @_;
   $self->throw("Illegal grouprules object",$value) unless $value->isa("Polloc::GroupRules");
   $self->{'_grouprules'} = [] unless defined $self->{'_grouprules'};
   push @{$self->{'_grouprules'}}, $value;
}



=head2 execute

Executes the executable rules only

=head3 Arguments

Any argument supported/required by the rules.  C<-seq> is always required

=head3 Returns

A reference to an array of L<Polloc::FeatureI> objects

=cut

sub execute {
   my($self, @args) = @_;
   $self->debug("Evaluating executable rules");
   my($prefix) = $self->_rearrange([qw(PREFIX)], @args);
   $self->_end_rules_loop; # A (perhaps) paranoid precaution
   my @feats = ();
   while ( my $rule = $self->next_rule ){
      $self->debug("On " . $self->{'_loop_index_rules'});
      if($rule->executable){
         $self->debug("RUN!");
         push @feats, @{$rule->execute(@args)};
      }
   }
   return wantarray ? @feats : \@feats;
}

=head2 increase_index

=cut

sub increase_index {
   my $self = shift;
   while ( my $rule = $self->next_rule ){
      my $nid = $self->_next_child_id;
      $rule->id($nid) if defined $nid;
      $rule->restart_index;
   }
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


=head2 parameter

=head3 Purpose

Gets/sets some generic parameter.  It is intended to provide an
interface between L<Polloc::RuleIO>'s general configuration and
L<Polloc::RuleI>, regardless of the format.

=head3 Arguments

The key (str) and the value (mix, optional)

=head3 Returns

The value (mix or undef)

=head3 Throws

A L<Polloc::Polloc::NotImplementedException> if not implemented

=cut

sub parameter {
   my $self = shift;
   $self->throw("parameter",$self,"Polloc::Polloc::NotImplementedException");
}

=head2 read

=cut

sub read {
   my $self = shift;
   $self->throw("read",$self,"Polloc::Polloc::NotImplementedException");
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _register_rule_parse

=cut

sub _register_rule_parse {
   my $self = shift;
   $self->throw("_register_rule_parse",$self,"Polloc::Polloc::NotImplementedException");
}

=head2 _next_child_id

=cut

sub _next_child_id {
   my $self = shift;
   return unless defined $self->prefix_id;
   $self->{'_next_child_id'} ||= $self->init_id;
   return $self->prefix_id . ":" . ($self->{'_next_child_id'}++);
}

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
   $format = "cfg" if $format =~ /^(conf|config|bme)$/;
   return $format if $format =~ /^(cfg)$/;
   return;
}

=head2 _end_rules_loop

=cut

sub _end_rules_loop { shift->{'_loop_index_rules'} = 0 }

1;
