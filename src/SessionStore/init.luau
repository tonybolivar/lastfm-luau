--!nocheck
-- SessionStore namespace. Only loads runtime-specific implementations
-- on the matching runtime; InMemory is portable and always available.

local Polyfills = require(script.Parent.Polyfills)
local Future = require(script.Parent.Future)
local Errors = require(script.Parent.Errors)
local Types = require(script.Parent.Types)

local SessionStore = {}

export type StoredSession = Types.StoredSession

export type SessionStore = {
	Kind: string,
	SaveAsync: (self: SessionStore, key: string, session: StoredSession) -> any,
	LoadAsync: (self: SessionStore, key: string) -> any,
	ClearAsync: (self: SessionStore, key: string) -> any,
}

SessionStore.InMemory = require(script.InMemory)

if Polyfills.Runtime == "Roblox" then
	SessionStore.RobloxDataStore = require(script.RobloxDataStore)
end

if Polyfills.Runtime == "Lune" then
	SessionStore.LuneFile = require(script.LuneFile)
end

return SessionStore
