--!strict
local Framework = require("../Framework")
local Page = require("@self/Page")

return function()
	Framework.describe("Page", function()
		local function makePage(pageNum: number, totalPages: number)
			return Page.New({
				Items = { "a", "b", "c" },
				PageNumber = pageNum,
				PageSize = 3,
				TotalPages = totalPages,
				TotalItems = totalPages * 3,
				Refetch = function(p)
					return require("@self/Future").Ok(makePage(p, totalPages))
				end,
			})
		end

		Framework.it("HasMore is true while pages remain", function()
			Framework.expect(makePage(1, 3):HasMore()).toBeTruthy()
			Framework.expect(makePage(3, 3):HasMore()).toBeFalsy()
		end)

		Framework.it("HasPrev is true past page 1", function()
			Framework.expect(makePage(1, 3):HasPrev()).toBeFalsy()
			Framework.expect(makePage(2, 3):HasPrev()).toBeTruthy()
		end)

		Framework.it("NextAsync re-issues with PageNumber+1", function()
			local p = makePage(1, 3)
			local r = p:NextAsync():Await()
			Framework.expect(r:IsOk()).toBeTruthy()
			Framework.expect(r:UnwrapOk().PageNumber).toBe(2)
		end)

		Framework.it("NextAsync errors when already on last page", function()
			local p = makePage(3, 3)
			local r = p:NextAsync():Await()
			Framework.expect(r:IsErr()).toBeTruthy()
		end)

		Framework.it("Empty page has zero items and zero pages", function()
			local empty = Page.Empty(function(_p)
				return require("@self/Future").Ok(makePage(1, 0))
			end)
			Framework.expect(#empty.Items).toBe(0)
			Framework.expect(empty.TotalPages).toBe(0)
			Framework.expect(empty:HasMore()).toBeFalsy()
		end)
	end)
end
