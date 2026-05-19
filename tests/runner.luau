--!nocheck
-- Test runner. Loads each spec file (each one returns a function that
-- registers its cases), then invokes Framework.run().
--
-- Run with: `lune run tests/runner.luau` (from the project root)

local Framework = require("./Framework")

local specs = {
	require("./unit/md5.spec"),
	require("./unit/signing.spec"),
	require("./unit/cache.spec"),
	require("./unit/page.spec"),
	require("./unit/parse.spec"),
	require("./unit/secret.spec"),
	require("./unit/errors.spec"),
	require("./parity/p528_authenticated_user_name.spec"),
	require("./parity/p529_compilation_variant.spec"),
	require("./parity/p530_empty_search.spec"),
	require("./parity/p531_class_equality.spec"),
	require("./parity/p532_username_cache_key.spec"),
	require("./namespace/track.spec"),
	require("./namespace/user.spec"),
}

for _, spec in specs do
	if type(spec) == "function" then
		spec()
	end
end

local ok = Framework.run()
if not ok then
	error("Tests failed", 0)
end
