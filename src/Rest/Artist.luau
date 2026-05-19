--!strict
local Request = require(script.Parent.Request)
local Future = require(script.Parent.Parent.Future)
local Parse = require(script.Parent.Parent.Parse)
local Page = require(script.Parent.Parent.Page)
local Resources = require(script.Parent.Parent.Resources)

local Artist = {}
Artist.__index = Artist

export type ArtistNamespace = typeof(setmetatable({} :: { _Client: any }, Artist))

function Artist.New(client: any): ArtistNamespace
	return setmetatable({ _Client = client }, Artist) :: any
end

function Artist.GetCorrectionAsync(self: ArtistNamespace, artist: string)
	return Future.New(function(): Resources.Artist?
		local resp = Request.Execute((self :: any)._Client, "artist.getCorrection", { artist = artist })
		local corrections = (resp :: any).corrections
		if type(corrections) ~= "table" or corrections == "" then return nil end
		local correction = (corrections :: any).correction
		if type(correction) ~= "table" then return nil end
		local artistData = (correction :: any).artist
		if type(artistData) ~= "table" then return nil end
		return Parse.Artist(artistData)
	end)
end

function Artist.GetInfoAsync(self: ArtistNamespace, artist: string, opts: { Mbid: string?, Autocorrect: boolean?, Username: string?, Lang: string? }?)
	local o = opts or {}
	return Future.New(function(): Resources.Artist
		local params: { [string]: any } = { artist = artist }
		if o.Mbid then params.mbid = o.Mbid end
		if o.Autocorrect ~= nil then params.autocorrect = o.Autocorrect and "1" or "0" end
		if o.Username then params.username = o.Username end
		if o.Lang then params.lang = o.Lang end
		local resp = Request.Execute((self :: any)._Client, "artist.getInfo", params)
		return Parse.Artist((resp :: any).artist)
	end)
end

function Artist.GetSimilarAsync(self: ArtistNamespace, artist: string, opts: { Mbid: string?, Autocorrect: boolean?, Limit: number? }?)
	local o = opts or {}
	return Future.New(function(): { Resources.Artist }
		local params: { [string]: any } = { artist = artist }
		if o.Mbid then params.mbid = o.Mbid end
		if o.Autocorrect ~= nil then params.autocorrect = o.Autocorrect and "1" or "0" end
		if o.Limit then params.limit = o.Limit end
		local resp = Request.Execute((self :: any)._Client, "artist.getSimilar", params)
		local out: { Resources.Artist } = {}
		for _, a in Parse.List((resp :: any).similarartists and (resp :: any).similarartists.artist) do
			table.insert(out, Parse.Artist(a))
		end
		return out
	end)
end

function Artist.GetTagsAsync(self: ArtistNamespace, artist: string, opts: { Mbid: string?, Autocorrect: boolean?, User: string? }?)
	local o = opts or {}
	return Future.New(function(): { Resources.Tag }
		local params: { [string]: any } = { artist = artist }
		if o.Mbid then params.mbid = o.Mbid end
		if o.Autocorrect ~= nil then params.autocorrect = o.Autocorrect and "1" or "0" end
		if o.User then params.user = o.User end
		local resp = Request.Execute((self :: any)._Client, "artist.getTags", params)
		local out: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).tags and (resp :: any).tags.tag) do
			table.insert(out, Parse.Tag(t))
		end
		return out
	end)
end

function Artist.GetTopAlbumsAsync(self: ArtistNamespace, artist: string, opts: { Mbid: string?, Autocorrect: boolean?, Limit: number?, Page: number? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Album>
		local params: { [string]: any } = { artist = artist }
		if o.Mbid then params.mbid = o.Mbid end
		if o.Autocorrect ~= nil then params.autocorrect = o.Autocorrect and "1" or "0" end
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "artist.getTopAlbums", params)
		local topalbums = (resp :: any).topalbums
		local items: { Resources.Album } = {}
		for _, a in Parse.List(topalbums and (topalbums :: any).album) do
			table.insert(items, Parse.Album(a))
		end
		local function refetch(p: number): any
			return Artist.GetTopAlbumsAsync(self, artist, { Mbid = o.Mbid, Autocorrect = o.Autocorrect, Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(topalbums), Refetch = refetch })
	end)
end

function Artist.GetTopTagsAsync(self: ArtistNamespace, artist: string, opts: { Mbid: string?, Autocorrect: boolean? }?)
	local o = opts or {}
	return Future.New(function(): { Resources.Tag }
		local params: { [string]: any } = { artist = artist }
		if o.Mbid then params.mbid = o.Mbid end
		if o.Autocorrect ~= nil then params.autocorrect = o.Autocorrect and "1" or "0" end
		local resp = Request.Execute((self :: any)._Client, "artist.getTopTags", params)
		local out: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).toptags and (resp :: any).toptags.tag) do
			table.insert(out, Parse.Tag(t))
		end
		return out
	end)
end

function Artist.GetTopTracksAsync(self: ArtistNamespace, artist: string, opts: { Mbid: string?, Autocorrect: boolean?, Limit: number?, Page: number? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = { artist = artist }
		if o.Mbid then params.mbid = o.Mbid end
		if o.Autocorrect ~= nil then params.autocorrect = o.Autocorrect and "1" or "0" end
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "artist.getTopTracks", params)
		local toptracks = (resp :: any).toptracks
		local items: { Resources.Track } = {}
		for _, t in Parse.List(toptracks and (toptracks :: any).track) do
			table.insert(items, Parse.Track(t))
		end
		local function refetch(p: number): any
			return Artist.GetTopTracksAsync(self, artist, { Mbid = o.Mbid, Autocorrect = o.Autocorrect, Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(toptracks), Refetch = refetch })
	end)
end

function Artist.SearchAsync(self: ArtistNamespace, query: string, opts: { Limit: number?, Page: number? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Artist>
		local params: { [string]: any } = { artist = query }
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "artist.search", params)
		local results = (resp :: any).results
		local matches = results and (results :: any).artistmatches
		local items: { Resources.Artist } = {}
		for _, raw in Parse.MatchesList(matches, "artist") do
			table.insert(items, Parse.Artist(raw))
		end
		local pagination = Parse.Pagination(results)
		local function refetch(p: number): any
			return Artist.SearchAsync(self, query, { Limit = o.Limit, Page = p })
		end
		if pagination.Total == 0 then return Page.Empty(refetch) end
		return Page.Build({ Items = items, Pagination = pagination, Refetch = refetch })
	end)
end

function Artist.AddTagsAsync(self: ArtistNamespace, artist: string, tags: { string })
	return Future.New(function(): ()
		Request.Execute((self :: any)._Client, "artist.addTags", { artist = artist, tags = table.concat(tags, ",") })
		return nil
	end)
end

function Artist.RemoveTagAsync(self: ArtistNamespace, artist: string, tag: string)
	return Future.New(function(): ()
		Request.Execute((self :: any)._Client, "artist.removeTag", { artist = artist, tag = tag })
		return nil
	end)
end

return Artist
