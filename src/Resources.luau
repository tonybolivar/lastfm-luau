--!strict
-- Typed records for Last.fm resources (Artist, Track, Album, Tag, User).
-- These are the shape of values returned by Rest methods after parsing.

local Types = require("@self/Types")

export type Wiki = {
	Summary: string, -- HTML stripped, whitespace collapsed
	Content: string, -- HTML stripped, whitespace collapsed
	SummaryRaw: string, -- as returned by Last.fm (may contain HTML)
	ContentRaw: string, -- as returned by Last.fm (may contain HTML)
	Published: Types.LastDate?,
	Url: string?,
}

export type Artist = {
	Name: string,
	Mbid: string?,
	Url: string?,
	Images: { Types.Image }?,
	Listeners: number?,
	PlayCount: number?,
	UserPlayCount: number?,
	Streamable: boolean?,
	OnTour: boolean?,
	Bio: Wiki?,
	Tags: { Tag }?,
	Similar: { Artist }?,
}

export type Track = {
	Name: string,
	Mbid: string?,
	Url: string?,
	Artist: Artist,
	Album: Album?,
	Duration: number?,
	Listeners: number?,
	PlayCount: number?,
	UserPlayCount: number?,
	UserLoved: boolean?,
	NowPlaying: boolean?,
	Date: Types.LastDate?,
	Images: { Types.Image }?,
	Tags: { Tag }?,
	Wiki: Wiki?,
	Streamable: boolean?,
	Rank: number?,
}

export type Album = {
	Name: string,
	Mbid: string?,
	Url: string?,
	Artist: Artist,
	Images: { Types.Image }?,
	Listeners: number?,
	PlayCount: number?,
	UserPlayCount: number?,
	Tracks: { Track }?,
	Tags: { Tag }?,
	Wiki: Wiki?,
	ReleaseDate: Types.LastDate?,
}

export type Tag = {
	Name: string,
	Url: string?,
	Count: number?,
	Reach: number?,
	Total: number?,
	Wiki: Wiki?,
}

export type User = {
	Name: string,
	RealName: string?,
	Url: string,
	Country: string?,
	Age: number?,
	Gender: string?,
	Subscriber: boolean?,
	PlayCount: number?,
	Playlists: number?,
	Registered: Types.LastDate?,
	Images: { Types.Image }?,
	Type: string?,
}

export type Friend = User & {
	BootStrap: number?,
}

export type ScrobbleEntry = {
	Artist: string,
	Track: string,
	Timestamp: number,
	Album: string?,
	AlbumArtist: string?,
	TrackNumber: number?,
	Mbid: string?,
	Duration: number?,
	ChosenByUser: boolean?,
	Context: string?,
	StreamId: string?,
}

export type ScrobbleResult = {
	Accepted: number,
	Ignored: number,
	IgnoredMessages: { { Code: number, Message: string, Track: string?, Artist: string? } },
}

return {}
