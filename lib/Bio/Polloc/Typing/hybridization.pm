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
use Bio::Seq;
use Bio::Polloc::LociGroup;
use Bio::Polloc::LocusI;
use List::Util qw(reduce);
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
   defined $locigroup or $self->throw("Impossible to find a locigroup");
   return $self->_scan_locigroup($self->_plot_loci_fx($locigroup)) if $self->function  eq 'plot_loci';
   return $self->_scan_locigroup($self->_search_loci_fx($locigroup)) if $self->function eq 'search_loci';
   return $self->_scan_locigroup($self->_get_probes_fx($locigroup)) if $self->function eq 'get_probes';
   $self->throw("Unsupported function", $self->function, 'Bio::Polloc::Polloc::UnexpectedException');
}

=head2 cluster

=head2 typing_value

See L<Bio::Polloc::TypingI-E<gt>typing_value>.

Returns the score.  If applied over a locigroup returned by L<scan>,
it is 1 for presence or 0 for absence.  Eventual values ranging from zero
to one can be implemented in future versions, aimed to reflect imperfect
match (for example, the identity).

=cut

sub typing_value {
   my ($self, @args) = @_;
   my($loci) = $self->_rearrange([qw(LOCI)], @args);
   $self->throw("Impossible to analyze loci", $loci)
   	unless defined $loci and ref($loci) and ref($loci)=~/ARRAY/i;
   return [ map { $_->score } @$loci ];
}

=head2 graph_content

Generates the graphical representation of the dot-plot matrix.  See
L<Bio::Polloc::TypingI-E<gt>graph>.

=cut

