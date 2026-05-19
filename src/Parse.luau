--!strict
-- Response parsing helpers. Last.fm's JSON-from-XML conversion produces a few
-- predictable warts:
--   - Numbers come as strings ("123" instead of 123)
--   - Booleans come as "0"/"1" strings
--   - Single-element lists are returned as the element itself, not as a length-1 array
--   - Pagination lives in an "@attr" key
--   - Text content lives in a "#text" key
--   - Missing fields may be absent, null, or empty objects {}
--
-- These helpers normalize all of that.

local Types = require("@self/Types")
local Resources = require("@self/Resources")

local Parse = {}

function Parse.Number(v: any): number?
	if v == nil then
		return nil
	end
	if type(v) == "number" then
		return v
	end
	if type(v) == "string" then
		return tonumber(v)
	end
	return nil
end

function Parse.String(v: any): string?
	if v == nil then
		return nil
	end
	if type(v) == "table" then
		local text = (v :: any)["#text"]
		if type(text) == "string" then
			return text
		end
		return nil
	end
	if type(v) == "string" then
		return v
	end
	return tostring(v)
end

function Parse.Boolean(v: any): boolean?
	if v == nil then
		return nil
	end
	if type(v) == "boolean" then
		return v
	end
	if type(v) == "string" then
		return v == "1" or v == "true" or v == "yes"
	end
	if type(v) == "number" then
		return v ~= 0
	end
	return nil
end

local function isoFromUnix(seconds: number): string
	return os.date("!%Y-%m-%dT%H:%M:%SZ", seconds)
end

function Parse.LastDate(raw: any): Types.LastDate?
	if raw == nil then
		return nil
	end
	if type(raw) == "number" then
		return { UnixSeconds = raw, Iso8601 = isoFromUnix(raw) }
	end
	if type(raw) == "string" then
		local n = tonumber(raw)
		if n then
			return { UnixSeconds = n, Iso8601 = isoFromUnix(n) }
		end
		return { UnixSeconds = 0, Iso8601 = raw }
	end
	if type(raw) == "table" then
		local uts = (raw :: any).uts or ((raw :: any)["@attr"] and (raw :: any)["@attr"].unixtime)
		local text = (raw :: any)["#text"]
		local unixSeconds = Parse.Number(uts)
		if unixSeconds then
			return { UnixSeconds = unixSeconds, Iso8601 = Parse.String(text) or isoFromUnix(unixSeconds) }
		end
		if type(text) == "string" then
			return { UnixSeconds = 0, Iso8601 = text }
		end
	end
	return nil
end

function Parse.Images(raw: any): { Types.Image }?
	if type(raw) ~= "table" then
		return nil
	end
	local result: { Types.Image } = {}
	for _, img in raw do
		if type(img) == "table" then
			local size = Parse.String((img :: any).size)
			local url = Parse.String((img :: any)["#text"])
			if size and url and url ~= "" then
				table.insert(result, { Size = size :: any, Url = url })
			end
		end
	end
	if #result == 0 then
		return nil
	end
	return result
end

function Parse.Wiki(raw: any): Resources.Wiki?
	if type(raw) ~= "table" then
		return nil
	end
	return {
		Summary = Parse.String((raw :: any).summary) or "",
		Content = Parse.String((raw :: any).content) or "",
		Published = Parse.LastDate((raw :: any).published),
		Url = Parse.String((raw :: any).url),
	}
end

function Parse.Attr(obj: any, ...: string): any
	if type(obj) ~= "table" then
		return nil
	end
	local attr = (obj :: any)["@attr"]
	if type(attr) ~= "table" then
		return nil
	end
	for _, key in { ... } do
		local v = (attr :: any)[key]
		if v ~= nil then
			return v
		end
	end
	return nil
end

