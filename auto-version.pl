#!/usr/bin/perl -w

use strict;
use Bio::Polloc::Polloc::Version;
use File::Copy;
use File::Spec;

sub auto_version($){
   my $path = shift;
   my $v = $Bio::Polloc::Polloc::Version::VERSION;
   print "Versioning $path\n";
   if(-d $path){
      opendir (my $Dh, $path) or die "I can not open '$path': $!\n";
      my @files = readdir $Dh;
      closedir $Dh;
      for my $f (@files){
	 &auto_version(File::Spec->catfile($path, $f)) if $f !~ /^\.\.?$/;
      }
   }else{
      open IN, "<", $path or die "I can not read '$path': $!\n";
      open OUT, ">", ".tmp" or die "I can not write in '.tmp': $!\n";
      while(<IN>){
         s/^our \$VERSION = .*; # \[a-version\].*/our \$VERSION = $v; # [a-version] from Bio::Polloc::Polloc::Version/;
	 print OUT $_;
      }
      close IN;
      close OUT;
      copy ".tmp", $path or die "I can not copy .tmp in $path: $!\n";
      unlink ".tmp";
   }
}

&auto_version('lib');

