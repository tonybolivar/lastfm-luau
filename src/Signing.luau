--!strict
-- Last.fm canonical signature.
-- Spec: https://www.last.fm/api/authspec
--
-- 1. Drop `format` and `callback` from params.
-- 2. Sort remaining params alphabetically by key.
-- 3. Concatenate as key1value1key2value2...
-- 4. Append shared secret (no separator).
-- 5. MD5 over the UTF-8 bytes.
-- 6. Lowercase hex.
--
-- The result is passed to the API as the `api_sig` parameter.

local Md5 = require("@self/Md5")

local Signing = {}

local EXCLUDED: { [string]: boolean } = {
	format = true,
	callback = true,
}

function Signing.GenerateSignature(params: { [string]: any }, secret: string): string
	local keys: { string } = {}
	for k in params do
		if not EXCLUDED[k] then
			table.insert(keys, k)
		end
	end
	table.sort(keys)

	local parts: { string } = {}
	for _, k in keys do
		local v = params[k]
		if v ~= nil then
			table.insert(parts, k)
			table.insert(parts, tostring(v))
		end
	end
	table.insert(parts, secret)
	return Md5.Hash(table.concat(parts, ""))
end

return Signing
