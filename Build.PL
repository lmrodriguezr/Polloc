use strict;
use Module::Build;
use Config;
use File::Spec;

my $build = new Module::Build (
	module_name	=> 'Bio::Polloc::Polloc::Root',
	description	=> 'Polymorphic Loci analysis',
	dist_name	=> 'Bio::Polloc',
	dist_author	=> 'Luis M Rodriguez-R <lmrodriguezr@gmail.com>',
	dist_abstract	=> 'Polymorphic Loci analysis',
	license		=> 'perl',
	requires	=> {
		perl		=> '5.8.0',
		Error		=> 0,
		'File::Path'	=> 0,
		'File::Spec'	=> 0,
		'File::Temp'	=> 0,
		'List::Util'	=> 0,
		Symbol		=> 0,
		'Bio::SeqIO'	=> 0,
	},
	recommends	=> {
		'GD::Simple'	=> 0,
		'File::Basename'	=> 0,
		Cwd		=> 0,
		'Bio::Tools::Run::Alignment::Muscle' => 0,
		'Bio::Tools::Run::StandAloneBlast' => 0,
		'Bio::Tools::Run::Hmmer' => 0,
	},
	build_requires	=> { 'Module::Build' => 0.20 },
	configure_requires => { 'Module::Build' => 0.36 },
	create_makefile_pl	=> 'traditional',
);

for my $pl (qw(polloc_vntrs)){
   my $script = File::Spec->catfile('scripts', "$pl.pl");
   $build->scripts($script) if $build->y_n("Do you want to install the $script script to $Config{installscript}?", 'n');
}

$build->create_makefile_pl;
$build->create_build_script;

