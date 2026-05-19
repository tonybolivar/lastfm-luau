--!strict
-- pylast PR #528 — Fix `AuthenticatedUser.get_name` returning empty string.
-- https://github.com/pylast/pylast/pull/528
--
-- Regression check: when a session is restored with no resolved Name,
-- GetAuthenticatedUserAsync must call user.getInfo (with no `user` param,
-- relying on sk) and update the session's Name in-place.

local Framework = require("../Framework")
local FakeHttp = require("../FakeHttp")
local LastFM = require("@self")

return function()
	Framework.describe("pylast #528 parity: AuthenticatedUser name resolution", function()
		Framework.it("GetAuthenticatedUserAsync resolves Name when session.Name == ''", function()
			local fake = FakeHttp.New({
				["user.getInfo"] = [[{"user":{"name":"alice","url":"http://last.fm/user/alice","subscriber":"0","playcount":"1234"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				Secret = "s",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			client:SetSession({ Name = "", Key = "session_key", Subscriber = false })

			local result = client:GetAuthenticatedUserAsync():Await()
			Framework.expect(result:IsOk()).toBeTruthy()
			local user = result:UnwrapOk()
			Framework.expect(user.Name).toBe("alice")
		end)

		Framework.it("updates the session's Name after resolution so we don't re-resolve", function()
			local fake = FakeHttp.New({
				["user.getInfo"] = [[{"user":{"name":"bob","url":"http://last.fm/user/bob"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				Secret = "s",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			client:SetSession({ Name = "", Key = "session_key" })

			client:GetAuthenticatedUserAsync():Await():UnwrapOk()
			local sessionView = client:GetSession()
			Framework.expect(sessionView and sessionView.Name).toBe("bob")
		end)
	end)
end
