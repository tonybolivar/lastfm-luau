--!strict
local Request = require("@self/Rest/Request")
local Future = require("@self/Future")
local Parse = require("@self/Parse")
local Page = require("@self/Page")
local Resources = require("@self/Resources")
local Types = require("@self/Types")

local User = {}
User.__index = User

export type UserNamespace = typeof(setmetatable({} :: { _Client: any }, User))

function User.New(client: any): UserNamespace
	return setmetatable({ _Client = client }, User) :: any
end

-- Accept string | Roblox Player Instance. Caller-friendly: lets Roblox code do
-- :GetRecentTracksAsync(player) without having to dig out .Name.
local function resolveUser(value: any): string
	if type(value) == "string" then return value end
	if type(value) == "userdata" or (type(value) == "table" and (value :: any).Name and (value :: any).ClassName) then
		return tostring((value :: any).Name)
	end
	error("user parameter must be a string or a Roblox Player Instance", 0)
end

function User.GetInfoAsync(self: UserNamespace, user: string | any)
	local userName = resolveUser(user)
	return Future.New(function(): Resources.User
		local resp = Request.Execute((self :: any)._Client, "user.getInfo", { user = userName })
		return Parse.User((resp :: any).user)
	end)
end

function User.GetFriendsAsync(self: UserNamespace, user: string | any, opts: { Limit: number?, Page: number?, Recenttracks: boolean? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.User>
		local params: { [string]: any } = { user = userName }
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		if o.Recenttracks ~= nil then params.recenttracks = o.Recenttracks and "1" or "0" end
		local resp = Request.Execute((self :: any)._Client, "user.getFriends", params)
		local friends = (resp :: any).friends
		local items: { Resources.User } = {}
		for _, u in Parse.List(friends and (friends :: any).user) do
			table.insert(items, Parse.User(u))
		end
		local function refetch(p: number): any
			return User.GetFriendsAsync(self, userName, { Limit = o.Limit, Page = p, Recenttracks = o.Recenttracks })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(friends), Refetch = refetch })
	end)
end

function User.GetLovedTracksAsync(self: UserNamespace, user: string | any, opts: { Limit: number?, Page: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = { user = userName }
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "user.getLovedTracks", params)
		local loved = (resp :: any).lovedtracks
		local items: { Resources.Track } = {}
		for _, t in Parse.List(loved and (loved :: any).track) do
			table.insert(items, Parse.Track(t))
		end
		local function refetch(p: number): any
			return User.GetLovedTracksAsync(self, userName, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(loved), Refetch = refetch })
	end)
end

function User.GetRecentTracksAsync(self: UserNamespace, user: string | any, opts: { Limit: number?, Page: number?, From: number?, To: number?, Extended: boolean? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = { user = userName }
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		if o.From then params.from = o.From end
		if o.To then params.to = o.To end
		if o.Extended ~= nil then params.extended = o.Extended and "1" or "0" end
		local resp = Request.Execute((self :: any)._Client, "user.getRecentTracks", params)
		local recent = (resp :: any).recenttracks
		local items: { Resources.Track } = {}
		for _, t in Parse.List(recent and (recent :: any).track) do
			table.insert(items, Parse.Track(t))
		end
		local function refetch(p: number): any
			return User.GetRecentTracksAsync(self, userName, { Limit = o.Limit, Page = p, From = o.From, To = o.To, Extended = o.Extended })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(recent), Refetch = refetch })
	end)
end

function User.GetPersonalTagsAsync(self: UserNamespace, user: string | any, tag: string, taggingType: "artist" | "album" | "track", opts: { Limit: number?, Page: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): Page.Page<any>
		local params: { [string]: any } = { user = userName, tag = tag, taggingtype = taggingType }
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "user.getPersonalTags", params)
		local taggings = (resp :: any).taggings
		local items: { any } = {}
		if taggingType == "artist" then
			local list = taggings and (taggings :: any).artists and (taggings :: any).artists.artist
			for _, a in Parse.List(list) do table.insert(items, Parse.Artist(a)) end
		elseif taggingType == "album" then
			local list = taggings and (taggings :: any).albums and (taggings :: any).albums.album
			for _, a in Parse.List(list) do table.insert(items, Parse.Album(a)) end
		elseif taggingType == "track" then
			local list = taggings and (taggings :: any).tracks and (taggings :: any).tracks.track
			for _, t in Parse.List(list) do table.insert(items, Parse.Track(t)) end
		end
		local function refetch(p: number): any
			return User.GetPersonalTagsAsync(self, userName, tag, taggingType, { Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(taggings), Refetch = refetch })
	end)
end

