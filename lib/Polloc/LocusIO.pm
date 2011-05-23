=head1 NAME

Polloc::LocusIO - I/O interface of C<Polloc::Locus::*> objects

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Polloc::Polloc::Root>

=item *

L<Polloc::Polloc::IO>

=back

=head1 SYNOPSIS

Read & write loci:

    use strict;
    use Polloc::LocusIO;

    my $locusI = Polloc::LocusIO->new(-file=>"t/loci.gff3", -format=>"gff3");
    my $locusO = Polloc::LocusIO->new(-file=>">out.gff3", -format=>"gff3");

    while(my $locus = $locusI->next_locus){
       print "Got a ", $locus->type, " from ", $locus->from, " to ", $locus->to, "\n";
       # Filter per type
       if($locus->type eq "repeat"){
          $locusO->write_locus($locus);
       }
    }

=cut

package Polloc::LocusIO;

use strict;

use base qw(Polloc::Polloc::Root Polloc::Polloc::IO);

=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Polloc::LocusIO::(\S+)/){
      my $bme = Polloc::Polloc::Root->new(@args);
      my($format, $file) = $bme->_rearrange([qw(FORMAT FILE)], @args);

      ($format = $file) =~ s/^.*\.// if $file and not $format;
      if($format){
         $format = __PACKAGE__->_qualify_format($format);
         $class = "Polloc::LocusIO::" . $format if $format;
      }
   }

   if($class =~ m/Polloc::LocusIO::(\S+)/){
      my $load = 0;
      if(__PACKAGE__->_load_module($class)){
         $load = $class;
      }
      
      if($load){
         my $self = $load->SUPER::new(@args);
	 $self->debug("Got the LocusIO class $load");
         $self->_initialize(@args);
         return $self;
         
      }
      
      my $bme = Polloc::Polloc::Root->new(@args);
      $bme->throw("Impossible to load the module", $class);
   }
   my $bme = Polloc::Polloc::Root->new(@args);
   $bme->throw("Impossible to load the proper Polloc::LocusI class with ".
   		"[".join("; ",@args)."]", $class);
}

=head2 format

Gets/sets the format of the file

=head3 Arguments

Format (str), currently supported: gff3.

=head3 Return

Format (str or C<undef>).

=cut

sub format {
   my($self,$value) = @_;
   if($value){
      my $v = $self->_qualify_format($value);
      $self->throw("Attempting to set an invalid type of locus",$value) unless $v;
      $self->{'_format'} = $v;
   }
   return $self->{'_format'};
}

=head2 write_locus

Appends one locus to the output file.

=head2 Arguments

=over

=item -locus I<Polloc::LocusI>, mandatory

The locus to append.

=item -force I<Bool (int)>

If true, forces re-parsing of the locus.  Otherwise,
tries to load cached parsing (if any).

=cut

sub write_locus {
   my($self, @args) = @_;
   my($locus) = $self->_rearrange([qw(LOCUS)], @args);
   $self->throw("You must provide the locus to append") unless defined $locus;
   $self->throw("The obtained locus is not an object", $locus)
   	unless UNIVERSAL::can($locus, 'isa');
   $self->_write_locus_impl(@args);
}

=head2 read_loci

Gets the loci stored in the input file.

=head3 Arguments

=over

=item -genomes I<arrayref of Polloc::Genome objects>

An arrayref containing the L<Polloc::Genome> objects associated to
the collection of loci.  This is not mandatory, but C<seq> and
C<genome> properties will not be set on the newly created objects
if this parameter is not provided.

=back

=head3 Returns

A L<Polloc::LociGroup> object.

=cut

sub read_loci { return shift->_read_loci_impl(@_) }

=head2 next_locus

Reads the next locus in the buffer.

=head3 Arguments

Same of L<read_loci()>

=back

=head3 Returns

A L<Polloc::LocusI> object.

=cut

sub next_locus { return shift->_next_locus_impl(@_) }

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _qualify_format

Uniformizes the distinct names that every format can receive

=head3 Arguments

The requested format (str)

=head3 Returns

The qualified format (str or undef)

=cut

sub _qualify_format {
   my($self,$value) = @_;
   return unless $value;
   $value = 'gff3' if $value =~ /^gff3?$/i;
   $value = lc $value;
   return $value;
}

=head2 _write_locus_impl

Format-specific implementation of C<write_locus()>.

=cut

sub _write_locus_impl {
   $_[0]->throw("_write_locus_impl", $_[0], 'Polloc::Polloc::UnimplementedException');
}

=head2 _read_loci_impl

Format-specific implementation of C<next_locus>.

=cut

sub _read_loci_impl {
   my ($self,@args) = @_;
   my $group = Polloc::LociGroup->new();
   while(my $locus = $self->next_locus(@args)){
      $group->add_locus($locus);
   }
   return $group;
}

=head2 _next_locus_impl

=cut

sub _next_locus_impl {
   $_[0]->throw("_next_locus_impl", $_[0], 'Polloc::Polloc::UnimplementedException');
}

=head2 _save_locus

=cut

sub _save_locus {
   my($self, $locus) = @_;
   $self->{'_saved_loci'}||= [];
   push @{$self->{'_saved_loci'}}, $locus if defined $locus;
   return $locus;
}

=head2 _locus_by_id

=cut

sub _locus_by_id {
   my($self, $id) = @_;
   return unless defined $id;
   my @col = grep { $_->id eq $id } @{$self->{'_saved_loci'}};
   return $col[0];
}

=head2 _initialize

=cut

sub _initialize {
   my $self = shift;
   $self->_initialize_io(@_);
}

1;
