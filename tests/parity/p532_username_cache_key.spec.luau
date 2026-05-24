--!strict
-- pylast PR #532, Fix cache miss on requests with username param.
-- https://github.com/pylast/pylast/pull/532
--
-- Regression check: two calls to track.getInfo with the same `username` must
-- hit the cache on the second call (no second HTTP request), and calls with
-- different usernames must NOT collide.

local Framework = require("../Framework")
local FakeHttp = require("../FakeHttp")
local LastFM = require("@self")

return function()
	Framework.describe("pylast #532 parity: cache key includes username", function()
		Framework.it("second call with same username hits cache", function()
			local fake = FakeHttp.New({
				["track.getInfo"] = [[{"track":{"name":"T","artist":{"#text":"A"},"userplaycount":"5"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})

			client.Track:GetInfoAsync("A", "T", { Username = "alice" }):Await():UnwrapOk()
			Framework.expect(#fake.Calls).toBe(1)

			client.Track:GetInfoAsync("A", "T", { Username = "alice" }):Await():UnwrapOk()
			Framework.expect(#fake.Calls).toBe(1)
		end)

		Framework.it("different usernames do NOT share cache", function()
			local fake = FakeHttp.New({
				["track.getInfo"] = [[{"track":{"name":"T","artist":{"#text":"A"},"userplaycount":"5"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})

			client.Track:GetInfoAsync("A", "T", { Username = "alice" }):Await():UnwrapOk()
			client.Track:GetInfoAsync("A", "T", { Username = "bob" }):Await():UnwrapOk()
			Framework.expect(#fake.Calls).toBe(2)
		end)

		Framework.it("calls with no username share cache with each other", function()
			local fake = FakeHttp.New({
				["track.getInfo"] = [[{"track":{"name":"T","artist":{"#text":"A"}}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})

			client.Track:GetInfoAsync("A", "T"):Await():UnwrapOk()
			client.Track:GetInfoAsync("A", "T"):Await():UnwrapOk()
			Framework.expect(#fake.Calls).toBe(1)
		end)
	end)
end
