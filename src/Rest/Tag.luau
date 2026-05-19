--!strict
local Request = require("@self/Rest/Request")
local Future = require("@self/Future")
local Parse = require("@self/Parse")
local Page = require("@self/Page")
local Resources = require("@self/Resources")

local Tag = {}
Tag.__index = Tag

export type TagNamespace = typeof(setmetatable({} :: { _Client: any }, Tag))

function Tag.New(client: any): TagNamespace
	return setmetatable({ _Client = client }, Tag) :: any
end

function Tag.GetInfoAsync(self: TagNamespace, tag: string, opts: { Lang: string? }?)
	local o: any = opts or {}
	return Future.New(function(): Resources.Tag
		local params: { [string]: any } = { tag = tag }
		if o.Lang then
			params.lang = o.Lang
		end
		local resp = Request.Execute((self :: any)._Client, "tag.getInfo", params)
		return Parse.Tag((resp :: any).tag)
	end)
end

function Tag.GetSimilarAsync(self: TagNamespace, tag: string)
	return Future.New(function(): { Resources.Tag }
		local resp = Request.Execute((self :: any)._Client, "tag.getSimilar", { tag = tag })
		local out: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).similartags and (resp :: any).similartags.tag) do
			table.insert(out, Parse.Tag(t))
		end
		return out
	end)
end

function Tag.GetTopAlbumsAsync(self: TagNamespace, tag: string, opts: { Limit: number?, Page: number? }?)
	local o: any = opts or {}
	return Future.New(function(): Page.Page<Resources.Album>
		local params: { [string]: any } = { tag = tag }
		if o.Limit then
			params.limit = o.Limit
		end
		if o.Page then
			params.page = o.Page
		end
		local resp = Request.Execute((self :: any)._Client, "tag.getTopAlbums", params)
		local albums = (resp :: any).albums
		local items: { Resources.Album } = {}
		for _, a in Parse.List(albums and (albums :: any).album) do
			table.insert(items, Parse.Album(a))
		end
		local function refetch(p: number): any
			return Tag.GetTopAlbumsAsync(self, tag, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(albums), Refetch = refetch })
	end)
end

function Tag.GetTopArtistsAsync(self: TagNamespace, tag: string, opts: { Limit: number?, Page: number? }?)
	local o: any = opts or {}
	return Future.New(function(): Page.Page<Resources.Artist>
		local params: { [string]: any } = { tag = tag }
		if o.Limit then
			params.limit = o.Limit
		end
		if o.Page then
			params.page = o.Page
		end
		local resp = Request.Execute((self :: any)._Client, "tag.getTopArtists", params)
		local topartists = (resp :: any).topartists
		local items: { Resources.Artist } = {}
		for _, a in Parse.List(topartists and (topartists :: any).artist) do
			table.insert(items, Parse.Artist(a))
		end
		local function refetch(p: number): any
			return Tag.GetTopArtistsAsync(self, tag, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(topartists), Refetch = refetch })
	end)
end

function Tag.GetTopTagsAsync(self: TagNamespace)
	return Future.New(function(): { Resources.Tag }
		local resp = Request.Execute((self :: any)._Client, "tag.getTopTags", {})
		local out: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).toptags and (resp :: any).toptags.tag) do
			table.insert(out, Parse.Tag(t))
		end
		return out
	end)
end

function Tag.GetTopTracksAsync(self: TagNamespace, tag: string, opts: { Limit: number?, Page: number? }?)
	local o: any = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = { tag = tag }
		if o.Limit then
			params.limit = o.Limit
		end
		if o.Page then
			params.page = o.Page
		end
		local resp = Request.Execute((self :: any)._Client, "tag.getTopTracks", params)
		local tracks = (resp :: any).tracks
		local items: { Resources.Track } = {}
		for _, t in Parse.List(tracks and (tracks :: any).track) do
			table.insert(items, Parse.Track(t))
		end
		local function refetch(p: number): any
			return Tag.GetTopTracksAsync(self, tag, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(tracks), Refetch = refetch })
	end)
end

function Tag.GetWeeklyChartListAsync(self: TagNamespace, tag: string)
	return Future.New(function(): { { From: number, To: number } }
		local resp = Request.Execute((self :: any)._Client, "tag.getWeeklyChartList", { tag = tag })
		local out: { { From: number, To: number } } = {}
		for _, c in Parse.List((resp :: any).weeklychartlist and (resp :: any).weeklychartlist.chart) do
			table.insert(out, {
				From = Parse.Number((c :: any).from) or 0,
				To = Parse.Number((c :: any).to) or 0,
			})
		end
		return out
	end)
end

return Tag
