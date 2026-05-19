--!nocheck
-- File-backed session store for Lune runtimes. Stores sessions as a JSON
-- object keyed by user identifier, with atomic writes (tmp + rename).

local Polyfills = require(script.Parent.Parent.Polyfills)
local Future = require(script.Parent.Parent.Future)
local Errors = require(script.Parent.Parent.Errors)

local LuneFile = {}

local mt = {}
mt.__index = mt

mt.Kind = "LuneFile"

local function readAll(path)
	local fs = Polyfills.Fs
	if not fs then
		return {}
	end
	local ok, exists = pcall(function()
		return fs.isFile(path)
	end)
	if not ok or not exists then
		return {}
	end
	local raw = fs.readFile(path)
	local decoded = Polyfills.Json.Decode(raw)
	return decoded or {}
end

local function writeAtomic(path, contents)
	local fs = Polyfills.Fs
	if not fs then
		error(Errors.New("DataStoreError", "Lune fs unavailable"), 0)
	end
	-- Ensure parent dir exists
	local dir = string.match(path, "(.*)[/\\]")
	if dir and dir ~= "" then
		pcall(function()
			fs.writeDir(dir)
		end)
	end
	local tmpPath = path .. ".tmp"
	fs.writeFile(tmpPath, contents)
	if fs.isFile(path) then
		fs.removeFile(path)
	end
	fs.move(tmpPath, path)
end

function mt.SaveAsync(self, key, session)
	return Future.New(function()
		local all = readAll(self._Path)
		all[key] = session
		writeAtomic(self._Path, Polyfills.Json.Encode(all))
		return nil
	end)
end

function mt.LoadAsync(self, key)
	return Future.New(function()
		local all = readAll(self._Path)
		return all[key]
	end)
end

function mt.ClearAsync(self, key)
	return Future.New(function()
		local all = readAll(self._Path)
		all[key] = nil
		writeAtomic(self._Path, Polyfills.Json.Encode(all))
		return nil
	end)
end

function LuneFile.New(opts)
	if Polyfills.Runtime ~= "Lune" then
		error("LuneFile can only be used on the Lune runtime", 2)
	end
	assert(type(opts) == "table" and type(opts.Path) == "string", "opts.Path (string) required")
	return setmetatable({ _Path = opts.Path }, mt)
end

return LuneFile
