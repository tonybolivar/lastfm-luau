--!strict
local Request = require("@self/Rest/Request")
local Future = require("@self/Future")
local Parse = require("@self/Parse")
local Page = require("@self/Page")
local Resources = require("@self/Resources")

local Track = {}
Track.__index = Track

export type TrackNamespace = typeof(setmetatable({} :: { _Client: any }, Track))

function Track.New(client: any): TrackNamespace
	return setmetatable({ _Client = client }, Track) :: any
end

function Track.GetCorrectionAsync(self: TrackNamespace, artist: string, track: string)
	return Future.New(function(): Resources.Track?
		local resp = Request.Execute((self :: any)._Client, "track.getCorrection", { artist = artist, track = track })
		local corrections = (resp :: any).corrections
		if type(corrections) ~= "table" or corrections == "" then
			return nil
		end
		local correction = (corrections :: any).correction
		if type(correction) ~= "table" then
			return nil
		end
		local trackData = (correction :: any).track
		if type(trackData) ~= "table" then
			return nil
		end
		return Parse.Track(trackData)
	end)
end

function Track.GetInfoAsync(
	self: TrackNamespace,
	artist: string,
	track: string,
	opts: { Mbid: string?, Autocorrect: boolean?, Username: string? }?
)
	local o: any = opts or {}
	return Future.New(function(): Resources.Track
		local params: { [string]: any } = { artist = artist, track = track }
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Autocorrect ~= nil then
			params.autocorrect = o.Autocorrect and "1" or "0"
		end
		if o.Username then
			params.username = o.Username
		end
		local resp = Request.Execute((self :: any)._Client, "track.getInfo", params)
		return Parse.Track((resp :: any).track)
	end)
end

function Track.GetSimilarAsync(
	self: TrackNamespace,
	artist: string,
	track: string,
	opts: { Mbid: string?, Autocorrect: boolean?, Limit: number? }?
)
	local o: any = opts or {}
	return Future.New(function(): { Resources.Track }
		local params: { [string]: any } = { artist = artist, track = track }
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Autocorrect ~= nil then
			params.autocorrect = o.Autocorrect and "1" or "0"
		end
		if o.Limit then
			params.limit = o.Limit
		end
		local resp = Request.Execute((self :: any)._Client, "track.getSimilar", params)
		local out: { Resources.Track } = {}
		for _, t in Parse.List((resp :: any).similartracks and (resp :: any).similartracks.track) do
			table.insert(out, Parse.Track(t))
		end
		return out
	end)
end

function Track.GetTagsAsync(
	self: TrackNamespace,
	artist: string,
	track: string,
	opts: { Mbid: string?, Autocorrect: boolean?, User: string? }?
)
	local o: any = opts or {}
	return Future.New(function(): { Resources.Tag }
		local params: { [string]: any } = { artist = artist, track = track }
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Autocorrect ~= nil then
			params.autocorrect = o.Autocorrect and "1" or "0"
		end
		if o.User then
			params.user = o.User
		end
		local resp = Request.Execute((self :: any)._Client, "track.getTags", params)
		local out: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).tags and (resp :: any).tags.tag) do
			table.insert(out, Parse.Tag(t))
		end
		return out
	end)
end

function Track.GetTopTagsAsync(
	self: TrackNamespace,
	artist: string,
	track: string,
	opts: { Mbid: string?, Autocorrect: boolean? }?
)
	local o: any = opts or {}
	return Future.New(function(): { Resources.Tag }
		local params: { [string]: any } = { artist = artist, track = track }
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Autocorrect ~= nil then
			params.autocorrect = o.Autocorrect and "1" or "0"
		end
		local resp = Request.Execute((self :: any)._Client, "track.getTopTags", params)
		local out: { Resources.Tag } = {}
		for _, t in Parse.List((resp :: any).toptags and (resp :: any).toptags.tag) do
			table.insert(out, Parse.Tag(t))
		end
		return out
	end)
end

function Track.SearchAsync(
	self: TrackNamespace,
	query: string,
	opts: { Artist: string?, Limit: number?, Page: number? }?
)
	local o: any = opts or {}
	return Future.New(function(): Page.Page<Resources.Track>
		local params: { [string]: any } = { track = query }
		if o.Artist then
			params.artist = o.Artist
		end
		if o.Limit then
			params.limit = o.Limit
		end
		if o.Page then
			params.page = o.Page
		end
		local resp = Request.Execute((self :: any)._Client, "track.search", params)
		local results = (resp :: any).results
		local matches = results and (results :: any).trackmatches
		local items: { Resources.Track } = {}
		for _, raw in Parse.MatchesList(matches, "track") do
			table.insert(items, Parse.Track(raw))
		end
		local pagination = Parse.Pagination(results)
		local function refetch(p: number): any
			return Track.SearchAsync(self, query, { Artist = o.Artist, Limit = o.Limit, Page = p })
		end
		if pagination.Total == 0 then
			return Page.Empty(refetch)
		end
		return Page.Build({ Items = items, Pagination = pagination, Refetch = refetch })
	end)
