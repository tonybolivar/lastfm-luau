--!nocheck
-- Roblox HTTP adapter. Loaded only when runtime detection picks Roblox.

local Errors = require("@self/Errors")

local HttpService = game:GetService("HttpService")

local Http = {}

-- Roblox's HttpService:RequestAsync rejects requests that set headers it
-- manages itself (user-agent, host, content-length, etc.). The lib sets a
-- user-agent on every request; strip the rejected ones here so the rest of
-- the pipeline can stay runtime-agnostic.
local FORBIDDEN_HEADERS: { [string]: boolean } = {
	["user-agent"] = true,
	["host"] = true,
	["content-length"] = true,
	["connection"] = true,
	["transfer-encoding"] = true,
}

local function sanitizeHeaders(input)
	if type(input) ~= "table" then
		return input
	end
	local out = {}
	for k, v in input do
		if not FORBIDDEN_HEADERS[string.lower(k)] then
			out[k] = v
		end
	end
	return out
end

function Http:Request(req)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = req.url,
			Method = req.method,
			Headers = sanitizeHeaders(req.headers),
			Body = req.body,
		})
	end)
	if not ok then
		local msg = tostring(response)
		-- Roblox returns this with varying casing ("Http..." vs "HTTP...") depending
		-- on engine version; match case-insensitively so the friendly hint always wins.
		if string.find(string.lower(msg), "http requests are not enabled", 1, true) then
			error(
				Errors.New(
					"HttpError",
					"HttpService is not enabled. In Studio: HttpService.HttpEnabled = true. In published places: Game Settings > Security > Allow HTTP Requests.",
					{ Cause = response }
				),
				0
			)
		end
		error(Errors.New("HttpError", msg, { Cause = response }), 0)
	end
	local lowerHeaders = {}
	for k, v in response.Headers do
		lowerHeaders[string.lower(k)] = v
	end
	return {
		ok = response.Success,
		status = response.StatusCode,
		statusMessage = response.StatusMessage,
		headers = lowerHeaders,
		body = response.Body,
	}
end

return Http
