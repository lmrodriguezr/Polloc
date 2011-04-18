Perl modules for Polymorphic Loci Analysis (Polloc)
===================================================

A collection of perl modules to analyse *Polymorphic Loci*
in bacterial genomes.


Author
------

Luis M. Rodriguez R. <lmrodriguezr at gmail dot com>

Institut de Recherche pour le developpement

UMR Resistance des Plantes aux Bioagresseurs

Group *Effecteur/Cible*

Montpellier, France


License
-------

This package is licensed under the terms of *The Artistic
License*. See LICENSE.txt.


Description
-----------



Requirements
------------

### System-wide requirements

The basic system requires, at least, the following perl
modules:

* `Error`

* `File::Path`

* `File::Spec`

* `File::Temp`

* `Symbol`

### Other requirements

The following requirements can be ignored depending on the
set of modules to be used.

#### Perl modules:

*  `File::Basename`

* `Cwd`

* `Bio::SeqIO`

* `Bio::Tools::Run::Alignment::Muscle`

* `Bio::Tools::Run::StandAloneBlast`

* `Bio::Tools::Run::Hmmer`

#### External tools

* [CRISPRfinder](http://crispr.u-psud.fr/Server/), for
CRISPRs detection.

* [TRF](http://tandem.bu.edu/trf/trf.html), for Tandem
Repeats detection (producing `Polloc::Locus::Repeat`
objects).

* [mreps](http://bioinfo.lifl.fr/mreps/), for Repeats
detection (alternative to TRF).

* [Stand-Alone NCBI BLAST](http://blast.ncbi.nlm.nih.gov/),
for several analyses including features grouping,
homology-based detection of features and context-based
groups extension.

* [Muscle](http://www.drive5.com/muscle/), for alignments
in features detection and grouping, as well as context-based
groups extension.

* [HMMER](http://http://hmmer.janelia.org/), for
profiles-based features detection and as alternative to
BLAST in context-based groups extension.


Installation
------------

1.  **Install the requirements**.  Remember, you can
    find the Perl modules in [CPAN](cpan.org).

2.  **Download** the library.  There are several alternatives,
    but we love git:

	mkdir Polloc
	cd Polloc
	git init
	git clone git://github.com/lmrodriguezr/Polloc
	cp -r lib/Polloc <perl-libraries-location> # For example /usr/lib/perl5/site_perl

3.  **Use the package**.  See the following section (Usage) for
    some examples.

4.  Familiar enough?  We are glad to listen than, **start developing**.
    You can check the documentation within the modules using perldoc
    (or any other Pod interpreter), or contact us at for questions and
    features requests.


Usage
-----

### Running existing scripts


### Writing new scripts

