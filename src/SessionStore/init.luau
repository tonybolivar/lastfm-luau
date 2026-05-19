--!nocheck
-- SessionStore namespace. Only loads runtime-specific implementations
-- on the matching runtime; InMemory is portable and always available.

local Polyfills = require("@self/Polyfills")
local Future = require("@self/Future")
local Errors = require("@self/Errors")
local Types = require("@self/Types")

local SessionStore = {}

export type StoredSession = Types.StoredSession

export type SessionStore = {
	Kind: string,
	SaveAsync: (self: SessionStore, key: string, session: StoredSession) -> any,
	LoadAsync: (self: SessionStore, key: string) -> any,
	ClearAsync: (self: SessionStore, key: string) -> any,
}

SessionStore.InMemory = require("@self/SessionStore/InMemory")

if Polyfills.Runtime == "Roblox" then
	SessionStore.RobloxDataStore = require("@self/SessionStore/RobloxDataStore")
end

if Polyfills.Runtime == "Lune" then
	SessionStore.LuneFile = require("@self/SessionStore/LuneFile")
end

return SessionStore
