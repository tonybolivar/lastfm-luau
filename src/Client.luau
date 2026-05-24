--!strict
-- Client class. Holds config, wires subsystems (rate limit, retry, cache,
-- session store, logger, polyfills), and mounts the 9 REST namespaces as
-- direct fields (`client.Track`, `client.User`, etc.).

local Polyfills = require("@self/Polyfills")
local InMemoryCache = require("@self/Cache/InMemoryCache")
local RateLimit = require("@self/RateLimit")
local Secret = require("@self/Secret")
local Logger = require("@self/Logger")
local Errors = require("@self/Errors")
local Future = require("@self/Future")
local Types = require("@self/Types")
local Resources = require("@self/Resources")
local Rest = require("@self/Rest")
local Parse = require("@self/Parse")

local Client = {}
Client.__index = Client

local DEFAULT_UA = "lastfm-luau/1.0 (+https://github.com/tonybolivar/lastfm-luau)"

export type Config = {
	ApiKey: string,
	Secret: string?,
	UserAgent: string?,
	HttpClient: any?,
	Cache: any?,
	SessionStore: any?,
	RateLimit: Types.RateLimitConfig?,
	Retry: Types.RetryConfig?,
	Logger: Types.Logger?,
	AutoInvalidateStoredSessions: boolean?,
}

export type Client = typeof(setmetatable({} :: any, Client))

function Client.New(config: Config): Client
	assert(
		type(config) == "table" and type(config.ApiKey) == "string" and config.ApiKey ~= "",
		"Config.ApiKey (string) is required"
	)

	local userAgent = if config.UserAgent then `{config.UserAgent} {DEFAULT_UA}` else DEFAULT_UA

	local logger = config.Logger or Logger.Noop
	local rateLimitConfig: any = config.RateLimit or {}
	local rateLimit: any
	if rateLimitConfig.Enabled == false then
		rateLimit = RateLimit.Noop()
	else
		rateLimit = RateLimit.New({
			Wait = Polyfills.Wait,
			RequestsPerSecond = rateLimitConfig.RequestsPerSecond,
			Burst = rateLimitConfig.Burst,
			ThrowOnLimit = rateLimitConfig.ThrowOnLimit,
		})
	end

	local cacheImpl = config.Cache or InMemoryCache.New()
	local httpClient = config.HttpClient or Polyfills.Http
	local retryConfig: any = config.Retry or {}

	local self: any = setmetatable({
		_ApiKey = config.ApiKey,
		_Secret = if config.Secret then Secret.New(config.Secret) else nil,
		_UserAgent = userAgent,
		_HttpClient = httpClient,
		_Cache = cacheImpl,
		_SessionStore = config.SessionStore,
		_RateLimit = rateLimit,
		_RetryAttempts = retryConfig.Attempts or 3,
		_RetryBase = retryConfig.BaseSeconds or 0.5,
		_RetryCap = retryConfig.CapSeconds or 30,
		_Logger = logger,
		_Session = nil,
		_LastStoreKey = nil,
		_AutoInvalidateStoredSessions = if config.AutoInvalidateStoredSessions == nil
			then true
			else config.AutoInvalidateStoredSessions,
	}, Client)

	self.Album = Rest.Album.New(self)
	self.Artist = Rest.Artist.New(self)
	self.Auth = Rest.Auth.New(self)
	self.Chart = Rest.Chart.New(self)
	self.Geo = Rest.Geo.New(self)
	self.Library = Rest.Library.New(self)
	self.Tag = Rest.Tag.New(self)
	self.Track = Rest.Track.New(self)
	self.User = Rest.User.New(self)

	return self
end

function Client.SetSession(self: Client, session: any)
	assert(
		type(session) == "table" and type(session.Key) == "string" and session.Key ~= "",
		"session.Key (string) is required"
	);
	(self :: any)._Session = {
		Name = tostring(session.Name or ""),
		Key = Secret.New(session.Key),
		Subscriber = session.Subscriber and true or false,
	}
