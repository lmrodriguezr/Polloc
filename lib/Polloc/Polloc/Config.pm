=head1 NAME

Polloc::Polloc::Config - Handles .cfg files

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Polloc::Polloc::Config;

use strict;

use base qw(Polloc::Polloc::Root Polloc::Polloc::IO);

=head1 GLOBALS

Global variables controling the behavior of the package

=cut

our($CFGMAXDEPTH, $CFGCURDEPTH);

=head2 CFGMAXDEPTH

Maximum depth of variables replacement

=cut

$CFGMAXDEPTH = 7 unless defined $CFGMAXDEPTH;

=head2 CFGCURDEPTH

Current depth of replacement (internal var)

=cut

$CFGCURDEPTH = 0;

=head1 APPENDIX

Methods provided by the package

=head2 new

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 parse

=cut

sub parse {
   my($self,@args) = @_;

   $CFGCURDEPTH = 0;
   my $onspace = "";
   my @spaces = @{$self->spaces};
   $self->debug("The fine art of parsing (".$self->resource.")...");
   while(my $line = $self->_readline){
      $line = $self->_filter_line($line);
      next if $line =~ /^\s*$/;
      if($line =~ m/^\[\s*([\w\.]+)\s*\]$/){
         # [ space ]
	 $self->debug("[$onspace] Space: $line");
	 $onspace = $self->_parse_space($1);
      }elsif( !$self->_space_required($onspace) ){
         # Ignore space
	 $self->debug("[$onspace] Ignored: $line");
	 next;
      }elsif($line =~ m/^([\w\.]+)\s*=\s*(.*)$/){
	 $self->debug("[$onspace] Key-value pair: $line");
         # key = value
	 $self->_save(-space=>$onspace, -key=>$1, -value=>$2);
      }elsif($line =~ m/^([\w\.]+)(\s+(.*))?$/){
	 $self->debug("[$onspace] Token: $line");
         # token body || token
	 # Note that 'key = value' also fits this expresion because body
	 # is anything, but it has been already ruled out.
	 $self->_execute_token(-space=>$onspace, -token=>$1, -body=>$3);
      }else{
         $self->throw("Unable to parse configuration file ".$self->file,
	 		$line, "Polloc::Polloc::IOException");
      }
   }
   $self->close();
   $self->_reparse();
   $self->_execute_postparse();
}

=head2 spaces

=cut

sub spaces {
   my $self = shift;
   $self->{'_spaces'} = ['.'] unless defined $self->{'_spaces'};
   while ( my $a = shift ) {
      for my $s (@{ ref($a) =~ /array/i ? $a : [$a] }){
         push @{$self->{'_spaces'}}, $self->_parse_space($s);
      }
   }
   return $self->{'_spaces'};
}

sub _filter_line {
   my($self,$line) = @_;

   chomp($line);
   $line =~ s/^#.*//;
   $line =~ s/\s#.*//;
   $line =~ s/^\s+//;
   $line =~ s/\s+$//;

   return $line;
}

