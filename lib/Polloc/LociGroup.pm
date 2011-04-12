=head1 NAME

Polloc::LociGroup - A group of loci

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Polloc::Polloc::Root>

=back

=cut

package Polloc::LociGroup;

use strict;
use Polloc::Polloc::IO;
use base qw(Polloc::Polloc::Root);

=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 add_locus

Alias of C<add_loci()>

=cut

sub add_locus { return shift->add_loci(@_) }

=head2 add_loci

Adds loci to the collection on the specified
genome's space

=head3 Throws

A L<Polloc::Polloc::Error> if an argument is not
a L<Polloc::LocusI> object.

=head3 Arguments

The first argument B<MUST> be the identifier of
the genome's space (int).  All the following are
expected to be L<Polloc::LocusI> objects.

=cut

sub add_loci {
   my $self = shift;
   my $space = 0+shift;
   $self->{'_loci'} = [] unless defined $self->{'_loci'};
   $self->{'_loci'}->[$space] = [] unless defined $self->{'_loci'}->[$space];
   for my $locus (@_){
      $self->throw('Expecting a Polloc::LocusI object', $locus)
      	unless UNIVERSAL::can($locus, 'isa') and $locus->isa('Polloc::LocusI');
      push @{ $self->{'_loci'}->[$space] }, $locus;
   }
}

=head2 loci

Gets the loci

=cut

sub loci {
   my $self = shift;
   my @out = ();
   for my $space ($self->structured_loci){ push @out, @$space }
   return wantarray ? @out : \@out;
}

=head2 structured_loci

Returns a two-dimensional array where the first key corresponds
to the number of the genome space and the second key is an
incremental for each locus.

=cut

sub structured_loci {
   my $self = shift;
   return wantarray ? @{$self->{'_loci'}} : $self->{'_loci'};
}

=head2 locus

Get a locus by ID

=head3 Arguments

The ID of the locus (str).

=cut

sub locus {
   my ($self, $id) = @_;
   for my $locus ($self->loci){ return $locus if $locus->id eq $id }
   return;
}

=head2 name

Gets/sets the name of the group.  This is supposed
to be unique!

=head3 Note

Future implementations could assume unique naming
for getting/setting/initializing groups of loci
by name.

=cut

sub name {
   my ($self, $value) = @_;
   $self->{'_name'} = $value if defined $value;
   return $self->{'_name'};
}

=head2 genomes

Gets/sets the genomes to be used as analysis base.

=head3 Arguments

A reference to an array of L<Polloc::Genome> objects.

=cut

sub genomes {
   my($self, $value) = @_;
   $self->{'_genomes'} = $value if defined $value;
   return wantarray ? @{$self->{'_genomes'}} : $self->{'_genomes'};
}


=head2 featurename

Gets/Sets the name of the feature common to all the
loci in the group.

=cut

sub featurename {
   my ($self, $value) = @_;
   $self->{'_featurename'} = $value if defined $value;
   return $self->{'_featurename'};
}

=head2 export_gff3

Exports the list of loci to the specified file or file handler

=head3 Arguments

Any argument accepted by Polloc::Polloc::IO->new()

=head3 Returns

The L<Polloc::Polloc::IO> object handling the output.

=cut

sub export_gff3 {
   my $self = shift;
   my $gff = Polloc::Polloc::IO->new(@_);
   $gff->_print("##gff-version 3\n\n");
   for my $locus ($self->loci){
      $gff->_print($locus->gff3_line);
   }
   $gff->close();
   return $gff;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my ($self, @args) = @_;
   my($name, $featurename, $genomes) = $self->_rearrange([qw(NAME FEATURENAME GENOMES)], @args);
   $self->name($name);
   $self->featurename($featurename);
   $self->genomes($genomes);
}

1;
