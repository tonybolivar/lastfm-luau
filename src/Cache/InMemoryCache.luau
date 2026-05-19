--!strict
local Cache = require("@self/Cache")

local InMemoryCache = {}

local imcMt = {}
imcMt.__index = imcMt

function imcMt.Get(self: any, key: string): Cache.CacheEntry?
	local entry = self._Store[key]
	if not entry then
		return nil
	end
	if entry.ExpiresAt < os.clock() then
		self._Store[key] = nil
		return nil
	end
	return entry
end

function imcMt.Set(self: any, key: string, entry: Cache.CacheEntry)
	self._Store[key] = entry
end

function imcMt.Invalidate(self: any, prefix: string?)
	if not prefix then
		self._Store = {}
		return
	end
	for k in self._Store do
		if string.sub(k, 1, #prefix) == prefix then
			self._Store[k] = nil
		end
	end
end

function InMemoryCache.New(): Cache.Cache
	return setmetatable({ _Store = {} :: { [string]: Cache.CacheEntry } }, imcMt) :: any
end

return InMemoryCache