end

function Track.LoveAsync(self: TrackNamespace, artist: string, track: string)
	return Future.New(function(): nil
		Request.Execute((self :: any)._Client, "track.love", { artist = artist, track = track })
		return nil
	end)
end

function Track.UnloveAsync(self: TrackNamespace, artist: string, track: string)
	return Future.New(function(): nil
		Request.Execute((self :: any)._Client, "track.unlove", { artist = artist, track = track })
		return nil
	end)
end

function Track.AddTagsAsync(self: TrackNamespace, artist: string, track: string, tags: { string })
	return Future.New(function(): nil
		Request.Execute((self :: any)._Client, "track.addTags", {
			artist = artist,
			track = track,
			tags = table.concat(tags, ","),
		})
		return nil
	end)
end

function Track.RemoveTagAsync(self: TrackNamespace, artist: string, track: string, tag: string)
	return Future.New(function(): nil
		Request.Execute((self :: any)._Client, "track.removeTag", {
			artist = artist,
			track = track,
			tag = tag,
		})
		return nil
	end)
end

function Track.UpdateNowPlayingAsync(
	self: TrackNamespace,
	artist: string,
	track: string,
	opts: {
		Album: string?,
		AlbumArtist: string?,
		TrackNumber: number?,
		Duration: number?,
		Mbid: string?,
		Context: string?,
	}?
)
	local o: any = opts or {}
	return Future.New(function(): nil
		local params: { [string]: any } = { artist = artist, track = track }
		if o.Album then
			params.album = o.Album
		end
		if o.AlbumArtist then
			params.albumArtist = o.AlbumArtist
		end
		if o.TrackNumber then
			params.trackNumber = o.TrackNumber
		end
		if o.Duration then
			params.duration = o.Duration
		end
		if o.Mbid then
			params.mbid = o.Mbid
		end
		if o.Context then
			params.context = o.Context
		end
		Request.Execute((self :: any)._Client, "track.updateNowPlaying", params)
		return nil
	end)
end

-- Scrobble a batch of up to 50 tracks. Each entry needs at minimum
-- Artist, Track, Timestamp. Returns an aggregate ScrobbleResult.
function Track.ScrobbleAsync(self: TrackNamespace, entries: { Resources.ScrobbleEntry })
	return Future.New(function(): Resources.ScrobbleResult
		assert(#entries > 0, "Track:ScrobbleAsync requires at least one entry")
		assert(#entries <= 50, "Track:ScrobbleAsync batch limit is 50 per call")
		local params: { [string]: any } = {}
		for i, entry in entries do
			local idx = tostring(i - 1)
			params["artist[" .. idx .. "]"] = entry.Artist
			params["track[" .. idx .. "]"] = entry.Track
			params["timestamp[" .. idx .. "]"] = entry.Timestamp
			if entry.Album then
				params["album[" .. idx .. "]"] = entry.Album
			end
			if entry.AlbumArtist then
				params["albumArtist[" .. idx .. "]"] = entry.AlbumArtist
			end
			if entry.TrackNumber then
				params["trackNumber[" .. idx .. "]"] = entry.TrackNumber
			end
			if entry.Mbid then
				params["mbid[" .. idx .. "]"] = entry.Mbid
			end
			if entry.Duration then
				params["duration[" .. idx .. "]"] = entry.Duration
			end
			if entry.ChosenByUser ~= nil then
				params["chosenByUser[" .. idx .. "]"] = entry.ChosenByUser and "1" or "0"
			end
			if entry.Context then
				params["context[" .. idx .. "]"] = entry.Context
			end
			if entry.StreamId then
				params["streamId[" .. idx .. "]"] = entry.StreamId
			end
		end
		local resp = Request.Execute((self :: any)._Client, "track.scrobble", params)
		local sc = (resp :: any).scrobbles
		local accepted = Parse.Number(Parse.Attr(sc, "accepted")) or 0
		local ignored = Parse.Number(Parse.Attr(sc, "ignored")) or 0
		local messages: { { Code: number, Message: string, Track: string?, Artist: string? } } = {}
		for _, s in Parse.List(sc and (sc :: any).scrobble) do
			local im = (s :: any).ignoredMessage
			if type(im) == "table" then
				local code = Parse.Number((im :: any).code) or 0
				if code ~= 0 then
					table.insert(messages, {
						Code = code,
						Message = Parse.String((im :: any)["#text"]) or "",
						Track = Parse.String((s :: any).track and (s :: any).track["#text"] or (s :: any).track),
						Artist = Parse.String((s :: any).artist and (s :: any).artist["#text"] or (s :: any).artist),
					})
				end
			end
		end
		return { Accepted = accepted, Ignored = ignored, IgnoredMessages = messages }
	end)
end

return Track
