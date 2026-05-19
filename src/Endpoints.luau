--!strict
-- Frozen metadata for all 57 Last.fm methods.
-- Read by the Rest layer to decide whether to sign requests, attach
-- a session key, cache the response, and so on.

export type UserScope = "session" | "param" | "none"

export type EndpointInfo = {
	Method: string,
	HttpMethod: "GET" | "POST",
	RequiresSignature: boolean,
	RequiresSession: boolean,
	UserScope: UserScope,
	DefaultTtl: number,
}

local VOLATILE = 30
local STANDARD = 300
local STATIC = 3600
local NO_CACHE = 0

local function read(method: string, ttl: number, scope: UserScope): EndpointInfo
	return {
		Method = method,
		HttpMethod = "GET",
		RequiresSignature = false,
		RequiresSession = false,
		UserScope = scope,
		DefaultTtl = ttl,
	}
end

local function signedRead(method: string): EndpointInfo
	return {
		Method = method,
		HttpMethod = "GET",
		RequiresSignature = true,
		RequiresSession = false,
		UserScope = "none",
		DefaultTtl = NO_CACHE,
	}
end

local function write(method: string): EndpointInfo
	return {
		Method = method,
		HttpMethod = "POST",
		RequiresSignature = true,
		RequiresSession = true,
		UserScope = "session",
		DefaultTtl = NO_CACHE,
	}
end

local function mobileWrite(method: string): EndpointInfo
	return {
		Method = method,
		HttpMethod = "POST",
		RequiresSignature = true,
		RequiresSession = false,
		UserScope = "none",
		DefaultTtl = NO_CACHE,
	}
end

local Endpoints: { [string]: EndpointInfo } = {
	-- Album (6)
	["album.addTags"] = write("album.addTags"),
	["album.getInfo"] = read("album.getInfo", STANDARD, "param"),
	["album.getTags"] = read("album.getTags", STANDARD, "param"),
	["album.getTopTags"] = read("album.getTopTags", STATIC, "none"),
	["album.removeTag"] = write("album.removeTag"),
	["album.search"] = read("album.search", STANDARD, "none"),

	-- Artist (10)
	["artist.addTags"] = write("artist.addTags"),
	["artist.getCorrection"] = read("artist.getCorrection", STATIC, "none"),
	["artist.getInfo"] = read("artist.getInfo", STANDARD, "param"),
	["artist.getSimilar"] = read("artist.getSimilar", STATIC, "none"),
	["artist.getTags"] = read("artist.getTags", STANDARD, "param"),
	["artist.getTopAlbums"] = read("artist.getTopAlbums", STANDARD, "none"),
	["artist.getTopTags"] = read("artist.getTopTags", STATIC, "none"),
	["artist.getTopTracks"] = read("artist.getTopTracks", STANDARD, "none"),
	["artist.removeTag"] = write("artist.removeTag"),
	["artist.search"] = read("artist.search", STANDARD, "none"),

	-- Auth (3) — all signed; getMobileSession is POST per Last.fm spec
	["auth.getMobileSession"] = mobileWrite("auth.getMobileSession"),
	["auth.getSession"] = signedRead("auth.getSession"),
	["auth.getToken"] = signedRead("auth.getToken"),

	-- Chart (3)
	["chart.getTopArtists"] = read("chart.getTopArtists", STANDARD, "none"),
	["chart.getTopTags"] = read("chart.getTopTags", STANDARD, "none"),
	["chart.getTopTracks"] = read("chart.getTopTracks", STANDARD, "none"),

	-- Geo (2)
	["geo.getTopArtists"] = read("geo.getTopArtists", STANDARD, "none"),
	["geo.getTopTracks"] = read("geo.getTopTracks", STANDARD, "none"),

	-- Library (1)
	["library.getArtists"] = read("library.getArtists", STANDARD, "param"),

	-- Tag (7)
	["tag.getInfo"] = read("tag.getInfo", STATIC, "none"),
	["tag.getSimilar"] = read("tag.getSimilar", STATIC, "none"),
	["tag.getTopAlbums"] = read("tag.getTopAlbums", STANDARD, "none"),
	["tag.getTopArtists"] = read("tag.getTopArtists", STANDARD, "none"),
	["tag.getTopTags"] = read("tag.getTopTags", STATIC, "none"),
	["tag.getTopTracks"] = read("tag.getTopTracks", STANDARD, "none"),
	["tag.getWeeklyChartList"] = read("tag.getWeeklyChartList", STATIC, "none"),

	-- Track (12)
	["track.addTags"] = write("track.addTags"),
	["track.getCorrection"] = read("track.getCorrection", STATIC, "none"),
	["track.getInfo"] = read("track.getInfo", STANDARD, "param"),
	["track.getSimilar"] = read("track.getSimilar", STATIC, "none"),
	["track.getTags"] = read("track.getTags", STANDARD, "param"),
	["track.getTopTags"] = read("track.getTopTags", STATIC, "none"),
	["track.love"] = write("track.love"),
	["track.removeTag"] = write("track.removeTag"),
	["track.scrobble"] = write("track.scrobble"),
	["track.search"] = read("track.search", STANDARD, "none"),
	["track.unlove"] = write("track.unlove"),
	["track.updateNowPlaying"] = write("track.updateNowPlaying"),

	-- User (13)
	["user.getFriends"] = read("user.getFriends", STANDARD, "param"),
	["user.getInfo"] = read("user.getInfo", STANDARD, "param"),
	["user.getLovedTracks"] = read("user.getLovedTracks", VOLATILE, "param"),
	["user.getPersonalTags"] = read("user.getPersonalTags", STANDARD, "param"),
	["user.getRecentTracks"] = read("user.getRecentTracks", VOLATILE, "param"),
	["user.getTopAlbums"] = read("user.getTopAlbums", STANDARD, "param"),
	["user.getTopArtists"] = read("user.getTopArtists", STANDARD, "param"),
	["user.getTopTags"] = read("user.getTopTags", STANDARD, "param"),
	["user.getTopTracks"] = read("user.getTopTracks", STANDARD, "param"),
	["user.getWeeklyAlbumChart"] = read("user.getWeeklyAlbumChart", STATIC, "param"),
	["user.getWeeklyArtistChart"] = read("user.getWeeklyArtistChart", STATIC, "param"),
	["user.getWeeklyChartList"] = read("user.getWeeklyChartList", STATIC, "param"),
	["user.getWeeklyTrackChart"] = read("user.getWeeklyTrackChart", STATIC, "param"),
}

return table.freeze(Endpoints)
