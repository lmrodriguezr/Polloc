=head1 NAME

Polloc::LocusI - Interface of C<Polloc::Locus::*> objects

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Polloc::Polloc::Root>

=back

=cut

package Polloc::LocusI;

use strict;
use Polloc::RuleI;
use Polloc::Polloc::IO;
use List::Util qw(min max);

use base qw(Polloc::Polloc::Root);

=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $class = ref($caller) || $caller;
   
   if($class !~ m/Polloc::Locus::(\S+)/){
      my $bme = Polloc::Polloc::Root->new(@args);
      my($type) = $bme->_rearrange([qw(TYPE)], @args);
      
      if($type){
         $type = Polloc::LocusI->_qualify_type($type);
         $class = "Polloc::Locus::" . $type if $type;
      }
   }

   if($class =~ m/Polloc::Locus::(\S+)/){
      my $load = 0;
      if(Polloc::RuleI->_load_module($class)){
         $load = $class;
      }elsif(Polloc::RuleI->_load_module("Polloc::Locus::generic")){
         $load = "Polloc::Locus::generic";
      }
      
      if($load){
         my $self = $load->SUPER::new(@args);
	 $self->debug("Got the LocusI class $load");
	 my($from,$to,$strand,$name,$rule,$seq,$id, $family, $source, $comments, $genome) =
	 	$self->_rearrange(
	 		[qw(FROM TO STRAND NAME RULE SEQ ID FAMILY SOURCE COMMENTS GENOME)], @args);
	 $self->from($from);
	 $self->to($to);
	 $self->strand($strand);
	 $self->name($name);
	 $self->rule($rule);
	 $self->seq($seq);
	 $self->id($id);
	 $self->family($family);
	 $self->source($source);
	 $self->comments($comments);
	 $self->genome($genome);
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

=head2 type

Gets/sets the type of rule

=head3 Arguments

Value (str).  Can be: pattern, profile, repeat, similarity, coding. composition, crispr
Some variations can be introduced, like case variations or short versions like B<patt>
or B<rep>.

=head3 Return

Value (str).  The type of the rule, or null if undefined.  The value returned is undef
or a string from the above list, regardless of the input variations.

=head3 Throws

L<Polloc::Polloc::Error> if an unsupported type is received.

=cut

sub type {
   my($self,$value) = @_;
   if($value){
      my $v = $self->_qualify_type($value);
      $self->throw("Attempting to set an invalid type of locus",$value) unless $v;
      $self->{'_type'} = $v;
   }
   return $self->{'_type'};
}

=head2 genome

Sets/gets the source genome as a L<Polloc::Genome> object.

=head3 Throws

L<Polloc::Polloc::Error> if unexpected type.

=cut

sub genome {
   my($self,$value) = @_;
   $self->{'_genome'} = $value if defined $value;
   return unless defined $self->{'_genome'};
   $self->throw("Unexpected type of genome", $self->{'_genome'})
   	unless UNIVERSAL::can($self->{'_genome'},'isa') and $self->{'_genome'}->isa('Polloc::Genome');
   return $self->{'_genome'};
}

=head2 name

Sets/gets the name of the locus

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


=head2 aliases

Gets the alias names

=head3 Returns

Aliases (arr reference or undef)

=cut

sub aliases { return shift->{'_aliases'}; }


=head2 add_alias

=head3 Arguments

One or more alias names (str)

=cut

sub add_alias {
   my($self,@values) = @_;
   $self->{'_aliases'} ||= [];
   push(@{$self->{'_aliases'}}, @values);
}

=head2 parents

Gets the parent features or loci

=head3 Returns

Parents (arr reference or undef)

=cut

sub parents { return shift->{'_parents'}; }

=head2 add_parent

=head3 Arguments

One or more parent object (C<Polloc::LocusI>)

=head3 Throws

L<Polloc::Polloc::Error> if some argument is not L<Polloc::LocusI>

=cut

sub add_parent {
   my($self,@values) = @_;
   $self->{'_parents'} ||= [];
   for(@values){ $self->throw("Illegal parent class '".ref($_)."'",$_)
   	unless $_->isa('Polloc::LocusI') }
   push(@{$self->{'_aliases'}}, @values);
}

=head2 target

Gets/sets the target of the alignment, if the feature is some alignment

=head3 Arguments

=over

=item -id

The ID of the target sequence

=item -from

The start on the target sequence

=item -to

The end on the target sequence

=item -strand

The strand of the target sequence

=back

=head3 Returns

A hash reference like C<{B<id>=E<gt>id, B<from>=E<gt>from, B<to>=E<gt>to,
B<strand>=E<gt>strand}>

=cut

sub target {
   my($self,@args) = @_;
   if($#args>=0){
      my($id,$from,$to,$strand) = $self->_rearrange([qw(ID FROM TO STRAND)], @args);
      $self->{'_target'} = {'id'=>$id, 'from'=>$from, 'to'=>$to, 'strand'=>$strand};
   }
   return $self->{'_target'};
}

=head2 comments

Gets/sets the comments on the locus, newline-separated

=head3 Arguments

New comments to add (str)

=head3 Returns

Comments (str)

=cut

sub comments {
   my($self,@comments) = @_;
   if($#comments>=0){
      $self->{'_comments'} ||= "";
      for(@comments) { $self->{'_comments'} .= "\n" . $_ if defined $_ }
      $self->{'_comments'} =~ s/^\n+//;
      $self->{'_comments'} =~ s/\n+$//; #<- Just in case it gets an empty comment
   }
   return $self->{'_comments'};
}

=head2 xrefs

Gets the cross references of the locus

=head3 Returns

Array reference or undef

=cut

sub xrefs { return shift->{'_xrefs'} }

=head2 add_xref

Adds a cross reference

=head3 Arguments

One or more cross references in GFF3 format

=cut

sub add_xref {
   my $self = shift;
   $self->{'_xrefs'} ||= [];
   push @{$self->{'_xrefs'}}, @_ if $#_>=0;
}

=head2 ontology_terms_str

Gets the ontology terms as explicit strings

=head3 Returns

Array reference or undef

=cut

sub ontology_terms_str{ return shift->{'_ontology_terms_str'} }

=head2 add_ontology_term_str

Adds an ontology term by string

=head3 Arguments

One or more strings

=cut

sub add_ontology_term_str {
   my $self = shift;
   push @{$self->{'_ontology_terms_str'}}, @_ if $#_>=0;
}


=head2 from

Gets/sets the B<from> position

=head3 Arguments

Position (int, optional)

=head3 Returns

The B<from> position (int, -1 if undefined)

=cut

sub from {
   my($self,$value) = @_;
   $self->{'_from'} ||= -1;
   $self->{'_from'} = $value+0 if defined $value;
   return $self->{'_from'};
}


=head2 to

Gets/sets the B<to> position

=head3 Arguments

Position (int, optional)

=head3 Returns

The B<to> position (int, -1 if undefined)

=cut

sub to {
   my($self,$value) = @_;
   $self->{'_to'} ||= -1;
   $self->{'_to'} = $value+0 if defined $value;
   return $self->{'_to'};
}

=head2 id

Gets/sets the ID of the locus

=head3 Arguments

ID (str)

=head3 Returns

ID (str)

=cut

sub id {
   my($self,$value) = @_;
   $self->{'_id'} = $value if defined $value;
   return $self->{'_id'};
}


=head2 family

Sets/gets the family of features.  I<I.e.>, a name identifying the type of locus.
A common family is B<CDS>, but other families can be defined.  Note that the family
is not qualified by the software used for the prediction (use C<source()> for that).

=head3 Arguments

The family (str, optional)

=head3 Returns

The family (str)

=head3 Note

This method tries to locate the family by looking (in that order) at:

=over

=item 1

The explicitly defined family.

=item 2

The prefix of the ID (asuming it was produced by some L<Polloc::RuleI> object).

=item 3

The type of the rule (if the rule is defined).

=item 4

If any of the former options work, returns B<unknown>.

=back

=cut

sub family {
   my($self,$value) = @_;
   $self->{'_family'} = $value if defined $value;
   unless(defined $self->{'_family'} or not defined $self->id){
      if($self->id =~ m/(.*):\d+\.\d+/){
         $self->{'_family'} = $1;
      }
   }
   $self->{'_family'} = $self->rule->type if not defined $self->{'_family'} and defined $self->rule;
   return 'unknown' unless defined $self->{'_family'};
   return $self->{'_family'};
}

=head2 source

Sets/gets the source of the feature.  For example, the software used.

=head3 Arguments

The source (str, optional).

=head3 Returns

The source (str).

=head3 Note

This method tries to locate the source looking (in that order) at:

=over

=item 1

The explicitly defined value.

=item 2

The source of the rule (if defined).

=item 3

If any of the above, returns B<polloc>.

=back

=cut

sub source {
   my($self,$value) = @_;
   $self->{'_source'} = $value if defined $value;
   $self->{'_source'} = $self->rule->source
   	if not defined $self->{'_source'} and defined $self->rule;
   return 'polloc' if not defined $self->{'_source'};
   return $self->{'_source'};
}

=head2 strand

Gets/sets the strand

=head3 Arguments

Strand (str: B<+>, B<-> or B<.>)

=head3 Returns

The strand (str)

=cut

sub strand {
   my($self,$value) = @_;
   $self->{'_strand'} ||= '.';
   $self->{'_strand'} = $value if defined $value;
   return $self->{'_strand'};
}

=head2 rule

Gets/sets the origin rule

=head3 Arguments

A L<Polloc::RuleI> object

=head3 Returns

A L<Polloc::RuleI> object

=head3 Throws

L<Polloc::Polloc::Error> if the argument is not of the proper class

=cut

sub rule {
   my($self,$value) = @_;
   if(defined $value){
      $self->throw("Unexpected class of argument '".ref($value)."'",$value)
      		unless $value->isa('Polloc::RuleI');
      $self->{'_rule'} = $value;
   }
   return $self->{'_rule'};
}


=head2 score

Gets the score of the feature

=head3 Returns

The score (float)

=head3 Throws

L<Polloc::Polloc::NotImplementedException> if not implemented

=cut

sub score { $_[0]->throw("score",$_[0],"Polloc::Polloc::NotImplementedException") }


=head2 seq

Sets/gets the sequence

=head3 Arguments

The sequence (Bio::Seq object, optional)

=head3 Returns

The sequence (Bio::Seq object or undef)

=head3 Throws

L<Polloc::Polloc::Error> if the sequence is not Bio::Seq

=head3 Note

This method returns the full original sequence, not the piece of sequence with the target

=cut
sub seq {
   my($self,$seq) = @_;
   if(defined $seq){
      $self->throw("Illegal type of sequence", $seq) unless $seq->isa('Bio::Seq');
      $self->{'_seq'} = $seq;
   }
   return $self->{'_seq'};
}

=head2 gff3_line

Formats the line as GFF3 and returns it.

=head3 Arguments	

=over

=item -force

Boolean (1 or 0)

=back

=head3 Returns

The GFF3-formatted line (str)
=head3 Note

This function stores the line in cache.  If it is called twice, the second
time will return the cached line unless the C<-force=>1> flag is passed.

=cut
sub gff3_line {
   my($self,@args) = @_;
   my($force) = $self->_rearrange([qw(FORCE)], @args);
   return $self->{'_gff3_line'} if defined $self->{'_gff3_line'} and not $force;
   my @out;
   push @out, defined $self->seq ? $self->seq->display_id : ".";
   $out[0] =~ s/^>/{{%}}3E/;
   push @out, $self->source; #defined $self->rule ? $self->rule->source : 'bme';
   push @out, $self->family;
   push @out, $self->from , $self->to;
   push @out, defined $self->score ? $self->score : ".";
   push @out, $self->strand, "0";
   my %atts;
   $atts{'ID'} = $self->id if defined $self->id;
   $atts{'Name'} = $self->name if defined $self->name;
   $atts{'Alias'} = $self->aliases if defined $self->aliases;
   $atts{'Parent'} = $self->parents if defined $self->parents;
   if(defined $self->target){
      my $tid = $self->target->{'id'};
      $tid =~ s/\s/{{%}}20/g;
      $atts{'Target'} = $tid . " " . $self->target->{'from'} . " " . $self->target->{'to'};
   }
   # TODO Gap
   $atts{'Note'} = [split /[\n\r]+/, $self->comments] if defined $self->comments;
   $atts{'Dbxref'} = $self->xrefs if defined $self->xrefs;
   $atts{'Ontology_term'} = $self->ontology_terms_str if defined $self->ontology_terms_str;
   my $o = "";
   for my $v (@out){
      $o.= $self->_gff3_value($v)."\t";
   }
   $a = "";
   for my $k (keys %atts){
      $a .= "$k=" . $self->_gff3_attribute($atts{$k}).";";
   }
   $a = substr($a,0,-1) if $a;
   $self->{'_gff3_line'} = $o . $a . "\n";
   return $self->{'_gff3_line'};
}

=head2 stringify

=head3 Purpose

To provide an easy method for the (str) description of any L<Polloc::LocusI> object.

=head3 Returns

The stringified object (str, off course)

=cut

sub stringify {
   my($self,@args) = @_;
   my $out = ucfirst $self->type;
   $out.= " '" . $self->id . "'" if defined $self->id;
   $out.= " at [". $self->from. "..". $self->to . $self->strand ."]";
   return $out;
}

=head2 read_gff3

Reads a GFF3 file and returns an array of loci

=head3 Arguments

=over

=item -file

The file containing the GFF3

=item -fh

The file handler pointing to the GFF3 content

=item ...

Any other argument supported by L<Polloc::Polloc::IO-E<gt>new()>, such as C<-url>

=back

=head3 Returns

An array of L<Polloc::LocusI> objects

=head3 Note

Static function, call it as C<Polloc::LocusI->read_gff3>).

=head3 TODO

B<Still not functional!>

=cut

sub read_gff3 {
   my ($class,@args) = @_;
   my $io = Polloc::Polloc::IO->new(@args);
   my @feats;
   while(my $ln = $io->_readline){
      next if $ln =~ /^\s*#.*$/;
      next if $ln =~ /^\s*$/;
      my @row = split /\t/, $ln;
      my $seqid = $class->_gff3_decode($row[0]);
      my $source = $class->_gff3_decode($row[1]);
      my $family = $class->_gff3_decode($row[2]);
      my $from = $class->_gff3_decode($row[3]);
      my $to = $class->_gff3_decode($row[4]);
      my $score= $class->_gff3_decode($row[5]);
      my $strand = $class->_gff3_decode($row[6]);
      my $frame = $class->_gff3_decode($row[7]);
      my @compl = split /;/, $row[8];
      my($id,$name,$type,$comments);
      for my $c (@compl){
         # ID, Note, Name
      }
      $type = $family unless defined $type;
      my $ft = Polloc::LocusI->new(-type=>$type);
      # 
      # TODO
      # 
      push @feats, $ft;
   }
   return @feats;
}

=head2 context_seq

Extracts a sequence from the context of the locus

=head3 Arguments

All the following arguments are mandatory, and must be passed in that order:

=over

=item *

ref I<int> :
  -1 to use the start as reference (useful for upstream sequences),
  +1 to use the end as reference (useful for downstream sequences),
   0 to use the start as start reference and the end as end reference

=item *

from I<int> : The relative start position.

=item *

to I<int> : The relative end position.

=back

=head3 Returns

A L<Bio::Seq> object.

=cut

sub context_seq {
   my ($self, $ref, $from, $to) = @_;
   $self->_load_module('Polloc::GroupCriteria');
   return unless defined $self->seq and defined $self->from and defined $self->to;
   my $seq;
   my ($start, $end);
   my $revcom = 0;
   if($ref < 0){
      if($self->strand eq '?' or $self->strand eq '+'){
	 # (500..0)--------------->*[* >> ft >> ]
	 $start = $self->from - $from;	$end = $self->from - $to;
      }else{
	 # [ << ft << *]*<-----------------(500..0)
	 $start = $self->to + $to;	$end = $self->to + $from;	$revcom = !$revcom;
      }
   }elsif($ref > 0){
      if($self->strand eq '?' or $self->strand eq '+'){
	 # [ >> ft >> *]*<-----------------(500..0)
	 $start = $self->to + $to;	$end = $self->to + $from;	$revcom = !$revcom;
      }else{
	 # (500..0)--------------->*[* << ft << ]
	 $start = $self->from - $from;		$end = $self->from - $to;
      }
   }else{
      if($self->strand eq '?' or $self->strand eq '+'){
	 $start = $self->from + $from;	$end = $self->to + $from;
      }else{
	 $start = $self->to - $from;	$end = $self->from - $to;
      }
   }
   $start = max(1, $start);
   $end = min($self->seq->length, $end);
   $self->debug("Extracting context ".
   		(defined $self->seq->display_id?$self->seq->display_id:'').
		"[$start..$end] ".($revcom?"-":"+"));
   $seq = Polloc::GroupCriteria->_build_subseq($self->seq, $start, $end);
   return unless defined $seq;
   $seq = $seq->revcom if $revcom;
   return $seq;
}



=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Polloc::*

=head2 _gff3_attribute

Properly escapes an attribute for GFF3 (an attribute the value of one of
the colon-separated entries in the ninth column)

=head3 Purpose

To simplify the code of L<Polloc::LocusI::gff3_line>

=head3 Arguments

The value to escape

=head3 Returns

The escaped value

=cut

sub _gff3_attribute {
   my($self,$value) = @_;
   return unless defined $value;
   if(ref($value) && ref($value) =~ m/array/i){
      my $out = "";
      for my $att (@{$value}){
	 $out.= "," . $self->_gff3_value($att);
      }
      $out = substr($out, 1) if $out;
      return $out;
   }
   return $self->_gff3_value($value);
}

=head2 _gff3_value

Properly escapes a value on the GFF3 line.  I.e., the content of one column.
Not to be used with the ninth column, because scapes the colon. the comma and
the equals signs.  Use instead the L<Polloc::LocusI::_gff3_attribute()> function
attribute by attribute

=head3 Purpose

To simplify the code of L<Polloc::LocusI::gff3_line()>

=head3 Arguments

The value to escape

=head3 Returns

The escaped value

=cut

sub _gff3_value {
   my ($self,$value) = @_;
   return unless defined $value;
   $value =~ s/%/%25/g;
   $value =~ s/\{\{%25\}\}/%/g;
   $value =~ s/\t/%9/g;
   $value =~ s/\n/\%D/g;
   $value =~ s/\r/\%A/g;
   $value =~ s/;/%3B/g;
   $value =~ s/=/%3D/g;
   $value =~ s/&/%26/g;
   $value =~ s/,/%2C/g;
   $value =~ s/ /%20/g;
   return $value;
}

=head2 _gff_decode

Decodes the URI-fashioned values on GFF3

=head3 Arguments

The value to decode (str)

=head3 Returns

The decoded value (str)

=cut

sub _gff3_decode {
   my($self,$value) = @_;
   return unless defined $value;
   $value =~ s/%25/%/g;
   $value =~ s/%9/\t/g;
   $value =~ s/%D/\n/g;
   $value =~ s/%A/\r/g;
   $value =~ s/%3B/;/g;
   $value =~ s/%3D/=/g;
   $value =~ s/%26/&/g;
   $value =~ s/%2C/,/g;
   return $value;
}

=head2 _qualify_type

Uniformizes the distinct names that every type can receive

=head3 Arguments

The requested type (str)

=head3 Returns

The qualified type (str or undef)

=cut

sub _qualify_type {
   my($self,$value) = @_;
   return unless $value;
   $value = lc $value;
   $value = "pattern" if $value=~/^(patt(ern)?)$/;
   $value = "profile" if $value=~/^(prof(ile)?)$/;
   $value = "repeat" if $value=~/^(rep(eat)?)$/;
   $value = "similarity" if $value=~/^((sequence)?sim(ilarity)?|homology|ident(ity)?)$/;
   $value = "coding" if $value=~/^(cod|cds)$/;
   $value = "composition" if $value=~/^(comp(osition)?|content)$/;
   return $value;
   # TRUST IT! if $value =~ /^(pattern|profile|repeat|similarity|coding|composition|crispr)$/;
}

=head2 _initialize

=cut

sub _initialize {
   my $self = shift;
   $self->throw("_initialize", $self, "Polloc::Polloc::NotImplementedException");
}

1;