sub graph_content {
   my($self, $locigroup, $width, $height, $font, @args) = @_;
   return unless defined $locigroup;
   return unless $self->_load_module('GD::Simple');
   
   # Prepare data
   my $genomes = $locigroup->genomes;
   $self->throw("You must define the genomes of the loci group in order to create a dotplot matrix")
   	unless defined $genomes;
   my ($struc, $names) = $self->_arrange_grid($locigroup);

   # Set the matrix up
   my ($nameh, $namev, $rightm, $bottomm) = (150, 120, 5, 5);
   my ($ix, $iy, $nh, $nv) = ($nameh, $namev, $#$names+1, $#$genomes+1);
   my ($iw, $ih) = ($width-$nameh-$rightm, $height-$namev-$bottomm);
   my ($lw, $lh) = ($iw/$nh, $ih/$nv);
   my $img = GD::Simple->new($width, $height);
   $img->bgcolor('white');
   $img->fgcolor('black');
   $img->rectangle($ix, $iy, $ix+$iw, $iy+$ih);
   $img->font($font);
   my $negative = $img->alphaColor(255, 255, 255, 0);
   my $positive = $img->alphaColor(  0,   0,   0, 0);
   $self->debug("DOTPLOT iw:$iw ih:$ih namev:$namev nameh:$nameh lw:$lw lh:$lh nh:$nh nv:$nv");

   # Draw rows
   for my $g (0 .. $#$struc){
      $img->fgcolor('black');
      $img->moveTo(int($nameh*0.1), int($namev + (($g+0.3)*$ih/$nv)));
      $img->fontsize(8);
      $img->string($genomes->[$g]->name);
   }

   # Draw columns
   for my $col (0 .. $#$names){
      my $n = $names->[$col];
      my $xName = int($nameh + (($col+1)*$iw/$nh));
      $img->moveTo($xName, int($namev*0.9));
      $img->fgcolor('black');
      $img->fontsize(8);
      $img->angle(-90);
      $img->string($n);
      $img->angle(0);

      # Draw spots
      GENOME: for my $g (0 .. $#$struc){
	 my $y1 = int($namev + (($g+0.1)*$ih/$nv));
	 my $y2 = $y1+int(0.8*$lh);
         LOCUS: for my $lk (0 .. $#{$struc->[$g]}){
	    my $l = $struc->[$g]->[$lk];
	    if($l->can('probeid') and $n eq $l->probeid){
	       my $x1 = int($nameh + (($col+0.1)*$iw/$nh));
	       my $x2 = $x1 + int(0.8*$lw);
	       $img->bgcolor($l->score ? $positive : $negative);
	       $img->fgcolor('black');
	       $img->rectangle($x1, $y1, $x2, $y2);
	       if($l->from > 0){
		  $img->fontsize(8);
		  $img->fgcolor('white');
		  $img->moveTo($x2, $y2);
		  $img->angle(-90);
		  $img->string($l->from."..".$l->to);
		  $img->angle(0);
	       }
	       next GENOME;
	    }
	 }
      }
   }
   return $img;
}

=head1 SPECIFIC METHODS

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

=head2 probe_size

=over

=item 

The expected size of the probe.  Use C<undef> or zero to trigger the default
behavior (see L<function>).

=item Arguments

An I<int> in nucleotides.

=back

=cut

sub probe_size {
   my ($self, $value) = @_;
   $self->{'_probe_size'} = $value+0 if defined $value;
   return $self->{'_probe_size'};
}

=head2 loci_probes

A I<str>, must be a valid method in the expected locus.

=cut

sub loci_probes {
   my ($self, $value) = @_;
   $self->{'_loci_probes'} = $value if defined $value;
   return $self->{'_loci_probes'};
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _plot_loci_fx

=cut

sub _plot_loci_fx {
   my ($self, $locigroup) = @_;
   return $locigroup;
}

=head2 _search_loci_fx

=cut

sub _search_loci_fx {
   my ($self, $locigroup) = @_;
   my $genomes = $locigroup->genomes;
   $self->throw("Please define the genomes in the locigroup", $locigroup) unless defined $genomes;
   my $out = Bio::Polloc::LociGroup->new(-genomes=>$genomes);
   GENOME: for my $genome (@$genomes){
      LOCUS: for my $locus (@{$locigroup->loci}){
	 SEQ: for my $seq (@{$genome->get_sequences}){
	    my $probes = {};
	    my $probeids = [];
	    if($self->loci_probes){
	       my $f = $self->loci_probes;
	       my $probes_ch = {};
	       my $probeidk = 0;
	       for my $locus (@{$locigroup->locus}){
	          $self->throw("Unsupported loci_probes function", $f) if $locus->can($f);
	          for my $probe ( @{ $locus->$f } ){
		     unless($probes_ch->{$probe} or $probes_ch->{Bio::Seq->new(-seq=>$probe)->revcom->seq}){
		        my $probeid = ''.($locus->id || '').'/'.(++$probeidk);
			$probes->{$probeid} = $probe;
			$probes_ch->{$probe} = 1;
			push @$probeids, $probeid;
		     }
		  }
	       }
	    }else{
	       $probeids = [''.($locus->id || '').'/1'];
	       my $probe = uc $locus->seq->subseq($locus->from, $locus->to);
	       $probe = substr $probe,
	       		int(0.5*($locus->length-$self->probe_size)),
			int(0.5*($locus->length+$self->probe_size))
			if $self->probe_size;
	       $probes = { $probeids->[0] => $probe }
	    }
	    PROBE: for my $probeid (@$probeids){
	       my $qF = $probes->{$probeid};
	       my $qR = uc Bio::Seq->new(-seq=>$qF)->revcom->seq;
	       my $t = uc $seq->seq;
	       $qF =~ s/[^A-Z]//g;
	       $qR =~ s/[^A-Z]//g;
	       $t  =~ s/[^A-Z]//g;
	       my $index = index $t, $qF;
	       my $strand = $index>=$[ ? $locus->strand : $locus->strand eq '+' ? '-' : $locus->strand eq '-' ? '+' : '.';
	       $index = index $t, $qR unless $index >= $[;
	       my %par = (-genome=>$genome, -type=>'hybridization', -probe=>$qF, -probeid=>$probeid, -seq=>$seq);
	       if($index >= $[){
		  $out->add_locus(Bio::Polloc::LocusI->new(
			-from=>pos(),
			-to=>pos()+length($1),
			-strand=>$strand,
			-score=>1,
			%par,
		     ));
	       }else{
		  $out->add_locus(Bio::Polloc::LocusI->new(
			-score=>0,
			%par,
		     ));
	       }
	    } #PROBE
	 } #SEQ
      } #LOCUS
   } #GENOME
   return $out;
}

=head2 _get_probes_fx

=cut

sub _get_probes_fx {
   my ($self, $locigroup) = @_;
   my $out = Bio::Polloc::LociGroup->new(-genomes=>$locigroup->genomes);
   $self->throw("You must define loci_probes, probe_size or both in order to use the get_probes function")
   		unless $self->loci_probes or $self->probe_size;
   
   # Get the probes
   my $probes = {}; # name -> seq
   my $probeids = [];
   if($self->loci_probes){
      $self->debug("Getting probes from method ".$self->loci_probes);
      my $f = $self->loci_probes;
      my $probes_ch = {};
      LOCUS: for my $locus (@{$locigroup->loci}){
         $self->throw("Unsupported loci_probes function", $f) unless $locus->can($f);
	 $self->debug("Getting probes from ".$locus->id);
	 # ToDo: Sort them intelligently!
	 my $locus_probes = $locus->$f;
	 PROBE: for my $pk (0 .. $#$locus_probes){
	    (my $p = uc $locus_probes->[$pk]) =~ s/[^A-Za-z]//g;
	    unless($probes_ch->{$p} or $probes_ch->{Bio::Seq->new(-seq=>$p)->revcom->seq}){
	       my $probeid = ''.($locus->id || '').'/'.$pk;
	       $probes->{$probeid} = $p;
	       push @$probeids, $probeid;
	       $probes_ch->{$p} = 1;
	    }
	 }
      }
   }else{
      my $probes_ch = {};
      LOCUS: for my $locus (@{$locigroup->loci}){
         my $seq = $locus->seq->subseq($locus->from, $locus->to);
	 POSITION: for my $i (0 .. int($locus->length / $self->probe_size)){
	    my $p = uc substr($seq, $i*$self->probe_size, ($i+1)*$self->probe_size);
	    $p =~ s/[^A-Z]//g;
	    unless($probes_ch->{$p} or $probes_ch->{Bio::Seq->new(-seq=>$p)->revcom->seq}){
	       my $probeid = ''.($locus->id || '').'/'.$i;
	       $probes->{$probeid} = $p;
	       push @$probeids, $probeid;
	       $probes_ch->{$p} = 1;
	    }
	 }
      }
   }

   # Hybridize
   $self->debug("Scanning loci with ".($#$probeids+1)." probes");
   LOCUS: for my $locus (@{$locigroup->loci}){
      my $t = $locus->seq->subseq($locus->from, $locus->to);
      my $probek = 0;
      PROBE: for my $probeid (@$probeids){
	 my $qF = $probes->{$probeid};
	 my $qR = Bio::Seq->new(-seq=>$qF)->revcom->seq;
	 my $index = index $t, $qF;
	 my $strand = $index>=$[ ? $locus->strand : $locus->strand eq '+' ? '-' : $locus->strand eq '-' ? '+' : '.';
	 $index = index $t, $qR unless $index >= $[;
	 my %par = (-type=>'hybridization', -probe=>$qR, -probeid=>$probeid, -genome=>$locus->genome, -seq=>$locus->seq);
	 if($index >= $[){
	    $out->add_locus(Bio::Polloc::LocusI->new(
		  -from=>$locus->from + $index,
		  -to=>$locus->from + $index + length $qF,
		  -strand=>$strand,
		  -score=>1,
		  %par,
	       ));
	 }else{
	    $out->add_locus(Bio::Polloc::LocusI->new(
		  -score=>0,
		  %par,
	       ));
	 }
      } #PROBE
   } #LOCUS
   $out->arrange_by_location;
   return $out;
}

=head2 _arrange_grid

=over

=item Note

This function relies on an ordered list of loci (per location, or whatever the order you want
to reflect).  Use something like C<$locigroup-E<gt>arrange_by_location> before calling this
method.

=back

=cut

sub _arrange_grid {
   my ($self, $locigroup) = @_;

   $self->debug("Getting unique probe names");
   my $names = [];
   my $names_ch = {};
   for my $l (@{$locigroup->loci}){
      if($l->can('probeid')){
	 push @$names, $l->probeid unless $names_ch->{$l->probeid};
	 $names_ch->{$l->probeid}=1;
      }
   }

   $self->debug("Ordering probes");
   my $S = $locigroup->structured_loci;
   for my $g (0 .. $#$S){
      $S->[$g] = [map {$_->probeid} @{$S->[$g]}];
   }
   my $i = 0; my $list = []; my $visited = {};
   my $list = [];
   REF: while(1){
      # If the i-th row is already empty, start again from the topmost non-empty one
      unless(defined $S->[$i]->[0]){
	 for($i=0; $i <= $#$S+1 and defined $S->[$i] and not defined $S->[$i]->[0]; $i++){ }
      }
      # If the i-th row is still empty, it's because I'm done
      last REF unless defined $S->[$i]->[0];
      # Eval if the first element of the i-th row is suitable
      $visited->{$i} = 1;
      TARGET: for my $k (0 .. $#$S){
         # Continue if the k-th row is empty or the first element is identical to the first from the i-th row
	 next TARGET if not defined $S->[$k]->[0] or $S->[$i]->[0] eq $S->[$k]->[0];
	 # If k has not being reference (in this round), and the first element of i-th row is a non-first element in the k-th
	 my @inS = grep { $_ eq $S->[$i]->[0] } @{$S->[$k]};
	 if(not $visited->{$k} and $#inS>=0){
	    # Use k as reference, and try again
	    $self->debug("Jumping from $i to $k");
	    $i = $k;
	    next REF;
	 }
      }
      # Save element, clean other rows and restart round
      push @$list, $S->[$i]->[0];
      $self->debug("Saving first probe at $i (".$S->[$i]->[0].") and cleaning rows");
      for my $a (0 .. $#$S){
	 $S->[$a] = [ grep { $_ ne $S->[$i]->[0] } @{$S->[$a]} ];
	 $self->debug("    $a: ".join(" ", @{$S->[$a]}));
      }
      $visited = {};
   }
   
   #$self->debug("Building the ordered matrix");
   #my $struc = [];
   #GENOME: for my $g (0 .. $#{$locigroup->genomes}){
   #   my $gn = $locigroup->genomes->[$g]->name;
   #   $struc->[$g] = [];
   #   PROBE: for my $p (0 .. $#$list){
   #      my $pn = $list->[$p];
#	 my @loci = grep { $_->genome->name eq $gn and $_->can('probeid') and $_->probeid eq $pn } @{$locigroup->loci};
#	 $self->warn("More than one loci in genome $g ($gn) with probe $p ($pn), using first only") if $#loci > 0;
#	 $struc->[$g]->[$p] = $loci[0] unless $#loci==-1;
   #   }
   #}
   return ($locigroup->structured_loci, $list);
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($probesize, $function, $lociprobes) = $self->_rearrange([qw(PROBE_SIZE FUNCTION LOCI_PROBES)], @args);
   $self->probe_size($probesize);
   $self->function($function);
   $self->loci_probes($lociprobes);
}

1;

