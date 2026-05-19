--!strict
local Framework = require("../Framework")
local Parse = require("@self/Parse")

return function()
	Framework.describe("Parse.Number", function()
		Framework.it("converts string ints", function()
			Framework.expect(Parse.Number("123")).toBe(123)
		end)
		Framework.it("passes through numbers", function()
			Framework.expect(Parse.Number(42)).toBe(42)
		end)
		Framework.it("returns nil for nil", function()
			Framework.expect(Parse.Number(nil)).toBeNil()
		end)
	end)

	Framework.describe("Parse.Boolean", function()
		Framework.it("treats '1' / '0' as true / false", function()
			Framework.expect(Parse.Boolean("1")).toBeTruthy()
			Framework.expect(Parse.Boolean("0")).toBeFalsy()
		end)
	end)

	Framework.describe("Parse.List", function()
		Framework.it("returns {} for nil", function()
			local list = Parse.List(nil)
			Framework.expect(#list).toBe(0)
		end)
		Framework.it("returns the array if already a list", function()
			local list = Parse.List({ "a", "b" })
			Framework.expect(#list).toBe(2)
			Framework.expect(list[1]).toBe("a")
		end)
		Framework.it("wraps a single object as a length-1 list", function()
			local list = Parse.List({ name = "x" })
			Framework.expect(#list).toBe(1)
			Framework.expect(list[1].name).toBe("x")
		end)
	end)

	Framework.describe("Parse.Pagination", function()
		Framework.it("coerces string fields to numbers", function()
			local p = Parse.Pagination({
				["@attr"] = { page = "2", perPage = "50", totalPages = "10", total = "500" },
			})
			Framework.expect(p.Page).toBe(2)
			Framework.expect(p.PerPage).toBe(50)
			Framework.expect(p.TotalPages).toBe(10)
			Framework.expect(p.Total).toBe(500)
		end)

		Framework.it("returns sensible defaults when @attr missing", function()
			local p = Parse.Pagination({})
			Framework.expect(p.Page).toBe(1)
			Framework.expect(p.TotalPages).toBe(0)
		end)
	end)

	Framework.describe("Parse.Wiki", function()
		Framework.it("strips HTML tags from Summary and Content", function()
			local w = Parse.Wiki({
				summary = [[Daft Punk are <a href="http://last.fm/x">a French duo</a> formed in 1993.]],
				content = [[<p>Lots of <b>info</b> here.</p>]],
				url = "http://last.fm/x",
			})
			Framework.expect(w and w.Summary).toBe("Daft Punk are a French duo formed in 1993.")
			Framework.expect(w and w.Content).toBe("Lots of info here.")
		end)
		Framework.it("preserves raw HTML on SummaryRaw and ContentRaw", function()
			local w = Parse.Wiki({
				summary = [[<a href="x">name</a>]],
				content = [[<p>x</p>]],
			})
			Framework.expect(w and w.SummaryRaw).toBe([[<a href="x">name</a>]])
			Framework.expect(w and w.ContentRaw).toBe([[<p>x</p>]])
		end)
		Framework.it("decodes common HTML entities", function()
			local w = Parse.Wiki({ summary = "rock &amp; roll &quot;quoted&quot; &#39;text&#39;", content = "" })
			Framework.expect(w and w.Summary).toBe([[rock & roll "quoted" 'text']])
		end)
		Framework.it("returns nil for non-table input", function()
			Framework.expect(Parse.Wiki(nil)).toBeNil()
			Framework.expect(Parse.Wiki("")).toBeNil()
		end)
	end)

	Framework.describe("Parse.Track", function()
		Framework.it("extracts name + artist from a recent-tracks-shaped object", function()
			local t = Parse.Track({
				name = "One More Time",
				artist = { ["#text"] = "Daft Punk", mbid = "abc" },
				url = "http://last.fm/x",
				date = { uts = "1700000000", ["#text"] = "14 Nov 2023, 22:13" },
			})
			Framework.expect(t.Name).toBe("One More Time")
			Framework.expect(t.Artist.Name).toBe("Daft Punk")
			Framework.expect(t.Url).toBe("http://last.fm/x")
			Framework.expect(t.Date and t.Date.UnixSeconds).toBe(1700000000)
		end)
		Framework.it("detects nowplaying flag", function()
			local t = Parse.Track({
				name = "X",
				artist = { ["#text"] = "Y" },
				["@attr"] = { nowplaying = "true" },
			})
			Framework.expect(t.NowPlaying).toBeTruthy()
		end)
	end)
end
