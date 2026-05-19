--!nocheck
-- Roblox HTTP adapter. Loaded only when runtime detection picks Roblox.

local Errors = require(script.Parent.Parent.Parent.Errors)

local HttpService = game:GetService("HttpService")

local Http = {}

function Http:Request(req)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = req.url,
			Method = req.method,
			Headers = req.headers,
			Body = req.body,
		})
	end)
	if not ok then
		local msg = tostring(response)
		if string.find(msg, "Http requests are not enabled", 1, true) then
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
