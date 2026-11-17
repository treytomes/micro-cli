// The micro-cli test suite.
//
// Run: miniscript.exe test/run.ms
// Exit code 0 means every check passed.
//
// The library is imported once, here, and the case module is handed this copy rather than
// importing one itself. The import binds the path it was given as the global name, so it
// is aliased below.

import "../cli"
import "harness"
import "cli"

cliSource = globals["../cli"]
cliCases = globals["cli"]

// A partly loaded module would otherwise surface as a puzzling error inside one case, so
// check the surface the suite relies on up front.
if cliSource.hasIndex("parse") == 0 then
	print "error: ../cli loaded without parse"
	exit 1
end if

cliCases.run(cliSource, harness)

harness.summary()
