=head1 NAME

Bio::Polloc::TypingI - Generic typing interface

=head1 DESCRIPTION

Use this interface to initialize the Bio::Polloc::Typing::* objects.  Any
rule inherits from this Interface.  Usually, rules are initialized
from files (via the L<Bio::Polloc::TypingIO> package).

=head1 AUTHOR - Luis M. Rodriguez-R

Email lrr at cpan dot org

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Polloc::Root>

=back

=cut

package Bio::Polloc::TypingI;
use strict;
use base qw(Bio::Polloc::Polloc::Root);
use Error qw(:try);
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=cut

=head2 new

Attempts to initialize a C<Bio::Polloc::Typing::*> object

B<Arguments>

=over

=item -type I<str>

The typing method.  For further description of the
different type, see:

  Li, W., Raoult, D., & Fournier, P.-E. (2009).
  Bacterial strain typing in the genomic era.
  FEMS Microbiology Reviews, 33(5), 892-916.

L<http://www.mendeley.com/research/bacterial-strain-typing-in-the-genomic-era/>.

One of:

=over

=item bandingPattern

"DNA banding pattern-based methods which classify bacteria
according to the size of fragments generated by amplification
and/or enzymatic digestion of genomic DNA" (Li I<et al> 2009)

=item bandingPattern::amplification

Same of C<bandingPattern>, but specifying fragments generated
B<by amplification>.

=item bandingPattern::restriction

Same of C<bandingPattern>, but specifying fragments generated
B<by enzymatic digestion>.

=item sequencing

"DNA sequencing-based methods, which study the polymorphism of
DNA sequences" (Li I<et al> 2009)

=item hybridization

"DNA hybridization-based methods using nucleotidic probes" (Li
I<et al> 2009)

=back

=item -locigroup I<Bio::Polloc::LociGroup object>

Group of loci (L<Bio::Polloc::LociGroup>) to be use for typing.

=back

B<Returns>

The C<Bio::Polloc::Typing::*> object

B<Throws>

L<Bio::Polloc::Polloc::Error> if unable to initialize the proper object

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   # Pre-fix based on type, unless the caller is a proper class
   if($class !~ m/Bio::Polloc::Typing::(\S+)/){
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      my($type) = $bme->_rearrange([qw(TYPE)], @args);
      
      if($type){
         $type = Bio::Polloc::TypingI->_qualify_type($type);
         $class = "Bio::Polloc::Typing::" . $type if $type;
      }
   }

   # Try to load the object
   if($class =~ m/Bio::Polloc::Typing::(\S+)/){
      if(Bio::Polloc::TypingI->_load_module($class)){;
         my $self = $class->SUPER::new(@args);
	 my($locigroup) = $self->_rearrange([qw(LOCIGROUP)], @args);
	 $self->debug("Got the TypingI class $class ($1)");
	 $self->locigroup($locigroup);
         $self->_initialize(@args);
         return $self;
      }
      my $bme = Bio::Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   }

   # Throws exception if any previous return
   my $bme = Bio::Polloc::Polloc::Root->new(@args);
   $bme->throw("Impossible to load the proper Bio::Polloc::TypingI class with ".
   		"[".join("; ",@args)."]", $class);
}

=head2 type

Gets/sets the type of typing method

B<Arguments>

Value (I<str>).  See L<new> and the corresponding C<Bio::Polloc::Typing::*>
objects for further details.

Some variations can be introduced, like case variations or short versions like
B<banding> or B<seq>.

B<Return>

Value (I<str>).  The typing method, or C<undef> if undefined.
The value returned is undef or a string from the above list, regardless of the
input variations.

B<Throws>

L<Bio::Polloc::Polloc::Error> if an unsupported type is received.

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

=head2 locigroup

Sets/gets the group of loci to be used.

B<Arguments>

A L<Bio::Polloc::LociGroup> object (optional).

B<Returns>

A L<Bio::Polloc::LociGroup> object or C<undef>.

=cut

sub locigroup {
   my($self, $value) = @_;
   $self->{'_locigroup'} = $value if defined $value;
   return $self->{'_locigroup'};
}

=head2 matrix

Generates a matrix of values for the given group of loci.

B<Arguments>

=over

=item -locigroup I<Bio::Polloc::LociGroup object>

The group of loci to be used as base.  If not provided,
attempts to find the last value returned by L<scan>.
If never called (or not cached by the implementation)
looks for the base loci (set via L<locigroup> or
at initialization).  If everything fails to provide a
base group of loci, warns about it and returns C<undef>.

=item -binary I<bool (int)>

If true, returns a binary matrix (presence/absence)
instead of the native typing value.

=item -names I<bool (int)>

If true, returns a hash with the names of the genomes as
keys instead of an array.

=back

B<Returns>

A reference to an array or a hash (if C<-names> is true).  The
key correspond to the incremental number or the name of the
genomes, and the values can be either numeric or an array of
numeric values, depending on the L<typing_value> implemented
by the genotyping method.  If C<-binary> is true, the values
are always 0 or 1, regardless of the typing method.

=cut

