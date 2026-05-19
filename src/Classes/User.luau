--!strict
local Resources = require("@self/Resources")

local User = {}
User.__index = User

export type User = typeof(setmetatable(
	{} :: Resources.User & { _Client: any },
	User
))

function User.New(data: Resources.User, client: any?): User
	local self: any = setmetatable(table.clone(data :: any), User)
	self._Client = client
	return self
end

function User.Sync(self: User, data: Resources.User)
	for k, v in pairs(data :: any) do
		(self :: any)[k] = v
	end
end

return User
