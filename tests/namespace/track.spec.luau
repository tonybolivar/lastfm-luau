--!strict
local Framework = require("../Framework")
local FakeHttp = require("../FakeHttp")
local LastFM = require("../../src")

return function()
	Framework.describe("Track namespace", function()
		Framework.it("GetInfoAsync parses Name, Artist, PlayCount, Duration", function()
			local fake = FakeHttp.New({
				["track.getInfo"] = [[{"track":{"name":"One More Time","artist":{"#text":"Daft Punk","mbid":"abc"},"duration":"320000","playcount":"100","listeners":"50","url":"http://last.fm/x"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local info = client.Track:GetInfoAsync("Daft Punk", "One More Time"):Await():UnwrapOk()
			Framework.expect(info.Name).toBe("One More Time")
			Framework.expect(info.Artist.Name).toBe("Daft Punk")
			Framework.expect(info.PlayCount).toBe(100)
			Framework.expect(info.Listeners).toBe(50)
			Framework.expect(info.Duration).toBe(320000)
		end)

		Framework.it("LoveAsync requires a session — throws AuthRequired otherwise", function()
			local fake = FakeHttp.New({})
			local client = LastFM.new({
				ApiKey = "k",
				Secret = "s",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local r = client.Track:LoveAsync("A", "T"):Await()
			Framework.expect(r:IsErr()).toBeTruthy()
			Framework.expect(r:UnwrapErr().Kind).toBe("AuthRequired")
		end)

		Framework.it("LoveAsync succeeds when session is set", function()
			local fake = FakeHttp.New({
				["track.love"] = [[{"status":"ok"}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				Secret = "s",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			client:SetSession({ Name = "alice", Key = "sk" })
			local r = client.Track:LoveAsync("A", "T"):Await()
			Framework.expect(r:IsOk()).toBeTruthy()
			Framework.expect(#fake.Calls).toBe(1)
			Framework.expect(fake.Calls[1].httpMethod).toBe("POST")
		end)

		Framework.it("ScrobbleAsync rejects empty batches and >50", function()
			local fake = FakeHttp.New({ ["track.scrobble"] = [[{"scrobbles":{"@attr":{"accepted":"0","ignored":"0"}}}]] })
			local client = LastFM.new({
				ApiKey = "k", Secret = "s", HttpClient = fake, RateLimit = { Enabled = false },
			})
			client:SetSession({ Name = "alice", Key = "sk" })
			-- Empty
			local empty = client.Track:ScrobbleAsync({}):Await()
			Framework.expect(empty:IsErr()).toBeTruthy()
			-- 51 entries
			local big: { any } = {}
			for i = 1, 51 do
				table.insert(big, { Artist = "A", Track = "T", Timestamp = i })
			end
			local toobig = client.Track:ScrobbleAsync(big):Await()
			Framework.expect(toobig:IsErr()).toBeTruthy()
		end)
	end)
end
