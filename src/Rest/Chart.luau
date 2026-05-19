--!strict
local Request = require(script.Parent.Request)
local Future = require(script.Parent.Parent.Future)
local Parse = require(script.Parent.Parent.Parse)
local Page = require(script.Parent.Parent.Page)
local Resources = require(script.Parent.Parent.Resources)

local Chart = {}
Chart.__index = Chart

export type ChartNamespace = typeof(setmetatable({} :: { _Client: any }, Chart))

function Chart.New(client: any): ChartNamespace
	return setmetatable({ _Client = client }, Chart) :: any
end

function Chart.GetTopArtistsAsync(self: ChartNamespace, opts: { Limit: number?, Page: number? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Artist>
		local params: { [string]: any } = {}
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "chart.getTopArtists", params)
		local artists = (resp :: any).artists
		local items: { Resources.Artist } = {}
		for _, a in Parse.List(artists and (artists :: any).artist) do
			table.insert(items, Parse.Artist(a))
		end
		local function refetch(p: number): any
			return Chart.GetTopArtistsAsync(self, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(artists), Refetch = refetch })
	end)
end

function Chart.GetTopTagsAsync(self: ChartNamespace, opts: { Limit: number?, Page: number? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Tag>
		local params: { [string]: any } = {}
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "chart.getTopTags", params)
		local tags = (resp :: any).tags
		local items: { Resources.Tag } = {}
		for _, t in Parse.List(tags and (tags :: any).tag) do
			table.insert(items, Parse.Tag(t))
		end
		local function refetch(p: number): any
			return Chart.GetTopTagsAsync(self, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(tags), Refetch = refetch })
	end)
end

function Chart.GetTopTracksAsync(self: ChartNamespace, opts: { Limit: number?, Page: number? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = {}
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "chart.getTopTracks", params)
		local tracks = (resp :: any).tracks
		local items: { Resources.Track } = {}
		for _, t in Parse.List(tracks and (tracks :: any).track) do
			table.insert(items, Parse.Track(t))
		end
		local function refetch(p: number): any
			return Chart.GetTopTracksAsync(self, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(tracks), Refetch = refetch })
	end)
end

return Chart
