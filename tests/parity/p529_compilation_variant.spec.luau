--!strict
-- pylast PR #529 — Add Album.get_album_artist_from_tracks and find_compilation_variant.
-- https://github.com/pylast/pylast/pull/529
--
-- Regression check: all four branches of GetAlbumArtistFromTracks plus the
-- compilation-variant filter that drops empty-stub Various Artists albums.

local Framework = require("../Framework")
local FakeHttp = require("../FakeHttp")
local LastFM = require("@self")
local Album = require("@self/Classes/Album")

return function()
	Framework.describe("pylast #529 parity: Album.GetAlbumArtistFromTracks", function()
		Framework.it("returns the unanimous artist when all tracks agree", function()
			local a = Album.New({
				Name = "X",
				Artist = { Name = "Constructor Artist" },
				Tracks = {
					{ Name = "T1", Artist = { Name = "ArtA" } },
					{ Name = "T2", Artist = { Name = "ArtA" } },
					{ Name = "T3", Artist = { Name = "ArtA" } },
				},
			})
			Framework.expect(a:GetAlbumArtistFromTracks()).toBe("ArtA")
		end)

		Framework.it("returns 'Various Artists' when tracks disagree", function()
			local a = Album.New({
				Name = "X",
				Artist = { Name = "Constructor Artist" },
				Tracks = {
					{ Name = "T1", Artist = { Name = "ArtA" } },
					{ Name = "T2", Artist = { Name = "ArtB" } },
				},
			})
			Framework.expect(a:GetAlbumArtistFromTracks()).toBe("Various Artists")
		end)

		Framework.it("returns nil when Tracks is missing or empty", function()
			local a = Album.New({ Name = "X", Artist = { Name = "Y" } })
			Framework.expect(a:GetAlbumArtistFromTracks()).toBeNil()
			local b = Album.New({ Name = "X", Artist = { Name = "Y" }, Tracks = {} })
			Framework.expect(b:GetAlbumArtistFromTracks()).toBeNil()
		end)
	end)

	Framework.describe("pylast #529 parity: Album.FindCompilationVariantAsync", function()
		Framework.it("returns the Various Artists variant when it has tracks", function()
			local fake = FakeHttp.New({
				["album.getInfo"] = [[{"album":{"name":"X","artist":"Various Artists","tracks":{"track":[{"name":"T1","artist":{"#text":"A1"}}]}}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local a = Album.New({ Name = "X", Artist = { Name = "ArtA" } }, client)
			local r = a:FindCompilationVariantAsync():Await()
			Framework.expect(r:IsOk()).toBeTruthy()
			local variant = r:UnwrapOk()
			Framework.expect(variant ~= nil).toBeTruthy()
			Framework.expect((variant :: any).Artist.Name).toBe("Various Artists")
		end)

		Framework.it("returns nil when the variant is a stub (no tracks)", function()
			local fake = FakeHttp.New({
				["album.getInfo"] = [[{"album":{"name":"X","artist":"Various Artists"}}]],
			})
			local client = LastFM.new({
				ApiKey = "k",
				HttpClient = fake,
				RateLimit = { Enabled = false },
			})
			local a = Album.New({ Name = "X", Artist = { Name = "ArtA" } }, client)
			local r = a:FindCompilationVariantAsync():Await()
			Framework.expect(r:IsOk()).toBeTruthy()
			Framework.expect(r:UnwrapOk()).toBeNil()
		end)
	end)
end
