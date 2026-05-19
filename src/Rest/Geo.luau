--!strict
local Request = require(script.Parent.Request)
local Future = require(script.Parent.Parent.Future)
local Parse = require(script.Parent.Parent.Parse)
local Page = require(script.Parent.Parent.Page)
local Resources = require(script.Parent.Parent.Resources)

local Geo = {}
Geo.__index = Geo

export type GeoNamespace = typeof(setmetatable({} :: { _Client: any }, Geo))

function Geo.New(client: any): GeoNamespace
	return setmetatable({ _Client = client }, Geo) :: any
end

function Geo.GetTopArtistsAsync(self: GeoNamespace, country: string, opts: { Limit: number?, Page: number? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Artist>
		local params: { [string]: any } = { country = country }
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "geo.getTopArtists", params)
		local topartists = (resp :: any).topartists
		local items: { Resources.Artist } = {}
		for _, a in Parse.List(topartists and (topartists :: any).artist) do
			table.insert(items, Parse.Artist(a))
		end
		local function refetch(p: number): any
			return Geo.GetTopArtistsAsync(self, country, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(topartists), Refetch = refetch })
	end)
end

function Geo.GetTopTracksAsync(self: GeoNamespace, country: string, opts: { Limit: number?, Page: number?, Location: string? }?)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = { country = country }
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		if o.Location then params.location = o.Location end
		local resp = Request.Execute((self :: any)._Client, "geo.getTopTracks", params)
		local tracks = (resp :: any).tracks
		local items: { Resources.Track } = {}
		for _, t in Parse.List(tracks and (tracks :: any).track) do
			table.insert(items, Parse.Track(t))
		end
		local function refetch(p: number): any
			return Geo.GetTopTracksAsync(self, country, { Limit = o.Limit, Page = p, Location = o.Location })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(tracks), Refetch = refetch })
	end)
end

return Geo
