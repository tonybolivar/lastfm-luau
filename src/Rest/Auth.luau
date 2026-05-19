--!strict
local Request = require("@self/Rest/Request")
local Future = require("@self/Future")
local Parse = require("@self/Parse")
local Md5 = require("@self/Md5")
local Types = require("@self/Types")

local Auth = {}
Auth.__index = Auth

export type AuthNamespace = typeof(setmetatable({} :: { _Client: any }, Auth))

export type Approval = {
	Url: string,
	QrMatrix: { { boolean } }?,
}

function Auth.New(client: any): AuthNamespace
	return setmetatable({ _Client = client }, Auth) :: any
end

function Auth.GetTokenAsync(self: AuthNamespace)
	return Future.New(function(): string
		local resp = Request.Execute((self :: any)._Client, "auth.getToken", {})
		return tostring((resp :: any).token)
	end)
end

-- Synchronous (no network) — builds the URL the user opens in a browser.
function Auth.GetApprovalUrl(self: AuthNamespace, token: string): Approval
	local apiKey = (self :: any)._Client._ApiKey
	return {
		Url = `https://www.last.fm/api/auth/?api_key={apiKey}&token={token}`,
		QrMatrix = nil,
	}
end

function Auth.GetSessionAsync(self: AuthNamespace, token: string)
	return Future.New(function(): Types.Session
		local resp = Request.Execute((self :: any)._Client, "auth.getSession", { token = token })
		local s = (resp :: any).session
		return {
			Name = tostring((s :: any).name),
			Key = tostring((s :: any).key),
			Subscriber = Parse.Boolean((s :: any).subscriber) or false,
		}
	end)
end

-- Mobile auth — exchanges username + plaintext password (or pre-hashed password)
-- for a session key. The library hashes the password if `Password` is provided;
-- pass `AuthToken` instead if you already have MD5(username .. MD5(password)).
function Auth.GetMobileSessionAsync(self: AuthNamespace, username: string, opts: { Password: string?, AuthToken: string? })
	return Future.New(function(): Types.Session
		local authToken: string
		if opts.AuthToken then
			authToken = opts.AuthToken
		elseif opts.Password then
			authToken = Md5.Hash(string.lower(username) .. Md5.Hash(opts.Password))
		else
			error("Auth.GetMobileSessionAsync requires opts.Password or opts.AuthToken", 0)
		end
		local resp = Request.Execute((self :: any)._Client, "auth.getMobileSession", {
			username = username,
			authToken = authToken,
		})
		local s = (resp :: any).session
		return {
			Name = tostring((s :: any).name),
			Key = tostring((s :: any).key),
			Subscriber = Parse.Boolean((s :: any).subscriber) or false,
		}
	end)
end

return Auth