sub matrix { 
   my($self, @args) = @_;
   my($locigroup, $binary, $names) = $self->_rearrange([qw(LOCIGROUP BINARY NAMES)], @args);
   $locigroup ||= $self->_scan_locigroup();
   $locigroup ||= $self->locigroup();
   unless(defined $locigroup){
      $self->warn("Impossible to find the group of loci");
      return;
   }
   my $out = $locigroup->structured_loci;
   for my $g (0 .. $#$out){
      $out->[$g] = $binary ? (($#{$out->[$g]}>=0)+0) : $self->typing_value($out->[$g]);
   }
   return $out unless $names;
   my $outN = {};
   $outN->{$locigroup->genomes->[$_]->name} = $out->[$_] for (0 .. $#$out);
   return $outN;
}

=head2 binary

Alias of L<matrix> with C<-binary> true.

=cut

sub binary {
   my($self, @args) = @_;
   return $self->matrix(-binary=>1, @args);
}

=head2 graph

Returns a L<GD::Simple> object containing the graphic representation
of the typing results.

B<Arguments>

=over

=item -locigroup I<Bio::Polloc::LociGroup>

The group to be used as a basis.  If any, attempts to locate
the last value returned by L<scan>.  If never called, looks
for the value stored via L<locigroup> or at initialization.
Otherwise, warns about it and returns C<undef>,

=item -width I<int>

Width of the image in pixels.  600 by default.

=item -height I<int>

Height of the image in pixels.  300 by default.

=item -font I<str>

Font of the text in the image (if any).  'Times' by default, but
certain images require a TrueType Font in order to work properly.
This argument is optional, but we strongly recommend to provide
the path to Lucida Sans Regular, or any other similar TrueType
Font.

=back

B<Returns>

A L<GD::Simple> object.

B<Synopsis>

    # ...
    $typing->scan($lociGroup);
    my $graph = $typing->graph(-font=>'/path/to/LucidaSansRegular.ttf');
    if($graph){
       open IMG, ">", "graph.png" or die "I can not open graph.png: $!\n";
       binmode IMG;
       print IMG $graph->png;
       close IMG;
    }

=cut

sub graph {
   my($self, @args) = @_;
   my($locigroup, $width, $height, $font) = $self->_rearrange([qw(LOCIGROUP WIDTH HEIGHT FONT)], @args);
   $locigroup ||= $self->_scan_locigroup || $self->locigroup;
   unless($locigroup){
      $self->warn("Impossible to find a group of loci.");
      return;
   }
   try { $self->_load_module('GD::Simple'); }
   catch Bio::Polloc::Polloc::Error with {
      $self->warn("I need GD::Simple to create the image, impossible to locate it.\n".shift);
      return;
   } otherwise { $self->throw("Non-native error", shift); };
   $width  ||= 600;
   $height ||= 300;
   $font   ||= 'Times';
   return $self->graph_content($locigroup, $width, $height, $font, @args);
}

=head1 METHODS TO BE IMPLEMENTED

Methods that should be implemented by objects using this
interface as base.  All the methods in this section can
throw L<Bio::Polloc::Polloc::NotImplementedException> if not
implemented.

=head2 scan

Scans the genomes using the specified loci as base.

B<Arguments>

=over

=item -locigroup I<Bio::Polloc::LociGroup>

Loci to use as genotyping base.  Optional if provided via
L<locigroup> or at initialization.

=back

B<Returns>

A L<Bio::Polloc::LociGroup> object containing the actual loci
employed for typing.

=cut

sub scan { $_[0]->throw("scan", $_[0], "Bio::Polloc::Polloc::NotImplementedException") }

=head2 cluster

Clusters the genomes based on the provided loci.

B<Arguments>

=over

=item -locigroup I<Bio::Polloc::LociGroup object>

The base group of loci.  Same behavior as L<matrix>.

=back

B<Returns>

A L<Bio::Tree> object.

=cut

sub cluster { $_[0]->throw("cluster", $_[0], "Bio::Polloc::Polloc::NotImplementedException") }

=head2 typing_value

Provides a value for the passed loci associated with
the typing method.

B<Arguments>

=over

=item -loci I<Array of Bio::Polloc::LocusI>

The loci to be evaluated.  Note that it is a reference array
of L<Bio::Polloc::LocusI> objects, and B<NOT> a L<Bio::Polloc::LociGroup>.
This is because all the loci are expected to be part of the
same genome, and the same group (if grouped).  This argument
is mandatory.

=back

B<Returns>

A numeric value or a reference to an array of numeric values,
depending on the genotyping method.

=cut

sub typing_value {
   $_[0]->throw("typing_value", $_[0], "Bio::Polloc::Polloc::NotImplementedException")
}

=head1 INTERNAL METHODS

Methods intended to be used only witin the scope of Bio::Polloc::*

=head2 _qualify_type

=cut

sub _qualify_type {
   my($self,$value) = @_;
   return unless $value;
   $value = lc $value;
   $value = "bandingPattern" if $value=~/^banding(?:patt(?:ern)?)?$/;
   $value = "bandingPattern::amplification"
   	if $value=~/^banding(?:patt(?:ern)?)?::ampl(?:if(?:ication)?)?$/;
   $value = "bandingPattern::restriction"
   	if $value=~/^banding(?:patt(?:ern)?)?::rest(?:r(?:iction)?)?$/;
   $value = "sequencing" if $value=~/^seq(?:uenc(?:e|ing))?$/;
   $value = "hibridization" if $value=~/^hib(?:ridization)?$/;
   return $value;
}

=head2 _scan_locigroup

Gets/sets the group of loci after scanning.  This should be
called at the end of all the implementations of L<scan>.

=cut

sub _scan_locigroup {
   my($self,$value) = @_;
   $self->{'_scan_locigroup'} = $value if defined $value;
   return $self->{'_scan_locigroup'};
}

=head2 _initialize

=cut

sub _initialize {
   my $self = shift;
   $self->throw("_initialize", $self, "Bio::Polloc::Polloc::NotImplementedException");
}

1;
