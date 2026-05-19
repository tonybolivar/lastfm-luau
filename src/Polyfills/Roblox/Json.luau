--!nocheck
local HttpService = game:GetService("HttpService")

local Json = {}

function Json.Encode(value)
	return HttpService:JSONEncode(value)
end

function Json.Decode(s)
	return HttpService:JSONDecode(s)
end

return Json
