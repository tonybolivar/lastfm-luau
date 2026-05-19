--!strict
local Resources = require("@self/Resources")

local Track = {}
Track.__index = Track

export type Track = typeof(setmetatable(
	{} :: Resources.Track & { _Client: any },
	Track
))

function Track.New(data: Resources.Track, client: any?): Track
	local self: any = setmetatable(table.clone(data :: any), Track)
	self._Client = client
	return self
end

function Track.Sync(self: Track, data: Resources.Track)
	for k, v in pairs(data :: any) do
		(self :: any)[k] = v
	end
end

return Track