function User.GetTopAlbumsAsync(self: UserNamespace, user: string | any, opts: { Period: Types.Period?, Limit: number?, Page: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Album>
		local params: { [string]: any } = { user = userName }
		if o.Period then params.period = o.Period end
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "user.getTopAlbums", params)
		local top = (resp :: any).topalbums
		local items: { Resources.Album } = {}
		for _, a in Parse.List(top and (top :: any).album) do
			table.insert(items, Parse.Album(a))
		end
		local function refetch(p: number): any
			return User.GetTopAlbumsAsync(self, userName, { Period = o.Period, Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(top), Refetch = refetch })
	end)
end

function User.GetTopArtistsAsync(self: UserNamespace, user: string | any, opts: { Period: Types.Period?, Limit: number?, Page: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Artist>
		local params: { [string]: any } = { user = userName }
		if o.Period then params.period = o.Period end
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "user.getTopArtists", params)
		local top = (resp :: any).topartists
		local items: { Resources.Artist } = {}
		for _, a in Parse.List(top and (top :: any).artist) do
			table.insert(items, Parse.Artist(a))
		end
		local function refetch(p: number): any
			return User.GetTopArtistsAsync(self, userName, { Period = o.Period, Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(top), Refetch = refetch })
	end)
end

function User.GetTopTagsAsync(self: UserNamespace, user: string | any, opts: { Limit: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): { Resources.Tag }
		local params: { [string]: any } = { user = userName }
		if o.Limit then params.limit = o.Limit end
		local resp = Request.Execute((self :: any)._Client, "user.getTopTags", params)
		local out: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).toptags and (resp :: any).toptags.tag) do
			table.insert(out, Parse.Tag(t))
		end
		return out
	end)
end

function User.GetTopTracksAsync(self: UserNamespace, user: string | any, opts: { Period: Types.Period?, Limit: number?, Page: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = { user = userName }
		if o.Period then params.period = o.Period end
		if o.Limit then params.limit = o.Limit end
		if o.Page then params.page = o.Page end
		local resp = Request.Execute((self :: any)._Client, "user.getTopTracks", params)
		local top = (resp :: any).toptracks
		local items: { Resources.Track } = {}
		for _, t in Parse.List(top and (top :: any).track) do
			table.insert(items, Parse.Track(t))
		end
		local function refetch(p: number): any
			return User.GetTopTracksAsync(self, userName, { Period = o.Period, Limit = o.Limit, Page = p })
		end
		return Page.Build({ Items = items, Pagination = Parse.Pagination(top), Refetch = refetch })
	end)
end

export type WeeklyChartRange = { From: number, To: number }

function User.GetWeeklyChartListAsync(self: UserNamespace, user: string | any)
	local userName = resolveUser(user)
	return Future.New(function(): { WeeklyChartRange }
		local resp = Request.Execute((self :: any)._Client, "user.getWeeklyChartList", { user = userName })
		local out: { WeeklyChartRange } = {}
		for _, c in Parse.List((resp :: any).weeklychartlist and (resp :: any).weeklychartlist.chart) do
			table.insert(out, {
				From = Parse.Number((c :: any).from) or 0,
				To = Parse.Number((c :: any).to) or 0,
			})
		end
		return out
	end)
end

function User.GetWeeklyAlbumChartAsync(self: UserNamespace, user: string | any, opts: { From: number?, To: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): { Resources.Album }
		local params: { [string]: any } = { user = userName }
		if o.From then params.from = o.From end
		if o.To then params.to = o.To end
		local resp = Request.Execute((self :: any)._Client, "user.getWeeklyAlbumChart", params)
		local out: { Resources.Album } = {}
		for _, a in Parse.List((resp :: any).weeklyalbumchart and (resp :: any).weeklyalbumchart.album) do
			table.insert(out, Parse.Album(a))
		end
		return out
	end)
end

function User.GetWeeklyArtistChartAsync(self: UserNamespace, user: string | any, opts: { From: number?, To: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): { Resources.Artist }
		local params: { [string]: any } = { user = userName }
		if o.From then params.from = o.From end
		if o.To then params.to = o.To end
		local resp = Request.Execute((self :: any)._Client, "user.getWeeklyArtistChart", params)
		local out: { Resources.Artist } = {}
		for _, a in Parse.List((resp :: any).weeklyartistchart and (resp :: any).weeklyartistchart.artist) do
			table.insert(out, Parse.Artist(a))
		end
		return out
	end)
end

function User.GetWeeklyTrackChartAsync(self: UserNamespace, user: string | any, opts: { From: number?, To: number? }?)
	local userName = resolveUser(user)
	local o = opts or {}
	return Future.New(function(): { Resources.Track }
		local params: { [string]: any } = { user = userName }
		if o.From then params.from = o.From end
		if o.To then params.to = o.To end
		local resp = Request.Execute((self :: any)._Client, "user.getWeeklyTrackChart", params)
		local out: { Resources.Track } = {}
		for _, t in Parse.List((resp :: any).weeklytrackchart and (resp :: any).weeklytrackchart.track) do
			table.insert(out, Parse.Track(t))
		end
		return out
	end)
end

return User
