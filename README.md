# Docoptz


# Tests

In this commit the tests are state of being transitioned away from the
`docoptz.sh` source itself into their own test directory (where they will run
using [Dashtap]). This is an in-between state where you'll find the tests (in
the old home-brewed format) in the `t-nontap` directory, and you may run them
like so:

    for FILE in t/*.t; do echo "$FILE"; dash "$FILE"; done


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

<!--[eof]-->
