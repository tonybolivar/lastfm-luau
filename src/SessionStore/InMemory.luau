--!strict
-- Ephemeral session store. Used by tests and as the default for non-Roblox
-- runtimes when no other store is configured.

local Future = require(script.Parent.Parent.Future)
local Types = require(script.Parent.Parent.Types)
local Errors = require(script.Parent.Parent.Errors)

local InMemory = {}

local mt = {}
mt.__index = mt

mt.Kind = "InMemory"

function mt.SaveAsync(self: any, key: string, session: Types.StoredSession): Future.FutureLike<Errors.LastFMError, ()>
	return Future.New(function(): ()
		self._Store[key] = session
		return nil
	end)
end

function mt.LoadAsync(self: any, key: string): Future.FutureLike<Errors.LastFMError, Types.StoredSession?>
	return Future.New(function(): Types.StoredSession?
		return self._Store[key]
	end)
end

function mt.ClearAsync(self: any, key: string): Future.FutureLike<Errors.LastFMError, ()>
	return Future.New(function(): ()
		self._Store[key] = nil
		return nil
	end)
end

function InMemory.New(): any
	return setmetatable({
		_Store = {} :: { [string]: Types.StoredSession },
	}, mt)
end

return InMemory
