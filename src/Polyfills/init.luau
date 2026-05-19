--!nocheck
-- Runtime bootloader. Detects Roblox vs Lune and dispatches to the appropriate
-- HTTP / JSON / Wait / AuthGui adapters. Type-checking is disabled in this file
-- because both branches reference runtime-specific globals (`game`, `task`) and
-- runtime-specific require forms (`script.X` vs `require("@lune/X")`).

local Errors = require(script.Parent.Errors)

local function detectRuntime(): string
	local gameGlobal = rawget(_G, "game")
	if gameGlobal then
		local ok = pcall(function()
			return gameGlobal:GetService("HttpService")
		end)
		if ok then
			return "Roblox"
		end
	end
	if pcall(require, "@lune/net") then
		return "Lune"
	end
	return "Unknown"
end

local runtime = detectRuntime()

local Http, Json, AuthGui, Fs
if runtime == "Roblox" then
	Http = require(script.Roblox.Http)
	Json = require(script.Roblox.Json)
	AuthGui = require(script.Roblox.AuthGui)
elseif runtime == "Lune" then
	Http = require("@self/Polyfills/Lune/Http")
	Json = require("@self/Polyfills/Lune/Json")
	local ok, fs = pcall(require, "@lune/fs")
	if ok then
		Fs = fs
	end
end

local function wait(seconds: number)
	if runtime == "Roblox" then
		task.wait(seconds)
		return
	end
	if runtime == "Lune" then
		local task = require("@lune/task")
		task.wait(seconds)
		return
	end
	error(Errors.New("HttpError", "lastfm-luau: no wait implementation for runtime: " .. runtime), 0)
end

return {
	Runtime = runtime,
	Http = Http,
	Json = Json,
	AuthGui = AuthGui,
	Fs = Fs,
	Wait = wait,
}
