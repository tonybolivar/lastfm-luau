--!strict
-- Minimal event primitive. Used internally for diagnostic signals
-- (rate-limit hits, cache evictions, retries, etc.).

local Emitter = {}

export type Listener<T...> = (T...) -> ()

local connectionMt = {}
connectionMt.__index = connectionMt

export type Connection = typeof(setmetatable(
	{} :: {
		_Listener: Listener<...any>,
		_Emitter: any,
	},
	connectionMt
))

function connectionMt.Disconnect(self: Connection)
	local s = self :: any
	local listeners = s._Emitter._Listeners
	for i, l in listeners do
		if l == s._Listener then
			table.remove(listeners, i)
			break
		end
	end
end

local emitterMt = {}
emitterMt.__index = emitterMt

export type Emitter<T...> = typeof(setmetatable(
	{} :: {
		_Listeners: { Listener<T...> },
	},
	emitterMt
))

function emitterMt.Listen<T...>(self: Emitter<T...>, listener: Listener<T...>): Connection
	table.insert((self :: any)._Listeners, listener)
	return setmetatable({ _Listener = listener, _Emitter = self }, connectionMt) :: any
end

function emitterMt.Fire<T...>(self: Emitter<T...>, ...: T...)
	for _, listener in (self :: any)._Listeners do
		local ok, err = pcall(listener, ...)
		if not ok then
			warn(`[lastfm:emitter] listener errored: {tostring(err)}`)
		end
	end
end

function emitterMt.ListenerCount<T...>(self: Emitter<T...>): number
	return #(self :: any)._Listeners
end

function Emitter.New<T...>(): Emitter<T...>
	return setmetatable({ _Listeners = {} }, emitterMt) :: any
end

return Emitter
