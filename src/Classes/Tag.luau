--!strict
local Resources = require(script.Parent.Parent.Resources)

local Tag = {}
Tag.__index = Tag

export type Tag = typeof(setmetatable(
	{} :: Resources.Tag & { _Client: any },
	Tag
))

function Tag.New(data: Resources.Tag, client: any?): Tag
	local self: any = setmetatable(table.clone(data :: any), Tag)
	self._Client = client
	return self
end

function Tag.Sync(self: Tag, data: Resources.Tag)
	for k, v in pairs(data :: any) do
		(self :: any)[k] = v
	end
end

return Tag
