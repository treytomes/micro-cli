// The micro-cli test suite.
//
// Run: miniscript.exe test/run.ms
// Exit code 0 means every check passed.
//
// A test runner asks for part of the suite instead:
//
//   miniscript.exe test/run.ms --json --filter "a bare command line" --file cli.ms
//
// --filter takes a substring of a check's name, --file the name of a case module, and
// --json adds the ##TEST/##END records a runner reads. See harness.ms.
//
// The library is imported once, here, and the case module is handed this copy rather than
// importing one itself. The import binds the path it was given as the global name, so it
// is aliased below.

import "../cli"
import "harness"
import "cli"

// shellArgs[0] is this script, so the options start at index 1.
wanted = {"json": 0, "filters": [], "files": []}
at = 1
while at < shellArgs.len
	arg = shellArgs[at]
	if arg == "--filter" or arg == "--file" then
		if at + 1 >= shellArgs.len then
			print "error: " + arg + " needs a value"
			exit 1
		end if
		if arg == "--filter" then
			wanted.filters.push(shellArgs[at + 1])
		else
			wanted.files.push(shellArgs[at + 1])
		end if
		at = at + 2
	else if arg == "--json" then
		wanted.json = 1
		at = at + 1
	else
		print "error: unknown argument " + arg + " (--filter NAME, --file MODULE, --json)"
		exit 1
	end if
end while

harness.options.json = wanted.json
harness.options.filters = wanted.filters
harness.options.files = wanted.files

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
