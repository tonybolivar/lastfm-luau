--!strict
export type CacheEntry = {
	Body: string,
	ExpiresAt: number,
	Method: string,
}

export type Cache = {
	Get: (self: Cache, key: string) -> CacheEntry?,
	Set: (self: Cache, key: string, entry: CacheEntry) -> (),
	Invalidate: (self: Cache, prefix: string?) -> (),
}

local Cache = {}

-- Fields that must never appear in cache keys (they vary per-client / per-call
-- and don't affect the semantic identity of the request).
local EXCLUDED_KEYS: { [string]: boolean } = {
	api_key = true,
	api_sig = true,
	sk = true,
	format = true,
}

-- Build a deterministic cache key from method + outgoing params.
--
-- IMPORTANT (carried forward from pylast #532): callers MUST pass the SAME
-- params table they actually send over the wire. Computing the key from one
-- set of params and storing/looking-up under another leads to permanent
-- cache misses.
function Cache.KeyFor(method: string, params: { [string]: any }): string
	local sortedKeys: { string } = {}
	for k in params do
		if not EXCLUDED_KEYS[k] then
			table.insert(sortedKeys, k)
		end
	end
	table.sort(sortedKeys)
	local parts: { string } = {}
	for _, k in sortedKeys do
		local v = params[k]
		if v ~= nil then
			table.insert(parts, `{k}={tostring(v)}`)
		end
	end
	return `{method}?{table.concat(parts, "&")}`
end

return Cache
