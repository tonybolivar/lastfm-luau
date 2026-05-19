--!strict
-- Credential wrapper. Masks the value in tostring and blocks mutation.
-- Use Reveal() to access the raw string when actually sending it to the API.

local Secret = {}

local secretMt = {}
secretMt.__index = secretMt

secretMt.__tostring = function(self: any): string
	local v = self._Value
	local len = #v
	if len <= 4 then
		return `Secret({string.rep("*", len)})`
	end
	local visible = math.floor(len / 2)
	return `Secret({string.sub(v, 1, visible) .. string.rep("*", len - visible)})`
end

secretMt.__newindex = function(_, key: any)
	error(`Secret is immutable (attempted to set "{tostring(key)}")`, 2)
end

export type Secret = typeof(setmetatable({} :: { _Value: string }, secretMt))

function Secret.New(value: string): Secret
	assert(type(value) == "string", "Secret value must be a string")
	return setmetatable({ _Value = value }, secretMt) :: any
end

function Secret.Reveal(s: Secret): string
	return (s :: any)._Value
end

function Secret.IsSecret(value: any): boolean
	return type(value) == "table" and getmetatable(value :: any) == secretMt
end

return Secret
