--!strict
-- pylast PR #531 — Fix Country and Tag equality raising AttributeError.
-- https://github.com/pylast/pylast/pull/531
--
-- Regression check: Class instances compared against incompatible types must
-- not error. lastfm-luau deliberately does NOT override __eq on any Class,
-- so Luau's default reference equality applies — that's safe against any
-- type. This test pins the choice; if a future change adds __eq, the test
-- will fail unless the new __eq also type-checks defensively.

local Framework = require("../Framework")
local Tag = require("@self/Classes/Tag")
local Artist = require("@self/Classes/Artist")
local Album = require("@self/Classes/Album")
local Track = require("@self/Classes/Track")
local User = require("@self/Classes/User")

return function()
	Framework.describe("pylast #531 parity: Class equality is type-safe", function()
		local function testClass(label: string, instance: any)
			Framework.it(`{label} comparison against nil does not error`, function()
				Framework.expect(instance == nil).toBeFalsy()
			end)
			Framework.it(`{label} comparison against string does not error`, function()
				Framework.expect(instance == "some string").toBeFalsy()
			end)
			Framework.it(`{label} comparison against empty table does not error`, function()
				Framework.expect(instance == ({} :: any)).toBeFalsy()
			end)
			Framework.it(`{label} == itself is true`, function()
				Framework.expect(instance == instance).toBeTruthy()
			end)
		end

		testClass("Tag", Tag.New({ Name = "rock" }))
		testClass("Artist", Artist.New({ Name = "Daft Punk" }))
		testClass("Album", Album.New({ Name = "Discovery", Artist = { Name = "Daft Punk" } }))
		testClass("Track", Track.New({ Name = "One More Time", Artist = { Name = "Daft Punk" } }))
		testClass("User", User.New({ Name = "alice", Url = "http://last.fm/user/alice" }))
	end)
end
