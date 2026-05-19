--!nocheck
local serde = require("@lune/serde")

local Json = {}

function Json.Encode(value)
	return serde.encode("json", value)
end

function Json.Decode(s)
	return serde.decode("json", s)
end

return Json
