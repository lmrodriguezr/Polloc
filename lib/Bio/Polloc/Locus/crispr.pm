=head1 NAME

Bio::Polloc::Locus::crispr - A CRISPR locus

=head1 DESCRIPTION

A CRISPR locus.  Implements L<Bio::Polloc::LocusI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::crispr;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

=over

=item 

Creates a B<Bio::Polloc::Locus::repeat> object.

=item Arguments

=over

=item -spacers_no I<int>

The number of spacers.

=item -dr I<str>

Direct repeat sequence.

=back

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 spacers_no

=over

=item 

Gets/sets the number of spacers.

=item Arguments

The number of spacers (int, optional).

=item Returns

The number of spacers (int or undef).

=back

=cut

sub spacers_no {
   my($self,$value) = @_;
   $self->{'_spacers_no'} = $value if defined $value;
   return $self->{'_spacers_no'};
}


=head2 dr

=over

=item 

Sets/gets the Direct Repeat sequence.

=item Arguments

The direct repeat sequence (str, optional).

=item Returns

The direct repeat sequence (str or undef).

=back

=cut

sub dr {
   my($self,$value) = @_;
   $self->{'_dr'} = $value if defined $value;
   return $self->{'_dr'};
}

=head2 score

=over

=item 

Gets/sets the score.

=item Arguments

The score (float, optional).

=item Returns

The score (float or undef).

=back

=cut

sub score {
   my($self,$value) = @_;
   $self->{'_score'} = $value+0 if defined $value;
   return $self->{'_score'};
}

=head2 add_spacer

=over

=item 

Adds information for an spacer.

=item Arguments

=over

=item -from I<int>

Where the spacer starts.  This is a coordinate on the whole genome (or defined global sequence),
B<NOT> with respect to the CRISPR.

=item -to I<int>

Where the spacer ends.  This is a coordinate on the whole genome (or defined global sequence).
B<NOT> with respect to the CRISPR.

=item -raw_seq I<str>

Optional parameter to set the raw sequence of the spacer.  If not provided, it is calculated based
on the coordinates.  If no global sequence is set, it remains undefined.

=back

=back

=cut

sub add_spacer {
   my($self, @args) = @_;
   my ($from, $to, $raw_seq) = $self->_rearrange([qw(FROM TO RAW_SEQ)], @args);
   return unless defined $from and defined $to;
   $self->{'_spacers'} ||= [];
   push @{$self->{'_spacers'}}, {from=>$from, to=>$to, raw_seq=>$raw_seq};
}

=head2 spacers

=over

=item 

Gets/sets the spacers as an I<arrayref> of I<hashrefs> with keys C<from>, C<to> and C<raw_seq>.
When setting, C<raw_seq> keys can be safely ignored.  Also, it can be set from string, with the
format:

    1..7,19..25, ...

This is, regions separeted by comma (or space or semi-colon) each with the coordinates C<from> and C<to>
separated by two (or three) dots.  Each region can contains additional data (like the raw sequence)
after a colon, for example:

    1..7:AGCATGC,19..25:GCATGTC, ...

=item Arguments

I<str>, I<arrayref> of I<hashrefs> (with keys C<from> and C<to>), or I<arrayref> of I<arrayrefs>
(Each with two values, indicating the coordinates C<from> and C<to>).

=back

=cut

sub spacers {
   my ($self, $value) = @_;
   if(defined $value){
      $value = [map { [split /(?:\.\.\.?|:)/, $_, 2] } split /[,; ]/, $value] unless ref $value;
      my $o = [];
      for my $v (@$value){ push @$o, (ref $v eq 'HASH' ? $v : {from=>$v->[0], to=>$v->[1]}) }
      $self->{'_spacers'} = [];
      $self->add_spacer(-from=>$_->{from}, -to=>$_->{to}) for @$o;
   }
   $self->{'_spacers'}||= [];
   for my $i (0 .. $#{$self->{'_spacers'}}){
      $self->{'_spacers'}->[$i]->{'raw_seq'} =
      	$self->seq->subseq($self->{'_spacers'}->[$i]->{'from'}, $self->{'_spacers'}->[$i]->{'to'})
	if defined $self->seq and not defined $self->{'_spacers'}->[$i]->{'raw_seq'};
   }
   return $self->{'_spacers'};
}

=head2 spacers_location_str

=over

=item 

Gets the location string as defined in L<spacers>.

=back

=cut

sub spacers_location_str { return join ' ', map { $_->{from}.'..'.$_->{to} } @{shift->spacers} }

=head2 spacers_str

=over

=item *

Gets an arrayref with the strings of the spacer sequences.

=back

=cut

sub spacers_str {
   my $self = shift;
   return unless defined $self->spacers;
   return [ map { $_->{raw_seq} } @{$self->spacers} ];
}

=head2 repeats

=over

=item 

Gets the repeats as an I<arrayref> of I<hashrefs> with keys C<from> and C<to>.  The actual
sequence of the repeats can be retrieved using L<dr>.  There is no way to directly
set the coordinates of the repeats, instead, you must set the coordinates of the
L<spacers>.

=back

=cut

sub repeats {
   my $self = shift;
   return [] unless $self->spacers;
   my @froms = sort map { $_->{from}+0 } @{$self->spacers};
   my @tos = sort map { $_->{to}+0 } @{$self->spacers};
   my $from = $self->from;
   my $out = [];
   while(@froms){
      my $sp_f = shift @froms;
      push @$out, {from=>$from, to=>$sp_f} if $sp_f > $from;
      $from = shift(@tos) + 1;
   }
   push @$out, {from=>$from, to=>$self->to} if $out->[$#$out] < $self->to;
   return $out;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($spacers_no, $dr, $score, $spacers) = $self->_rearrange( [qw(SPACERS_NO DR SCORE SPACERS)], @args);
   $self->type('crispr');
   $self->spacers_no($spacers_no);
   $self->comments("Spacers_no=" . $self->spacers_no) if defined $self->spacers_no;
   $self->dr($dr);
   $self->comments("DR=" . $self->dr) if defined $self->dr;
   $self->score($score);
   $self->comments("questionable structure") if defined $self->score && $self->score < 60;
   $self->spacers($spacers);
   $self->comments("Spacers=" . $self->spacers_location_str) if $self->spacers_location_str;
}

1;
