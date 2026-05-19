--!strict
local Request = require("@self/Rest/Request")
local Future = require("@self/Future")
local Parse = require("@self/Parse")
local Page = require("@self/Page")
local Resources = require("@self/Resources")

local Album = {}
Album.__index = Album

export type AlbumNamespace = typeof(setmetatable({} :: { _Client: any }, Album))

function Album.New(client: any): AlbumNamespace
	return setmetatable({ _Client = client }, Album) :: any
end

function Album.GetInfoAsync(
	self: AlbumNamespace,
	artist: string,
	album: string,
	opts: { Mbid: string?, Autocorrect: boolean?, Username: string?, Lang: string? }?
)
	local o: any = opts or {}
	return Future.New(function(): Resources.Album
		local params: { [string]: any } = { artist = artist, album = album }
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Autocorrect ~= nil then
			params.autocorrect = o.Autocorrect and "1" or "0"
		end
		if o.Username then
			params.username = o.Username
		end
		if o.Lang then
			params.lang = o.Lang
		end
		local resp = Request.Execute((self :: any)._Client, "album.getInfo", params)
		return Parse.Album((resp :: any).album)
	end)
end

function Album.GetTagsAsync(
	self: AlbumNamespace,
	artist: string,
	album: string,
	opts: { Mbid: string?, Autocorrect: boolean?, User: string? }?
)
	local o: any = opts or {}
	return Future.New(function(): { Resources.Tag }
		local params: { [string]: any } = { artist = artist, album = album }
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Autocorrect ~= nil then
			params.autocorrect = o.Autocorrect and "1" or "0"
		end
		if o.User then
			params.user = o.User
		end
		local resp = Request.Execute((self :: any)._Client, "album.getTags", params)
		local tags: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).tags and (resp :: any).tags.tag) do
			table.insert(tags, Parse.Tag(t))
		end
		return tags
	end)
end

function Album.GetTopTagsAsync(
	self: AlbumNamespace,
	artist: string,
	album: string,
	opts: { Mbid: string?, Autocorrect: boolean? }?
)
	local o: any = opts or {}
	return Future.New(function(): { Resources.Tag }
		local params: { [string]: any } = { artist = artist, album = album }
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Autocorrect ~= nil then
			params.autocorrect = o.Autocorrect and "1" or "0"
		end
		local resp = Request.Execute((self :: any)._Client, "album.getTopTags", params)
		local tags: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).toptags and (resp :: any).toptags.tag) do
			table.insert(tags, Parse.Tag(t))
		end
		return tags
	end)
end

function Album.SearchAsync(self: AlbumNamespace, query: string, opts: { Limit: number?, Page: number? }?)
	local o: any = opts or {}
	return Future.New(function(): Page.Page<Resources.Album>
		local params: { [string]: any } = { album = query }
		if o.Limit then
			params.limit = o.Limit
		end
		if o.Page then
			params.page = o.Page
		end
		local resp = Request.Execute((self :: any)._Client, "album.search", params)
		local results = (resp :: any).results
		local matches = results and (results :: any).albummatches
		local items: { Resources.Album } = {}
		for _, raw in Parse.MatchesList(matches, "album") do
			table.insert(items, Parse.Album(raw))
		end
		local pagination = Parse.Pagination(results)
		local function refetch(p: number): any
			return Album.SearchAsync(self, query, { Limit = o.Limit, Page = p })
		end
		if pagination.Total == 0 then
			return Page.Empty(refetch)
		end
		return Page.Build({
			Items = items,
			Pagination = pagination,
			Refetch = refetch,
		})
	end)
end

function Album.AddTagsAsync(self: AlbumNamespace, artist: string, album: string, tags: { string })
	return Future.New(function(): nil
		local params: { [string]: any } = { artist = artist, album = album, tags = table.concat(tags, ",") }
		Request.Execute((self :: any)._Client, "album.addTags", params)
		return nil
	end)
end

function Album.RemoveTagAsync(self: AlbumNamespace, artist: string, album: string, tag: string)
	return Future.New(function(): nil
		local params: { [string]: any } = { artist = artist, album = album, tag = tag }
		Request.Execute((self :: any)._Client, "album.removeTag", params)
		return nil
	end)
end

return Album
