--!strict
local Framework = require("../Framework")
local Signing = require("@self/Signing")
local Md5 = require("@self/Md5")

return function()
	Framework.describe("Signing.GenerateSignature", function()
		Framework.it("sorts params alphabetically and appends secret", function()
			local params = { method = "auth.getSession", api_key = "k", token = "t" }
			local sig = Signing.GenerateSignature(params, "secret")
			-- Manual: api_keykmethodauth.getSessiontokent + "secret"
			local expected = Md5.Hash("api_keykmethodauth.getSessiontokentsecret")
			Framework.expect(sig).toBe(expected)
		end)

		Framework.it("excludes format and callback from signature", function()
			local withExtras =
				Signing.GenerateSignature({ method = "x", api_key = "k", format = "json", callback = "cb" }, "s")
			local without = Signing.GenerateSignature({ method = "x", api_key = "k" }, "s")
			Framework.expect(withExtras).toBe(without)
		end)

		Framework.it("skips nil-valued params", function()
			local withNil = Signing.GenerateSignature({ a = "1", b = nil :: any, c = "3" }, "s")
			local without = Signing.GenerateSignature({ a = "1", c = "3" }, "s")
			Framework.expect(withNil).toBe(without)
		end)

		Framework.it("matches the Last.fm worked example", function()
			-- From https://www.last.fm/api/authspec
			-- params: api_key=xxxxxxxxxx, method=auth.getSession, token=yyyyyy
			-- secret: ilovecher
			-- expected concat: api_keyxxxxxxxxxxmethodauth.getSessiontokenyyyyyyilovecher
			local sig = Signing.GenerateSignature({
				api_key = "xxxxxxxxxx",
				method = "auth.getSession",
				token = "yyyyyy",
			}, "ilovecher")
			Framework.expect(sig).toBe(Md5.Hash("api_keyxxxxxxxxxxmethodauth.getSessiontokenyyyyyyilovecher"))
		end)

		Framework.it("produces a 32-char lowercase hex string", function()
			local sig = Signing.GenerateSignature({ method = "track.getInfo" }, "x")
			Framework.expect(#sig).toBe(32)
			Framework.expect(string.match(sig, "^[0-9a-f]+$") ~= nil).toBeTruthy()
		end)
	end)
end