-- Normalize Last.fm's inconsistent list shapes to always-an-array.
-- Shapes we have to handle:
--   nil                   -> {}
--   "" (string)           -> {}
--   {}  (empty table)     -> {}     -- JSON `[]` or `{}` decoded to empty Luau table
--   { a, b, c }           -> { a, b, c }   -- already a list
--   { key = ... }         -> { { key = ... } }   -- single object, dict-shaped
function Parse.List(raw: any): { any }
	if raw == nil then
		return {}
	end
	if type(raw) ~= "table" then
		return {}
	end
	if next(raw :: any) == nil then
		return {}
	end
	if (raw :: any)[1] ~= nil then
		return raw :: any
	end
	return { raw }
end

-- Helper for search responses (carried-forward fix from pylast #530):
-- search.results.{album|artist|track}matches.{album|artist|track} may be absent
-- when the search yielded no results. Returns {} cleanly.
function Parse.MatchesList(matches: any, innerKey: string): { any }
	if type(matches) ~= "table" then
		return {}
	end
	return Parse.List((matches :: any)[innerKey])
end

function Parse.Tag(raw: any): Resources.Tag
	if type(raw) == "string" then
		return { Name = raw }
	end
	if type(raw) ~= "table" then
		return { Name = "" }
	end
	return {
		Name = Parse.String((raw :: any).name) or "",
		Url = Parse.String((raw :: any).url),
		Count = Parse.Number((raw :: any).count),
		Reach = Parse.Number((raw :: any).reach),
		Total = Parse.Number((raw :: any).total),
		Wiki = Parse.Wiki((raw :: any).wiki),
	}
end

function Parse.Artist(raw: any): Resources.Artist
	if type(raw) == "string" then
		return { Name = raw }
	end
	if type(raw) ~= "table" then
		return { Name = "" }
	end
	local nameVal = (raw :: any).name
	if type(nameVal) == "table" then
		nameVal = (nameVal :: any)["#text"]
	end
	local artist: Resources.Artist = {
		Name = Parse.String(nameVal) or Parse.String((raw :: any)["#text"]) or "",
		Mbid = Parse.String((raw :: any).mbid),
		Url = Parse.String((raw :: any).url),
		Images = Parse.Images((raw :: any).image),
		Listeners = Parse.Number(
			if type((raw :: any).stats) == "table"
				then (raw :: any).stats.listeners
				else (raw :: any).listeners
		),
		PlayCount = Parse.Number(
			if type((raw :: any).stats) == "table"
				then (raw :: any).stats.playcount
				else (raw :: any).playcount
		),
		UserPlayCount = Parse.Number(
			if type((raw :: any).stats) == "table"
				then (raw :: any).stats.userplaycount
				else (raw :: any).userplaycount
		),
		Streamable = Parse.Boolean((raw :: any).streamable),
		OnTour = Parse.Boolean((raw :: any).ontour),
		Bio = Parse.Wiki((raw :: any).bio),
	}
	if type((raw :: any).tags) == "table" then
		local tags: { Resources.Tag } = {}
		for _, t in Parse.List((raw :: any).tags.tag) do
			table.insert(tags, Parse.Tag(t))
		end
		artist.Tags = tags
	end
	if type((raw :: any).similar) == "table" then
		local sims: { Resources.Artist } = {}
		for _, a in Parse.List((raw :: any).similar.artist) do
			table.insert(sims, Parse.Artist(a))
		end
		artist.Similar = sims
	end
	return artist
end

function Parse.Album(raw: any): Resources.Album
	if type(raw) ~= "table" then
		return { Name = "", Artist = { Name = "" } }
	end
	local artistVal = (raw :: any).artist
	local artist: Resources.Artist
	if type(artistVal) == "table" then
		artist = Parse.Artist(artistVal)
	else
		artist = { Name = Parse.String(artistVal) or "" }
	end
	local album: Resources.Album = {
		Name = Parse.String((raw :: any).name) or Parse.String((raw :: any).title) or "",
		Mbid = Parse.String((raw :: any).mbid),
		Url = Parse.String((raw :: any).url),
		Artist = artist,
		Images = Parse.Images((raw :: any).image),
		Listeners = Parse.Number((raw :: any).listeners),
		PlayCount = Parse.Number((raw :: any).playcount),
		UserPlayCount = Parse.Number((raw :: any).userplaycount),
	}
	if type((raw :: any).tracks) == "table" then
		local tracks: { Resources.Track } = {}
		for _, t in Parse.List((raw :: any).tracks.track) do
			table.insert(tracks, Parse.Track(t))
		end
		album.Tracks = tracks
	end
	if type((raw :: any).tags) == "table" then
		local tags: { Resources.Tag } = {}
		for _, t in Parse.List((raw :: any).tags.tag) do
			table.insert(tags, Parse.Tag(t))
		end
		album.Tags = tags
	end
	if (raw :: any).wiki then
		album.Wiki = Parse.Wiki((raw :: any).wiki)
	end
	return album
end

function Parse.Track(raw: any): Resources.Track
	if type(raw) ~= "table" then
		return { Name = "", Artist = { Name = "" } }
	end
	local artistVal = (raw :: any).artist
	local artist: Resources.Artist
	if type(artistVal) == "table" then
		artist = Parse.Artist(artistVal)
	else
		artist = { Name = Parse.String(artistVal) or "" }
	end
	local track: Resources.Track = {
		Name = Parse.String((raw :: any).name) or "",
		Mbid = Parse.String((raw :: any).mbid),
		Url = Parse.String((raw :: any).url),
		Artist = artist,
		Duration = Parse.Number((raw :: any).duration),
		Listeners = Parse.Number((raw :: any).listeners),
		PlayCount = Parse.Number((raw :: any).playcount),
		UserPlayCount = Parse.Number((raw :: any).userplaycount),
		UserLoved = Parse.Boolean((raw :: any).userloved),
		Date = Parse.LastDate((raw :: any).date),
		Images = Parse.Images((raw :: any).image),
		Streamable = Parse.Boolean(
			if type((raw :: any).streamable) == "table"
				then (raw :: any).streamable["#text"]
				else (raw :: any).streamable
		),
		Rank = Parse.Number(Parse.Attr(raw, "rank")),
	}
	if Parse.Attr(raw, "nowplaying") == "true" then
		track.NowPlaying = true
	end
	if type((raw :: any).album) == "table" then
		track.Album = Parse.Album((raw :: any).album)
	end
	if type((raw :: any).toptags) == "table" then
		local tags: { Resources.Tag } = {}
		for _, t in Parse.List((raw :: any).toptags.tag) do
			table.insert(tags, Parse.Tag(t))
		end
		track.Tags = tags
	end
	if (raw :: any).wiki then
		track.Wiki = Parse.Wiki((raw :: any).wiki)
	end
	return track
end

function Parse.User(raw: any): Resources.User
	if type(raw) ~= "table" then
		return { Name = "", Url = "" }
	end
	return {
		Name = Parse.String((raw :: any).name) or "",
		RealName = Parse.String((raw :: any).realname),
		Url = Parse.String((raw :: any).url) or "",
		Country = Parse.String((raw :: any).country),
		Age = Parse.Number((raw :: any).age),
		Gender = Parse.String((raw :: any).gender),
		Subscriber = Parse.Boolean((raw :: any).subscriber),
		PlayCount = Parse.Number((raw :: any).playcount),
		Playlists = Parse.Number((raw :: any).playlists),
		Registered = Parse.LastDate((raw :: any).registered),
		Images = Parse.Images((raw :: any).image),
		Type = Parse.String((raw :: any).type),
	}
end

export type Pagination = { Page: number, PerPage: number, TotalPages: number, Total: number }

function Parse.Pagination(raw: any): Pagination
	if type(raw) ~= "table" then
		return { Page = 1, PerPage = 0, TotalPages = 0, Total = 0 }
	end
	local attr = (raw :: any)["@attr"] or raw
	return {
		Page = Parse.Number((attr :: any).page) or 1,
		PerPage = Parse.Number((attr :: any).perPage) or Parse.Number((attr :: any).itemsPerPage) or 0,
		TotalPages = Parse.Number((attr :: any).totalPages) or 0,
		Total = Parse.Number((attr :: any).total) or 0,
	}
end

return Parse