sub _save {
   my($self,@args) = @_;
   my($space,$key,$value) = $self->_rearrange([qw(SPACE KEY VALUE)], @args);
   return unless $key;
   
   # Parse key
   $key = $self->_parse_key(-space=>$space, -key=>$key);
   
   # Parse value
   if( !$value ){
      $value = "";
   }elsif($value =~ m/^(true|false)$/i){
      $value = ("true" eq lc $value);
   }elsif($value =~ m/^[\d\.Ee+\-]+$/){
      $value += 0;
   }elsif($value =~ m/^'(.*)'$/){
      $value = $1;
      $value =~ s/\$\{/\$\\{/;
   }elsif($value =~ m/^"(.*)"$/ ){
      $value = $1;
      push @{$self->{'_reparse'}}, $key if $value =~ /\$\{[\w\.]+\}/;
   }else{
      $self->throw("Bad value on configuration file ".$self->resource,
      		$value, "Polloc::Polloc::IOException");
   }
   $self->{'_data'}->{$key} = $value;

   return wantarray ? ($key,$value) : $key;
}

sub _parse_space {
   my($self,$space) = @_;
   my $out = lc $space;
   $out = "." . $out unless $out =~ m/^\./;
   $self->throw("Invalid space name <$out>", $space) unless $out =~ m/^[\w\.]+(\.\*)?$/i;
   return $out;
}

sub _space_required {
   my($self,$space) = @_;
   $space = $self->_parse_space($space);
   # Top-level space
   
   for my $req_space ( @{ $self->spaces } ) {
      return $req_space if (
      		# Explicitly required space
      		($req_space eq $space) ||
		# Among children of a required space.* 
      		($req_space =~ m/^(.+)\.\*$/ &&
      			$space =~ m/^$1\.[^\.]+/) ||
		# Parent of some required space
		($space =~ m/^$req_space\..*/)
	);
   }
   return 0;
}

sub _execute_token {
   my($self,@args) = @_;
   my ($token, $space, $body) = $self->_rearrange([qw(TOKEN SPACE BODY)], @args);
   $token = $self->_parse_key(-key=>$token, -space=>$space);
   $self->debug("Running $token with $body");
   defined  $self->_get_handle_function($token) or
      $self->throw("Any handle function for the called token", $token);
   my $hf = $self->_get_handle_function($token);
   ref($hf) =~ /HASH/i or
      $self->throw("Unexpected type of stored function", $hf);
   defined $hf->{'-obj'} && defined $hf->{'-fun'} or
      $self->throw("Incomplete function $token, imposible to complete call", $hf);
   eval {
      my $obj = $hf->{'-obj'};
      my $fun = $hf->{'-fun'};
      $obj->$fun($body, $hf->{'-defaults'});
   };
   if( $@ ){
      $self->throw("Error calling $token [$body]:\n$@", $hf);
   }
   return;
}
sub _execute_postparse {
   my($self,@args) = @_;
   $self->debug("Running postparse functions");
   for my $fn ( @{$self->_postparse_functions} ){
      next unless defined $fn; # This should never happens
      ref($fn) =~ /HASH/i or $self->throw("Unexpected type of stored function", $fn);
      defined $fn->{'-obj'} && defined $fn->{'-fun'} or
         $self->throw("Incomplete function, imposible to complete call", $fn);
      eval {
         my $obj = $fn->{'-obj'};
	 my $fun = $fn->{'-fun'};
	 $obj->$fun($fn->{'-defaults'});
      };
      if( $@ ){
         $self->throw("Error calling lambda function (for postparse):\n$@", $fn);
      }
   }
   return;
}
sub _register_handle_function {
   my($self,@args) = @_;
   my($token, $obj, $fun, $defaults, $space) =
   	$self->_rearrange([qw(TOKEN OBJ FUN DEFAULTS SPACE)], @args);
   $token = $self->_parse_key(-key=>$token, -space=>$space);
   my $hf = {-obj=>$obj, -fun=>$fun, -defaults=>$defaults};
   $self->_handle_functions;
   $self->{'_handle_functions'}->{$token} = $hf;
}
sub _register_postparse_function {
   my($self,@args) = @_;
   my($obj, $fun, $defaults) = $self->_rearrange([qw(OBJ FUN DEFAULTS)], @args);
   my $hf = {-obj=>$obj, -fun=>$fun, -defaults=>$defaults};
   $self->_postparse_functions;
   push @{$self->{'_postparse_functions'}}, $hf;
}

sub _handle_functions {
   my($self,@args) = @_;
   $self->{'_handle_functions'} = {} unless defined $self->{'_handle_functions'};
   return $self->{'_handle_functions'};
}

sub _postparse_functions {
   my($self,@args) = @_;
   $self->{'_postparse_functions'} = [] unless defined $self->{'_postparse_functions'};
   return $self->{'_postparse_functions'};
}

sub _get_handle_function {
   my($self,@args) = @_;
   my($token) = $self->_rearrange([qw(TOKEN)], @args);
   $self->_handle_functions;
   return $self->{'_handle_functions'}->{$token};
}

sub _reparse {
   my($self,@args) = @_;
   $self->{'_reparse'} = [] unless defined $self->{'_reparse'};
   my @reparse = @{$self->{'_reparse'}};
   $self->{'_reparse'} = [];
   return unless $#reparse>=0;
   if($CFGCURDEPTH++ >= $CFGMAXDEPTH){
      $self->warn("Maximum depth reached, some unparsed variables left");
      return;
   }
   for my $key (@reparse){
      next unless $key;
      my $v = $self->value($key);
      while($v =~ m/\$\{([\w\.]+)\}/){
      	 my $k2 = $1;
	 my $v2 = $self->value($k2);
      	 $v =~ s/\$\{$k2\}/$v2/g;
      }
      $self->_save(-key=>$key, -value=>"\"$v\"");
   }
   
   $self->_reparse(@args);
}

sub value {
   my($self,@args) = @_;
   my($key, $space, $mandatory, $noalert) =
   	$self->_rearrange([qw(KEY SPACE MANDATORY NOALERT)],@args);
   return unless $key;
   $key = $self->_parse_key(-key=>$key, -space=>$space);
   my $alias = $self->alias($key);
   if($alias){
      $self->debug("Retrieving value by alias ($key -> $alias)");
      return $self->value($alias);
   }
   unless(defined $self->{'_data'}->{$key}){
      $self->throw("Unable to find a value for the key", $key) if $mandatory;
      $self->warn("Unable to find a value for the key", $key) unless $noalert;
   }
   return $self->{'_data'}->{$key};
}

sub _parse_key {
   my($self,@args) = @_;
   my($key,$space) = $self->_rearrange([qw(KEY SPACE)], @args);
   $key or $self->throw("Got an empty key to parse, illegal action", $key,
   		"Polloc::Polloc::IOException");
   $key = lc $key;
   $space = $self->_parse_space($space);
   $key = $space . "." . $key if $space && $key !~ /^\./;
   $key =~ s/\.\./\./g;
   $key =~ s/\.\./\./g;
   $self->throw("Bad key or token on configuration file ".$self->resource, $key,
   		"Polloc::Polloc::IOException")
   		unless $key=~m/^[\w\.]+$/;
   return $key;
}

sub all_keys {
   my($self,$key) = @_;
   return keys %{ $self->{'_data'} };
}

sub _key_alias {
   my($self,$body,@args) = @_;
   $body or $self->throw("Empty body for alias", $body);
   $body =~ s/^\s*//;
   $body =~ s/\s*$//;
   my($from,$to) = split /\s+/, $body;
   $from or $self->throw("Any virtual key on alias", $body);
   $to or $self->throw("Any target key on alias", $body);
   $self->alias($from, $to);
}

sub alias {
   my($self,@args) = @_;
   my($from,$to) = $self->_rearrange([qw(FROM TO)], @args);
   $self->{'_alias'} ||= {};

   return unless $from;
   my $k = $self->_parse_key($from);
   $k or $self->throw("Illegal virual key as alias", $from);
   if(defined $to){
      my $d = $self->_parse_key($to);
      $self->debug("Saving alias ($k -> $d)");
      $d or $self->throw("Illegal target key to create alias", $to);
      $self->{'_alias'}->{$k} = $d;
   }
   return $self->{'_alias'}->{$k};
}

sub _initialize {
   my($self,@args) = @_;
   $self->_initialize_io(@args);
   my($spaces, $noparse) = $self->_rearrange([qw(SPACES NOPARSE)], @args);
   $self->{'_data'} = {};
   $self->spaces($spaces);
   $self->_register_handle_function(
   		-obj=>$self,
		-fun=>"_key_alias",
		-token=>".alias"
   	);
   $self->parse(@args) unless $noparse;
}


1;
