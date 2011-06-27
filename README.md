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

This package is licensed under the terms of **The Artistic
License**. See LICENSE.txt.


Description
-----------

A perl package for detecting, comparing, grouping, extending and
summarizing polymorphic loci in bacterial genomes.  This package
is mainly aimed to assist typing studies, but can be applied in
a much wider range of projects.


Requirements
------------

### System-wide requirements

The basic system requires, at least, the following perl
modules:

* `Error`

* `File::Path`

* `File::Spec`

* `File::Temp`

* `List::Util`

* `Symbol`

* `Bio::SeqIO`

### Other requirements

The following requirements can be ignored depending on the
set of modules to be used.

#### Perl modules:

* `File::Basename`

* `Cwd`

* `Bio::Tools::Run::Alignment::Muscle`

* `Bio::Tools::Run::StandAloneBlast`

* `Bio::Tools::Run::Hmmer`

* `GD::Simple`

#### External tools

* [CRISPRfinder](http://crispr.u-psud.fr/Server/), for
CRISPRs detection.

* [TRF](http://tandem.bu.edu/trf/trf.html), for Tandem
Repeats detection (producing `Bio::Polloc::Locus::Repeat`
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

* [HMMER](http://hmmer.janelia.org/), for
profiles-based features detection and as alternative to
BLAST in context-based groups extension.


Installation
------------

From v1.5 onwards there are two way to install Polloc.  The easiest way is using
[CPAN](http://cpan.org), with the command `install Bio::Polloc`.

The second way is from the source, in a three-steps process:

1.  **Install the requirements**.  Remember, you can
    find the Perl modules in [CPAN](http://cpan.org).

2.  **Download** the library.  There are several alternatives,
    but we love [git](http://www.git-scm.com/):

    ```bash
        mkdir Polloc
        cd Polloc
        git init
        git clone git://github.com/lmrodriguezr/Polloc
    ```

3.  **Install** the library:

    ```bash
        # The following three lines are optional (only for non-built copies)
        perl Build.PL
        ./Build manifest
        ./Build dist
        
        # The following lines install the library and the documentation
        perl Makefile.PL
        make
        make test
        make install # Could require sudo
    ```

Once installed, you can:

*   **Use the package**.  See the following section (Usage) for
    some examples.

*   Familiar enough?  We are glad to listen than, then you could
    **start developing**.  You can check the documentation within the
    modules using perldoc (or any other Pod interpreter), or contact
    us for questions and feature requests.


Usage
-----

### Running existing scripts

The scripts distributed with Polloc are located at the `scripts` folder.  Scripts
include a small help message, so that you can just run it with `perl`.

**ToDo**: Documentation for:

* **polloc_primers.pl**.

* **polloc_gel.pl**.

### Writing new scripts

**ToDo**


F.A.Q.
------

### How do I know the installed version of Polloc in my machine?

    perl -MBio::Polloc -e 'print $Bio::Polloc::VERSION, "\n"'

### Is there an implementation of Polloc running in a real-life tool?

Yes, the [VNTRs detection tool](http://bioinfo-prod.mpl.ird.fr/xantho/utils/#vntrs),
a web-service devoted to the detection and analysis of VNTR loci (Variable Number of
Tandem Repeats).  If you have another tool making use of Polloc, [please let us
know](mailto:lrr@cpan.org?subject=Polloc%20tool).

### How can I contribute to the Polloc project?

The Polloc library is Open Source, and is licensed under the Perl Artistic License.  This
means that you can freely modify the code provided you properly cite the source.  However,
if you want your modifications to be incorporated into the main Polloc code, please fork
[Polloc at GitHub](http://www.github.com/lmrodriguezr/Polloc) and submit your changes via
Pull Requests.  If you are not familiar with Git, please read the documentation available
at the [git website](http://www.git-scm.com/).

### Where can I find the documented modules in human-readable format?

You can read the documentation of Polloc in HTML format at CPAN:
(http://search.cpan.org/dist/Polloc/).

