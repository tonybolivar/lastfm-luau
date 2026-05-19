--!nocheck
-- DataStoreService-backed session store. Roblox-only.
--
-- - Wraps SetAsync/GetAsync/RemoveAsync in pcall + exponential backoff.
-- - Uses UpdateAsync for SaveAsync so two servers writing concurrently merge
--   on StoredAt (newest wins) rather than clobbering.
-- - Logs a "warn" via Config.Logger when DataStore budget falls below 10%
--   of the relevant request type.

local Polyfills = require("@self/Polyfills")
local Errors = require("@self/Errors")
local Future = require("@self/Future")

local RobloxDataStore = {}

local DEFAULT_RETRY_ATTEMPTS = 3
local DEFAULT_RETRY_BASE = 0.5

local mt = {}
mt.__index = mt

mt.Kind = "RobloxDataStore"

local function retrying(fn, attempts, base, wait, methodLabel)
	local lastErr
	for i = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return result
		end
		lastErr = result
		if i < attempts then
			local delay = base * (2 ^ (i - 1)) * (math.random() + 0.5)
			wait(delay)
		end
	end
	error(
		Errors.New("DataStoreError", `DataStore {methodLabel} failed after {attempts} attempts: {tostring(lastErr)}`, {
			Cause = lastErr,
		}),
		0
	)
end

local function checkBudget(self, requestType)
	if not self._Logger then
		return
	end
	local DataStoreService = game:GetService("DataStoreService")
	local ok, budget = pcall(function()
		return DataStoreService:GetRequestBudgetForRequestType(requestType)
	end)
	if ok and budget and budget < 6 then
		self._Logger("warn", "LastFM SessionStore: DataStore budget low", {
			budget = budget,
			requestType = tostring(requestType),
		})
	end
end

function mt.SaveAsync(self, key, session)
	return Future.New(function()
		checkBudget(self, Enum.DataStoreRequestType.UpdateAsync)
		local jsonValue = Polyfills.Json.Encode(session)
		retrying(function()
			return self._Store:UpdateAsync(key, function(existing)
				if existing then
					local ok, existingSession = pcall(Polyfills.Json.Decode, existing)
					if ok and type(existingSession) == "table" then
						local existingStoredAt = tonumber(existingSession.StoredAt) or 0
						if existingStoredAt > session.StoredAt then
							return existing
						end
					end
				end
				return jsonValue
			end)
		end, self._Attempts, self._Base, Polyfills.Wait, "UpdateAsync")
		return nil
	end)
end

function mt.LoadAsync(self, key)
	return Future.New(function()
		checkBudget(self, Enum.DataStoreRequestType.GetAsync)
		local raw = retrying(function()
			return self._Store:GetAsync(key)
		end, self._Attempts, self._Base, Polyfills.Wait, "GetAsync")
		if raw == nil then
			return nil
		end
		local ok, decoded = pcall(Polyfills.Json.Decode, raw)
		if not ok or type(decoded) ~= "table" then
			if self._Logger then
				self._Logger("warn", "LastFM SessionStore: corrupt entry, clearing", {
					key = key,
					error = tostring(decoded),
				})
			end
			pcall(function()
				self._Store:RemoveAsync(key)
			end)
			return nil
		end
		return decoded
	end)
end

function mt.ClearAsync(self, key)
	return Future.New(function()
		checkBudget(self, Enum.DataStoreRequestType.UpdateAsync)
		retrying(function()
			self._Store:RemoveAsync(key)
		end, self._Attempts, self._Base, Polyfills.Wait, "RemoveAsync")
		return nil
	end)
end

function RobloxDataStore.New(opts)
	if Polyfills.Runtime ~= "Roblox" then
		error("RobloxDataStore can only be used on the Roblox runtime", 2)
	end
	assert(type(opts) == "table" and type(opts.Name) == "string", "opts.Name (string) required")
	local DataStoreService = game:GetService("DataStoreService")
	local store = DataStoreService:GetDataStore(opts.Name, opts.Scope or "global")
	return setmetatable({
		_Store = store,
		_Attempts = opts.RetryAttempts or DEFAULT_RETRY_ATTEMPTS,
		_Base = opts.RetryBaseSeconds or DEFAULT_RETRY_BASE,
		_Logger = opts.Logger,
	}, mt)
end

return RobloxDataStore
