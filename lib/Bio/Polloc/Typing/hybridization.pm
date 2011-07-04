=head1 NAME

Bio::Polloc::Typing::hybridization - hybridization-based methods
for typing assesment.

=head1 DESCRIPTION

Category 3 of genotyping methods in:

  Li, W., Raoult, D., & Fournier, P.-E. (2009).
  Bacterial strain typing in the genomic era.
  FEMS Microbiology Reviews, 33(5), 892-916.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lrr at cpan dot org

=cut

package Bio::Polloc::Typing::hybridization;
use base qw(Bio::Polloc::TypingI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 PUBLIC METHODS

=head2 new

=over

=item Arguments

Same as L<Bio::Polloc::TypingI>, plus:

=over

=item -probesize I<int>

Size of the probe, in nucleotides, see L<probe_size>.

=item -function I<str>

Function for searching, see L<function>.

=back

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head1 METHODS FROM Bio::Polloc::TypingI

=head2 scan

=over

=item *

Scans the genomes (or a region) using probes.  Different flavors are
available (see L<function> for further details).

=back

=cut

sub scan {
   my($self, @args) = @_;
   my($locigroup) = $self->_rearrange([qw(LOCIGROUP)], @args);
   $locigroup ||= $self->locigroup;
   return $self->_scan_locigroup($self->_plot_loci_fx(-locigroup=>$locigroup)) if $self->function  eq 'plot_loci';
   return $self->_scan_locigroup($self->_search_loci_fx(-locigroup=>$locigroup)) if $self->function eq 'search_loci';
   return $self->_scan_locigroup($self->_get_probes_fx(-locigroup=>$locigroup)) if $self->function eq 'get_probes';
   $self->throw("Unsupported function", $self->function, 'Bio::Polloc::Polloc::UnexpectedException');
}

=head2 function

=over

=item *

Gets/sets the function that determines how to scan the given data.

=item Arguments

One of the following strings:

=over

=item search_loci

Scans the input genomes searching for the given loci.  B<Caution> this is an inefficient
process, and similar results are better achivied with a combination of a previous search
and the function C<plot_loci>.  Supports the definition of sub-locus regions using a
locus-specific function (see L<loci_probes>).  If the probe size is defined and not zero
(see L<probe_size>) uses the center-most region with that length as probe.  Due to its
low requirements and generic definition, B<this is the default> function (despite its
problems).

=item plot_loci

Basically does not perform a search.  Instead, trusts the presence/absence of loci in the
genomes list.  Useful to generate plots without relying on C<search_loci>.  If
L<loci_probes> is not defined, throws an exception.

=item get_probes

Gets probes from the loci and scans the loci, not the full genomes.  This is useful for
methods using amplified DNA, not genomic DNA, like the spoligotyping.  If defined, uses
the L<loci_probes> to get the probes from the loci.  If not, uses the L<probe_size> to
break the locus in chunks of that given size.  If neither is defined, throws an exception.

=back

=back

=cut

sub function {
   my($self, $value) = @_;
   if(defined $value){
      $value = lc $value;
      $value =~ s/[ \.\-]+/_/g;
      $self->{'_function'} = $value if $value =~ /^(?:search_loci|plot_loci|get_probes)$/;
   }
   $self->{'_function'} ||= 'search_loci';
   return $self->{'_function'};
}


=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($probesize, $function) = $self->_rearrange([qw(PROBESIZE FUNCTION)], @args);
   $self->probe_size($probesize);
   $self->function($function);
}

1;

