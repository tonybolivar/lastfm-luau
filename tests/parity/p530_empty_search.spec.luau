--!strict
-- pylast PR #530 — Return empty result instead of IndexError on empty search.
-- https://github.com/pylast/pylast/pull/530
--
-- Regression check: empty searches must return an empty Page<T> rather than
-- crashing on the missing `matches.*` key (parsed as nil, walrus-style guard).

local Framework = require("../Framework")
local FakeHttp = require("../FakeHttp")
local LastFM = require("@self")

return function()
	Framework.describe("pylast #530 parity: empty searches don't crash", function()
		Framework.it("Album:SearchAsync with no matches returns empty Page", function()
			local fake = FakeHttp.New({
				-- albummatches key is absent entirely
				["album.search"] = [[{"results":{"opensearch:totalResults":"0"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local r = client.Album:SearchAsync(""):Await()
			Framework.expect(r:IsOk()).toBeTruthy()
			local page = r:UnwrapOk()
			Framework.expect(#page.Items).toBe(0)
		end)

		Framework.it("Artist:SearchAsync with empty matches object returns empty Page", function()
			local fake = FakeHttp.New({
				-- artistmatches present but empty
				["artist.search"] = [[{"results":{"opensearch:totalResults":"0","artistmatches":{}}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local r = client.Artist:SearchAsync(""):Await()
			Framework.expect(r:IsOk()).toBeTruthy()
			Framework.expect(#r:UnwrapOk().Items).toBe(0)
		end)

		Framework.it("Track:SearchAsync with empty matches.track returns empty Page", function()
			local fake = FakeHttp.New({
				["track.search"] = [[{"results":{"opensearch:totalResults":"0","trackmatches":""}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local r = client.Track:SearchAsync(""):Await()
			Framework.expect(r:IsOk()).toBeTruthy()
			Framework.expect(#r:UnwrapOk().Items).toBe(0)
		end)
	end)
end
