--!nocheck
-- Lune HTTP adapter. Loaded only when runtime detection picks Lune.

local net = require("@lune/net")
local Errors = require("@self/Errors")

local Http = {}

function Http:Request(req)
	local ok, response = pcall(function()
		return net.request({
			url = req.url,
			method = req.method,
			headers = req.headers,
			body = req.body,
		})
	end)
	if not ok then
		error(Errors.New("HttpError", tostring(response), { Cause = response }), 0)
	end
	return {
		ok = response.ok,
		status = response.statusCode,
		statusMessage = response.statusMessage,
		headers = response.headers,
		body = response.body,
	}
end

return Http
