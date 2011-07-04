=head1 NAME

Bio::Polloc::Locus::hybridization - A genomic location where a probe binds

=head1 DESCRIPTION

A location in the genome where a probe binds.

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::LocusI>.

=back

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::hybridization;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

=over

=item 

Creates a B<Bio::Polloc::Locus::repeat> object.

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 probe

=over

=item 

Gets/sets the probe used for the hybridization.

=back

=cut

sub probe {
   my($self, $value) = @_;
   my $k = '_probe';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 probeid

=over

=item 

Gets/sets the ID of the probe employed.  Useful when more than one probe is
used at the same hybridization spot, or when non-identical match is allowed.
If not provided, returns L<probe>.

=back

=cut

sub probeid {
   my($self, $value) = @_;
   my $k = '_probeid';
   $self->{$k} = $value if defined $value;
   $self->{$k} ||= $self->probe;
   return $self->{$k};
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($score, $probe, $probeid) = $self->_rearrange([qw(SCORE PROBE PROBEID)], @args);
   $self->score($score);
   $self->probe($probe);
   $self->probeid($probeid);
}

1;
