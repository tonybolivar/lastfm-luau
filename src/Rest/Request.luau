--!strict
-- Core request pipeline: build → sign → cache-check → rate-limit → http → parse → cache.
--
-- This is the only place that knows the wire format. Namespace modules call
-- Request.Execute(client, methodName, params) and get parsed JSON back.

local Endpoints = require(script.Parent.Parent.Endpoints)
local Signing = require(script.Parent.Parent.Signing)
local Cache = require(script.Parent.Parent.Cache)
local Errors = require(script.Parent.Parent.Errors)
local Secret = require(script.Parent.Parent.Secret)
local Retry = require(script.Parent.Parent.Retry)
local Polyfills = require(script.Parent.Parent.Polyfills)

local Request = {}

local BASE_URL = "https://ws.audioscrobbler.com/2.0/"

local function urlEncode(s: string): string
	return (string.gsub(s, "[^A-Za-z0-9%-_.~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function buildQueryString(params: { [string]: any }): string
	local sortedKeys: { string } = {}
	for k in params do
		table.insert(sortedKeys, k)
	end
	table.sort(sortedKeys)
	local parts: { string } = {}
	for _, k in sortedKeys do
		local v = params[k]
		if v ~= nil then
			table.insert(parts, urlEncode(k) .. "=" .. urlEncode(tostring(v)))
		end
	end
	return table.concat(parts, "&")
end

function Request.Execute(client: any, methodName: string, userParams: { [string]: any }): any
	local info = Endpoints[methodName]
	if not info then
		error(Errors.New("InvalidParameter", `Unknown method: {methodName}`, { Method = methodName }), 0)
	end

	-- Copy user params (don't mutate caller's table) and add framework fields.
	local outgoing: { [string]: any } = {}
	for k, v in userParams do
		if v ~= nil then
			outgoing[k] = v
		end
	end
	outgoing.method = methodName
	outgoing.api_key = client._ApiKey
	outgoing.format = "json"

	if info.RequiresSession then
		if not client._Session then
			error(
				Errors.New(
					"AuthRequired",
					`Method "{methodName}" requires an active session. Call client:SetSession(...) first.`,
					{ Method = methodName }
				),
				0
			)
		end
		outgoing.sk = Secret.Reveal(client._Session.Key)
	end

	if info.RequiresSignature then
		if not client._Secret then
			error(
				Errors.New(
					"NoSecret",
					`Method "{methodName}" requires a secret. Pass it in Config.Secret.`,
					{ Method = methodName }
				),
				0
			)
		end
		outgoing.api_sig = Signing.GenerateSignature(outgoing, Secret.Reveal(client._Secret))
	end

	-- Cache lookup. The key is derived from outgoing params (with api_key,
	-- api_sig, sk, format excluded). Always-symmetric Get/Set via Cache.KeyFor.
	local cacheKey = Cache.KeyFor(methodName, outgoing)
	local ttl = info.DefaultTtl

	if ttl > 0 and client._Cache then
		local entry = (client._Cache :: any):Get(cacheKey)
		if entry then
			client._Logger("debug", "cache hit", { method = methodName })
			return Polyfills.Json.Decode(entry.Body)
		end
	end

	local function fire(): any
		client._RateLimit:Acquire()

		local httpReq
		if info.HttpMethod == "GET" then
			httpReq = {
				method = "GET" :: "GET" | "POST",
				url = BASE_URL .. "?" .. buildQueryString(outgoing),
				headers = { ["user-agent"] = client._UserAgent } :: { [string]: string },
			}
		else
			httpReq = {
				method = "POST" :: "GET" | "POST",
				url = BASE_URL,
				headers = {
					["user-agent"] = client._UserAgent,
					["content-type"] = "application/x-www-form-urlencoded",
				} :: { [string]: string },
				body = buildQueryString(outgoing),
			}
		end

		local response = (client._HttpClient :: any):Request(httpReq)

		-- HTTP 429 surfaces as RateLimited with optional Retry-After hint.
		if response.status == 429 then
			local retryAfter = tonumber(response.headers["retry-after"]) or 1
			local err = Errors.New("RateLimited", "HTTP 429 Too Many Requests", {
				HttpStatus = 429,
				Method = methodName,
			});
			(err :: any).RetryAfterSeconds = retryAfter
			error(err, 0)
		end

		-- Parse body unconditionally — Last.fm returns errors as HTTP 200 with
		-- { error, message } JSON, so status alone is unreliable.
		local body = response.body or ""
		local decoded: any
		local ok, decodeResult = pcall(Polyfills.Json.Decode, body)
		if ok then
			decoded = decodeResult
		else
			if not response.ok then
				error(
					Errors.New("HttpError", `HTTP {response.status}: non-JSON body`, {
						HttpStatus = response.status,
						Method = methodName,
						Cause = decodeResult,
					}),
					0
				)
			end
			error(
				Errors.New("ParseError", `Response body was not valid JSON: {tostring(decodeResult)}`, {
					HttpStatus = response.status,
					Method = methodName,
					Cause = decodeResult,
				}),
				0
			)
		end

		if type(decoded) == "table" and (decoded :: any).error ~= nil then
			local code = tonumber((decoded :: any).error) or 0
			local message = tostring((decoded :: any).message or "(no message)")
			client._Logger("warn", "Last.fm API error", { method = methodName, code = code, message = message })

			-- Auto-invalidate stored session on code 9 (invalid session key)
			if code == 9 and client._AutoInvalidateStoredSessions and client._LastStoreKey then
				pcall(function()
					client:ForgetSession()
					if client._SessionStore then
						client._SessionStore:ClearAsync(client._LastStoreKey):Await()
					end
				end)
			end

			error(Errors.FromApiCode(code, message, methodName), 0)
		end

		if not response.ok and response.status ~= 200 then
			error(
				Errors.New("HttpError", `HTTP {response.status}: {response.statusMessage or ""}`, {
					HttpStatus = response.status,
					Method = methodName,
				}),
				0
			)
		end

		return decoded, body
	end

	local result: any
	local rawBody: string
	local retried = Retry.Run(function(): any
		local r, b = fire()
		return { result = r, body = b }
	end, {
		Attempts = client._RetryAttempts,
		BaseSeconds = client._RetryBase,
		CapSeconds = client._RetryCap,
		Wait = Polyfills.Wait,
	})
	result = (retried :: any).result
	rawBody = (retried :: any).body

	if ttl > 0 and client._Cache then
		(client._Cache :: any):Set(cacheKey, {
			Body = rawBody,
			ExpiresAt = os.clock() + ttl,
			Method = methodName,
		})
	end

	return result
end

return Request
