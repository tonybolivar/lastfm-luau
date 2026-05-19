--!strict
-- Album wrapper with helpers for compilation-album disambiguation.
-- Ported from pylast PR #529: Last.fm stores albums as (artist, album) tuples,
-- so the same compilation can live under multiple artist names. These helpers
-- resolve the actual album-artist by inspecting track data.

local Future = require("@self/Future")
local Resources = require("@self/Resources")
local Errors = require("@self/Errors")

local Album = {}
Album.__index = Album

export type Album = Resources.Album & {
	_Client: any,
	Sync: (self: Album, data: Resources.Album) -> (),
	GetAlbumArtistFromTracks: (self: Album) -> string?,
	FindCompilationVariantAsync: (self: Album) -> Future.FutureLike<Errors.LastFMError, Album?>,
}

function Album.New(data: Resources.Album, client: any?): Album
	local self: any = setmetatable(table.clone(data :: any), Album)
	self._Client = client
	return self
end

-- Re-hydrate fields from a fresh API payload.
function Album.Sync(self: Album, data: Resources.Album)
	for k, v in pairs(data :: any) do
		(self :: any)[k] = v
	end
end

-- pylast #529: inspect tracks to determine the real album-artist.
-- Returns the unanimous artist name if all tracks agree, "Various Artists" if
-- tracks disagree, or nil if Tracks is empty/missing (stub album).
function Album.GetAlbumArtistFromTracks(self: Album): string?
	local tracks = (self :: any).Tracks
	if not tracks or #tracks == 0 then
		return nil
	end
	local firstArtist: string? = nil
	for _, track in tracks :: { Resources.Track } do
		local artistName = if track.Artist then track.Artist.Name else nil
		if not artistName or artistName == "" then
			return firstArtist
		end
		if firstArtist == nil then
			firstArtist = artistName
		elseif artistName ~= firstArtist then
			return "Various Artists"
		end
	end
	return firstArtist
end

-- pylast #529: look up the "Various Artists" variant of this album.
-- Returns the variant only if it has actual track data (skips empty stubs
-- Last.fm creates from random scrobbles); otherwise nil.
function Album.FindCompilationVariantAsync(self: Album)
	return Future.New(function(): Album?
		local client = (self :: any)._Client
		if not client then
			error(
				Errors.New(
					"InvalidParameter",
					"FindCompilationVariantAsync requires the Album to be constructed with a client"
				),
				0
			)
		end
		local result = client.Album:GetInfoAsync("Various Artists", (self :: any).Name):Await()
		if result:IsErr() then
			return nil
		end
		local variant = result:UnwrapOk() :: Resources.Album
		if not variant.Tracks or #variant.Tracks == 0 then
			return nil
		end
		return Album.New(variant, client)
	end)
end

return Album