end

function Client.ForgetSession(self: Client)
	(self :: any)._Session = nil
end

-- Returns a non-sensitive view of the session ({ Name, Subscriber }) or nil.
-- The session key is never exposed via this accessor.
function Client.GetSession(self: Client): { Name: string, Subscriber: boolean }?
	local s = (self :: any)._Session
	if not s then
		return nil
	end
	return { Name = s.Name, Subscriber = s.Subscriber }
end

function Client.LoadSessionAsync(self: Client, storeKey: string)
	return Future.New(function(): boolean
		local store = (self :: any)._SessionStore
		if not store then
			return false
		end
		(self :: any)._LastStoreKey = storeKey
		local result = store:LoadAsync(storeKey):Await()
		if result:IsErr() then
			error(result:UnwrapErr(), 0)
		end
		local stored = result:UnwrapOk()
		if not stored then
			return false
		end
		Client.SetSession(self, stored)
		return true
	end)
end

function Client.SaveSessionAsync(self: Client, storeKey: string)
	return Future.New(function(): nil
		local store = (self :: any)._SessionStore
		if not store then
			error(Errors.New("InvalidParameter", "Config.SessionStore is not configured"), 0)
		end
		local s = (self :: any)._Session
		if not s then
			error(Errors.New("AuthRequired", "No active session to save"), 0)
		end
		-- pylast #528: refuse to persist a session with no resolved Name;
		-- resolve via user.getInfo first so downstream `user=""` calls don't fail.
		if s.Name == nil or s.Name == "" then
			local resolved = Client.GetAuthenticatedUserAsync(self):Await()
			if resolved:IsErr() then
				error(resolved:UnwrapErr(), 0)
			end
			s.Name = resolved:UnwrapOk().Name
		end
		(self :: any)._LastStoreKey = storeKey
		local stored = {
			Name = s.Name,
			Key = Secret.Reveal(s.Key),
			Subscriber = s.Subscriber,
			StoredAt = os.time(),
			Version = 1,
		}
		local result = store:SaveAsync(storeKey, stored):Await()
		if result:IsErr() then
			error(result:UnwrapErr(), 0)
		end
		return nil
	end)
end

function Client.ClearSessionAsync(self: Client, storeKey: string)
	return Future.New(function(): nil
		Client.ForgetSession(self)
		local store = (self :: any)._SessionStore
		if not store then
			return nil
		end
		local result = store:ClearAsync(storeKey):Await()
		if result:IsErr() then
			error(result:UnwrapErr(), 0)
		end
		return nil
	end)
end

-- pylast #528: lazily resolve the authenticated user's profile when only a
-- session key was set (Name == ""). user.getInfo with no `user` param uses sk.
function Client.GetAuthenticatedUserAsync(self: Client)
	return Future.New(function(): Resources.User
		local s = (self :: any)._Session
		if not s then
			error(Errors.New("AuthRequired", "No active session"), 0)
		end
		-- Prefer the cached session Name when set; user.getInfo with a real
		-- user= param is the simple, well-defined call. If the session was
		-- restored from a bare key (Name == ""), attach `sk` so Last.fm can
		-- identify the caller via the session instead.
		local params: { [string]: any } = {}
		if s.Name and s.Name ~= "" then
			params.user = s.Name
		else
			params.sk = Secret.Reveal(s.Key)
		end
		local resp = Rest.Request.Execute(self, "user.getInfo", params)
		local parsed = Parse.User((resp :: any).user)
		if parsed.Name and parsed.Name ~= "" then
			s.Name = parsed.Name
		end
		return parsed
	end)
end

function Client.InvalidateCache(self: Client, methodPrefix: string?)
	local cache = (self :: any)._Cache
	if cache then
		cache:Invalidate(methodPrefix)
	end
end

return Client
