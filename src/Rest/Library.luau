--!strict
local Request = require("@self/Rest/Request")
local Future = require("@self/Future")
local Parse = require("@self/Parse")
local Page = require("@self/Page")
local Resources = require("@self/Resources")

local Library = {}
Library.__index = Library

export type LibraryNamespace = typeof(setmetatable({} :: { _Client: any }, Library))

function Library.New(client: any): LibraryNamespace
	return setmetatable({ _Client = client }, Library) :: any
end

function Library.GetArtistsAsync(self: LibraryNamespace, user: string, opts: { Limit: number?, Page: number? }?)
	local o: any = opts or {}
	return Future.New(function(): Page.Page<Resources.Artist>
		local params: { [string]: any } = { user = user }
		if o.Limit then
			params.limit = o.Limit
		end
		if o.Page then
			params.page = o.Page
		end
		local resp = Request.Execute((self :: any)._Client, "library.getArtists", params)
		local artists = (resp :: any).artists
		local items: { Resources.Artist } = {}
		for _, a in Parse.List(artists and (artists :: any).artist) do
			table.insert(items, Parse.Artist(a))
		end
		local function refetch(p: number): any
			return Library.GetArtistsAsync(self, user, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(artists), Refetch = refetch })
	end)
end

return Library
