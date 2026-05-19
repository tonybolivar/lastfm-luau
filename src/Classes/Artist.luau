--!strict
local Resources = require("@self/Resources")

local Artist = {}
Artist.__index = Artist

export type Artist = typeof(setmetatable({} :: Resources.Artist & { _Client: any }, Artist))

function Artist.New(data: Resources.Artist, client: any?): Artist
	local self: any = setmetatable(table.clone(data :: any), Artist)
	self._Client = client
	return self
end

function Artist.Sync(self: Artist, data: Resources.Artist)
	for k, v in pairs(data :: any) do
		(self :: any)[k] = v
	end
end

return Artist
