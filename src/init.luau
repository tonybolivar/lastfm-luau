--!strict
-- lastfm-luau — Last.fm API client for Luau (Roblox + Lune)
--
-- Usage:
--   local LastFM = require(ReplicatedStorage.Packages.LastFM)
--   local client = LastFM.new({ ApiKey = "...", Secret = "..." })
--   local info = client.Track:GetInfoAsync("Daft Punk", "One More Time"):Await():UnwrapOk()
--
-- See README.md for the full guide. License: MIT.

local Client = require("@self/Client")
local Polyfills = require("@self/Polyfills")
local SessionStore = require("@self/SessionStore")
local Classes = require("@self/Classes")
local Resources = require("@self/Resources")
local Types = require("@self/Types")
local Errors = require("@self/Errors")
local Future = require("@self/Future")
local Logger = require("@self/Logger")
local Page = require("@self/Page")
local Secret = require("@self/Secret")

local LastFM = {}

LastFM.new = Client.New

LastFM.SessionStore = SessionStore
LastFM.AuthGui = Polyfills.AuthGui
LastFM.Logger = Logger
LastFM.Classes = Classes
LastFM.Errors = Errors
LastFM.Future = Future
LastFM.Page = Page
LastFM.Secret = Secret
LastFM.Runtime = Polyfills.Runtime

export type Client = Client.Client
export type Config = Client.Config
export type Track = Resources.Track
export type Artist = Resources.Artist
export type Album = Resources.Album
export type Tag = Resources.Tag
export type User = Resources.User
export type Wiki = Resources.Wiki
export type ScrobbleEntry = Resources.ScrobbleEntry
export type ScrobbleResult = Resources.ScrobbleResult
export type Image = Types.Image
export type ImageSize = Types.ImageSize
export type Period = Types.Period
export type LastDate = Types.LastDate
export type Session = Types.Session
export type StoredSession = Types.StoredSession
export type LastFMError = Errors.LastFMError
export type ErrorKind = Errors.ErrorKind
export type Page<T> = Page.Page<T>
export type FutureLike<E, T> = Future.FutureLike<E, T>
export type Result<E, T> = Future.Result<E, T>

return LastFM
