# Docoptz


# Installing & Updating

Docoptz uses the Dashtap test framework which is included as a Git submodule,
so if you want to run the tests, you'll need to clone the submodules as well:

    git clone --recurse-submodules git@github.com:zrajm/docoptz.git

The same goes for when you're pulling the latest changes:

    git pull --recurse-submodules

NOTE: If a submodule is in a 'detach HEAD' state (using Git v2.34.1) when you
invoke `git pull --recurse-submodules`, the submodule will remain in detached
HEAD state, but in the main repository `git status` will report that the
submodule as unmodified. :(

The following command will output the names of all submodules that are in a
detached HEAD state:

    git submodule -q foreach 'git symbolic-ref -q HEAD || echo "$sm_path"'


# Tests

The Docoptz test suite (found in the directory `t/`) can be run using:

    prove

Docoptz comes with a test suite written using the small [Dashtap] testing
framework. It is written using the [Dash] shell and uses the [TAP] (*Test
Anything Protocol*) output format. The small Dash shell file size and fast
execution format help deliver fast testing, while the TAP protocol allow you to
use any testing tool build for TAP (e.g. the `prove` command used above that
comes with Perl).


# License

All source code in this repository is licensed under GNU General Public License
version 2.0 ([GPL-2.0]). – Except for any included external libraries and
modules which use their own licenses.

Non-source code material is licensed under Creative Commons Attribution
ShareAlike version 4.0 International ([CC-BY-SA-4.0]).

[CC-BY-SA-4.0]: LICENSE-CC-BY-SA.txt
[Dash]: http://gondor.apana.org.au/~herbert/dash "Debian Almquist SHell"
[Dashtap]: //github.com/zrajm/dashtap "Dashtap Testing Framework"
[GPL-2.0]: LICENSE-GPL2.txt
[TAP]: //testanything.org "Test Anything Protocol"

<!--[eof]-->
