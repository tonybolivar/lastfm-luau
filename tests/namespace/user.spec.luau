--!strict
local Framework = require("../Framework")
local FakeHttp = require("../FakeHttp")
local LastFM = require("../../src")

return function()
	Framework.describe("User namespace", function()
		Framework.it("GetRecentTracksAsync parses pagination and items", function()
			local fake = FakeHttp.New({
				["user.getRecentTracks"] = [[{"recenttracks":{"@attr":{"page":"1","perPage":"50","totalPages":"3","total":"150","user":"alice"},"track":[{"name":"T1","artist":{"#text":"A1"},"date":{"uts":"1700000000","#text":"14 Nov 2023, 22:13"}},{"name":"T2","artist":{"#text":"A2"},"date":{"uts":"1700000060","#text":"14 Nov 2023, 22:14"}}]}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local page = client.User:GetRecentTracksAsync("alice"):Await():UnwrapOk()
			Framework.expect(#page.Items).toBe(2)
			Framework.expect(page.TotalPages).toBe(3)
			Framework.expect(page.PageNumber).toBe(1)
			Framework.expect(page.TotalItems).toBe(150)
			Framework.expect(page:HasMore()).toBeTruthy()
			Framework.expect(page.Items[1].Name).toBe("T1")
			Framework.expect(page.Items[1].Artist.Name).toBe("A1")
			Framework.expect(page.Items[1].Date and page.Items[1].Date.UnixSeconds).toBe(1700000000)
		end)

		Framework.it("GetInfoAsync parses user profile", function()
			local fake = FakeHttp.New({
				["user.getInfo"] = [[{"user":{"name":"alice","realname":"Alice","url":"http://last.fm/user/alice","country":"US","playcount":"42000","subscriber":"1"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local u = client.User:GetInfoAsync("alice"):Await():UnwrapOk()
			Framework.expect(u.Name).toBe("alice")
			Framework.expect(u.RealName).toBe("Alice")
			Framework.expect(u.Country).toBe("US")
			Framework.expect(u.PlayCount).toBe(42000)
			Framework.expect(u.Subscriber).toBeTruthy()
		end)

		Framework.it("GetTopArtistsAsync with period parameter", function()
			local fake = FakeHttp.New({
				["user.getTopArtists"] = [[{"topartists":{"@attr":{"page":"1","perPage":"50","totalPages":"1","total":"2","user":"alice"},"artist":[{"name":"Queen","playcount":"1511"},{"name":"Videoclub","playcount":"1124"}]}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local page = client.User:GetTopArtistsAsync("alice", { Period = "12month" }):Await():UnwrapOk()
			Framework.expect(#page.Items).toBe(2)
			Framework.expect(page.Items[1].Name).toBe("Queen")
			Framework.expect(page.Items[1].PlayCount).toBe(1511)
		end)
	end)
end
