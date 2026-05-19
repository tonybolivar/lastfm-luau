--!strict
local Framework = require("../Framework")
local Secret = require("@self/Secret")

return function()
	Framework.describe("Secret", function()
		Framework.it("masks half the value in tostring", function()
			local s = Secret.New("supersecret") -- 11 chars; half = 5
			local repr = tostring(s)
			-- Should contain prefix "super" but mask the rest
			Framework.expect(string.find(repr, "super") ~= nil).toBeTruthy()
			Framework.expect(string.find(repr, "secret") == nil).toBeTruthy()
		end)

		Framework.it("Reveal returns the raw value", function()
			local s = Secret.New("rawval")
			Framework.expect(Secret.Reveal(s)).toBe("rawval")
		end)

		Framework.it("IsSecret returns true for secrets, false otherwise", function()
			Framework.expect(Secret.IsSecret(Secret.New("x"))).toBeTruthy()
			Framework.expect(Secret.IsSecret("plain string")).toBeFalsy()
			Framework.expect(Secret.IsSecret({})).toBeFalsy()
			Framework.expect(Secret.IsSecret(nil)).toBeFalsy()
		end)

		Framework.it("blocks mutation via __newindex", function()
			local s = Secret.New("x")
			Framework.expect(function()
				(s :: any).foo = "bar"
			end).toThrow("Secret is immutable")
		end)

		Framework.it("masks short values entirely", function()
			local s = Secret.New("ab")
			Framework.expect(tostring(s)).toBe("Secret(**)")
		end)
	end)
end
